WITH f AS (
    SELECT TRY_CAST(b.MappingSetValueInputValueConstant1 AS BIGINT) AS k1
    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_xlabiccextractam_subledgermappingsetvalue] b
    WHERE b.MappingSetValueMappingSetCode IN (SELECT mapping_set_code FROM ref.location_mapping_sets)
          AND b.MappingSetValueEnabledFlag = 'Y'
          AND CAST(GETDATE() AS DATE) BETWEEN COALESCE(b.MappingSetValueEffectiveStartDate, '1900-01-01') AND COALESCE(b.MappingSetValueEffectiveEndDate, '9999-12-31')
          AND TRY_CAST(b.MappingSetValueInputValueConstant1 AS BIGINT) IS NOT NULL
)
SELECT
    COUNT(*)                                                    AS total_rows_after_filter,
    (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM f) d)          AS unique_keys,
    COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM f) d) AS duplicate_keys
FROM f;
