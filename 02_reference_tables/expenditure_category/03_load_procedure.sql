CREATE OR ALTER PROCEDURE silver.load_expenditure_category @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    DROP TABLE IF EXISTS silver.stg_expenditure_category;

    CREATE TABLE silver.stg_expenditure_category AS
    SELECT
        x.expenditure_category_id, x.expenditure_category_name,
        x.source_last_update_date,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.expenditure_category_name, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            b.ExpenditureCategoryBasePEOExpenditureCategoryId              AS expenditure_category_id,
            CAST(b.ExpenditureCategoryTLLangPEOName AS VARCHAR(240))       AS expenditure_category_name,
            b.ExpenditureCategoryBasePEOLastUpdateDate                     AS source_last_update_date,
            ROW_NUMBER() OVER (
                PARTITION BY b.ExpenditureCategoryBasePEOExpenditureCategoryId
                ORDER BY b.ExpenditureCategoryBasePEOLastUpdateDate DESC, b._LoadDTS DESC
            ) AS rn
        FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_expenditurecategory] b
        WHERE b.ExpenditureCategoryTLLangPEOLanguage = 'US'
    ) x
    WHERE x.rn = 1;

    UPDATE t
    SET
        t.expenditure_category_name = s.expenditure_category_name,
        t.source_last_update_date  = s.source_last_update_date,
        t._row_hash                = s._row_hash,
        t._silver_loaded_at        = @now,
        t._is_deleted              = 0,
        t._run_id                  = @run_id
    FROM silver.expenditure_category t
    INNER JOIN silver.stg_expenditure_category s
        ON t.expenditure_category_id = s.expenditure_category_id
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    INSERT INTO silver.expenditure_category
        (expenditure_category_id, expenditure_category_name,
         source_last_update_date, _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.expenditure_category_id, s.expenditure_category_name,
           s.source_last_update_date, s._row_hash, @now, 0, @run_id
    FROM silver.stg_expenditure_category s
    WHERE NOT EXISTS (SELECT 1 FROM silver.expenditure_category t
                      WHERE t.expenditure_category_id = s.expenditure_category_id);

    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.expenditure_category t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_expenditure_category s
                      WHERE s.expenditure_category_id = t.expenditure_category_id);

    DROP TABLE IF EXISTS silver.stg_expenditure_category;
END;
