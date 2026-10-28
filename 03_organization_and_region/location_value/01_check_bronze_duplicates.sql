WITH f AS (
    SELECT b.ValueId AS k1
    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_valuesetvalues] b
    WHERE b.AttributeCategory = 'Location Tree'
          AND b.Language = 'US'
)
SELECT
    COUNT(*)                                                    AS total_rows_after_filter,
    (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM f) d)          AS unique_keys,
    COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM f) d) AS duplicate_keys
FROM f;
