CREATE OR ALTER PROCEDURE silver.load_org_location_map @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    DROP TABLE IF EXISTS silver.stg_org_location_map;

    CREATE TABLE silver.stg_org_location_map AS
    SELECT
        x.organization_id, x.location_segment, x.mapping_set_code, x.enabled_flag, x.effective_start_date, x.effective_end_date,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.location_segment, '|', x.mapping_set_code, '|', x.enabled_flag, '|', x.effective_start_date, '|', x.effective_end_date, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            TRY_CAST(b.MappingSetValueInputValueConstant1 AS BIGINT)       AS organization_id,
            CAST(b.MappingSetValueValueConstant AS VARCHAR(30))            AS location_segment,
            CAST(b.MappingSetValueMappingSetCode AS VARCHAR(30))           AS mapping_set_code,
            CAST(b.MappingSetValueEnabledFlag AS VARCHAR(1))               AS enabled_flag,
            CAST(b.MappingSetValueEffectiveStartDate AS DATE)              AS effective_start_date,
            CAST(b.MappingSetValueEffectiveEndDate AS DATE)                AS effective_end_date,
            ROW_NUMBER() OVER (
                PARTITION BY TRY_CAST(b.MappingSetValueInputValueConstant1 AS BIGINT)
                ORDER BY b.MappingSetValueMappingSetCode, b._LoadDTS DESC
            ) AS rn
        FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_xlabiccextractam_subledgermappingsetvalue] b
        WHERE b.MappingSetValueMappingSetCode IN (SELECT mapping_set_code FROM ref.location_mapping_sets)
              AND b.MappingSetValueEnabledFlag = 'Y'
              AND CAST(GETDATE() AS DATE) BETWEEN COALESCE(b.MappingSetValueEffectiveStartDate, '1900-01-01') AND COALESCE(b.MappingSetValueEffectiveEndDate, '9999-12-31')
              AND TRY_CAST(b.MappingSetValueInputValueConstant1 AS BIGINT) IS NOT NULL
    ) x
    WHERE x.rn = 1;

    UPDATE t
    SET
        t.location_segment         = s.location_segment,
        t.mapping_set_code         = s.mapping_set_code,
        t.enabled_flag             = s.enabled_flag,
        t.effective_start_date     = s.effective_start_date,
        t.effective_end_date       = s.effective_end_date,
        t._row_hash               = s._row_hash,
        t._silver_loaded_at       = @now,
        t._is_deleted             = 0,
        t._run_id                 = @run_id
    FROM silver.org_location_map t
    INNER JOIN silver.stg_org_location_map s
        ON t.organization_id = s.organization_id
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    INSERT INTO silver.org_location_map
        (organization_id, location_segment, mapping_set_code, enabled_flag, effective_start_date, effective_end_date,
         _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.organization_id, s.location_segment, s.mapping_set_code, s.enabled_flag, s.effective_start_date, s.effective_end_date,
           s._row_hash, @now, 0, @run_id
    FROM silver.stg_org_location_map s
    WHERE NOT EXISTS (SELECT 1 FROM silver.org_location_map t
                      WHERE t.organization_id = s.organization_id);

    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.org_location_map t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_org_location_map s
                      WHERE s.organization_id = t.organization_id);

    DROP TABLE IF EXISTS silver.stg_org_location_map;
END;
