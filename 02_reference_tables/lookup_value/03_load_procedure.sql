CREATE OR ALTER PROCEDURE silver.load_lookup_value @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    DROP TABLE IF EXISTS silver.stg_lookup_value;

    CREATE TABLE silver.stg_lookup_value AS
    SELECT
        x.lookup_type, x.lookup_code, x.set_id, x.view_application_id, x.meaning,
        x.source_last_update_date,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.meaning, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            CAST(b.LookupType AS VARCHAR(30))                              AS lookup_type,
            CAST(b.LookupCode AS VARCHAR(30))                              AS lookup_code,
            b.SetId                                                        AS set_id,
            b.ViewApplicationId                                            AS view_application_id,
            CAST(b.Meaning AS VARCHAR(80))                                 AS meaning,
            b.LastUpdateDate                                               AS source_last_update_date,
            ROW_NUMBER() OVER (
                PARTITION BY b.LookupType, b.LookupCode, b.SetId, b.ViewApplicationId
                ORDER BY b.LastUpdateDate DESC, b._LoadDTS DESC
            ) AS rn
        FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_lookupvaluestl] b
        WHERE b.Language = 'US' AND b.LookupType = 'PJF_REVENUE_CATEGORY'
    ) x
    WHERE x.rn = 1;

    UPDATE t
    SET
        t.meaning                  = s.meaning,
        t.source_last_update_date  = s.source_last_update_date,
        t._row_hash                = s._row_hash,
        t._silver_loaded_at        = @now,
        t._is_deleted              = 0,
        t._run_id                  = @run_id
    FROM silver.lookup_value t
    INNER JOIN silver.stg_lookup_value s
        ON t.lookup_type = s.lookup_type AND t.lookup_code = s.lookup_code AND t.set_id = s.set_id AND t.view_application_id = s.view_application_id
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    INSERT INTO silver.lookup_value
        (lookup_type, lookup_code, set_id, view_application_id, meaning,
         source_last_update_date, _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.lookup_type, s.lookup_code, s.set_id, s.view_application_id, s.meaning,
           s.source_last_update_date, s._row_hash, @now, 0, @run_id
    FROM silver.stg_lookup_value s
    WHERE NOT EXISTS (SELECT 1 FROM silver.lookup_value t
                      WHERE t.lookup_type = s.lookup_type AND t.lookup_code = s.lookup_code AND t.set_id = s.set_id AND t.view_application_id = s.view_application_id);

    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.lookup_value t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_lookup_value s
                      WHERE s.lookup_type = t.lookup_type AND s.lookup_code = t.lookup_code AND s.set_id = t.set_id AND s.view_application_id = t.view_application_id);

    DROP TABLE IF EXISTS silver.stg_lookup_value;
END;
