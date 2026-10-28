CREATE OR ALTER PROCEDURE silver.dq_org_location_map @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    -- key is unique (uses every key column)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.org_location_map', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT organization_id FROM silver.org_location_map
          GROUP BY organization_id HAVING COUNT(*) > 1) x;

    -- key not null
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.org_location_map', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.org_location_map
    WHERE organization_id IS NULL;

    -- main column filled (warning only)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.org_location_map', 'location_segment not null', 'WARN', COUNT(*), @now
    FROM silver.org_location_map
    WHERE location_segment IS NULL AND _is_deleted = 0;

    -- Silver active rows = Bronze distinct keys (after filter)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.org_location_map', 'row count matches bronze', 'ERROR',
           ABS(
             (SELECT COUNT(*) FROM silver.org_location_map WHERE _is_deleted = 0)
           - (SELECT COUNT(*) FROM (
                SELECT DISTINCT TRY_CAST(b.MappingSetValueInputValueConstant1 AS BIGINT) AS k1
                FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_xlabiccextractam_subledgermappingsetvalue] b
                WHERE b.MappingSetValueMappingSetCode IN (SELECT mapping_set_code FROM ref.location_mapping_sets)
                      AND b.MappingSetValueEnabledFlag = 'Y'
                      AND CAST(GETDATE() AS DATE) BETWEEN COALESCE(b.MappingSetValueEffectiveStartDate, '1900-01-01') AND COALESCE(b.MappingSetValueEffectiveEndDate, '9999-12-31')
                      AND TRY_CAST(b.MappingSetValueInputValueConstant1 AS BIGINT) IS NOT NULL
             ) d)
           ), @now;

    -- extra test
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.org_location_map', 'one location per org', 'ERROR',
           (SELECT COUNT(*) FROM (
               SELECT TRY_CAST(b.MappingSetValueInputValueConstant1 AS BIGINT) AS organization_id
               FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_xlabiccextractam_subledgermappingsetvalue] b
               WHERE b.MappingSetValueMappingSetCode IN (SELECT mapping_set_code FROM ref.location_mapping_sets)
                 AND b.MappingSetValueEnabledFlag = 'Y'
                 AND CAST(GETDATE() AS DATE) BETWEEN COALESCE(b.MappingSetValueEffectiveStartDate, '1900-01-01') AND COALESCE(b.MappingSetValueEffectiveEndDate, '9999-12-31')
                 AND TRY_CAST(b.MappingSetValueInputValueConstant1 AS BIGINT) IS NOT NULL
               GROUP BY TRY_CAST(b.MappingSetValueInputValueConstant1 AS BIGINT)
               HAVING COUNT(DISTINCT b.MappingSetValueValueConstant) > 1) x), @now;
END;
