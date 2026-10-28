CREATE OR ALTER PROCEDURE silver.load_location_tree_version @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    DROP TABLE IF EXISTS silver.stg_location_tree_version;

    CREATE TABLE silver.stg_location_tree_version AS
    SELECT
        x.tree_version_id, x.status, x.effective_start_date, x.effective_end_date,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.status, '|', x.effective_start_date, '|', x.effective_end_date, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            CAST(b.TreeVersionId AS VARCHAR(64))                           AS tree_version_id,
            CAST(b.Status AS VARCHAR(30))                                  AS status,
            CAST(b.EffectiveStartDate AS DATE)                             AS effective_start_date,
            CAST(b.EffectiveEndDate AS DATE)                               AS effective_end_date,
            ROW_NUMBER() OVER (
                PARTITION BY b.TreeVersionId
                ORDER BY b._LoadDTS DESC
            ) AS rn
        FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreeversion] b
        WHERE b.TreeCode = 'Location Tree'
              AND b.TreeStructureCode = 'GL_ACCT_FLEX'
              AND b.Status = 'ACTIVE'
              AND CAST(GETDATE() AS DATE) BETWEEN b.EffectiveStartDate AND COALESCE(b.EffectiveEndDate, '9999-12-31')
    ) x
    WHERE x.rn = 1;

    UPDATE t
    SET
        t.status                   = s.status,
        t.effective_start_date     = s.effective_start_date,
        t.effective_end_date       = s.effective_end_date,
        t._row_hash               = s._row_hash,
        t._silver_loaded_at       = @now,
        t._is_deleted             = 0,
        t._run_id                 = @run_id
    FROM silver.location_tree_version t
    INNER JOIN silver.stg_location_tree_version s
        ON t.tree_version_id = s.tree_version_id
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    INSERT INTO silver.location_tree_version
        (tree_version_id, status, effective_start_date, effective_end_date,
         _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.tree_version_id, s.status, s.effective_start_date, s.effective_end_date,
           s._row_hash, @now, 0, @run_id
    FROM silver.stg_location_tree_version s
    WHERE NOT EXISTS (SELECT 1 FROM silver.location_tree_version t
                      WHERE t.tree_version_id = s.tree_version_id);

    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.location_tree_version t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_location_tree_version s
                      WHERE s.tree_version_id = t.tree_version_id);

    DROP TABLE IF EXISTS silver.stg_location_tree_version;
END;
