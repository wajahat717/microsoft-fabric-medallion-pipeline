CREATE OR ALTER PROCEDURE silver.dq_expenditure_category @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    -- key is unique (uses every key column)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.expenditure_category', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT expenditure_category_id FROM silver.expenditure_category
          GROUP BY expenditure_category_id HAVING COUNT(*) > 1) x;

    -- key not null
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.expenditure_category', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.expenditure_category
    WHERE expenditure_category_id IS NULL;

    -- main column filled (warning only)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.expenditure_category', 'expenditure_category_name not null', 'WARN', COUNT(*), @now
    FROM silver.expenditure_category
    WHERE expenditure_category_name IS NULL AND _is_deleted = 0;

    -- Silver active rows = Bronze distinct keys (after filter)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.expenditure_category', 'row count matches bronze', 'ERROR',
           ABS(
             (SELECT COUNT(*) FROM silver.expenditure_category WHERE _is_deleted = 0)
           - (SELECT COUNT(*) FROM (SELECT DISTINCT b.ExpenditureCategoryBasePEOExpenditureCategoryId
                                    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_expenditurecategory] b WHERE b.ExpenditureCategoryTLLangPEOLanguage = 'US') d)
           ), @now;
END;
