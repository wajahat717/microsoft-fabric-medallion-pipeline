WITH f AS (
    SELECT b.OrganizationId AS k1
    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_hcm_organizationam_organizationunit] b
    WHERE b.OrganizationUnitTranslationPEOLanguage = 'US'
          AND CAST(GETDATE() AS DATE) BETWEEN COALESCE(b.EffectiveStartDate, '1900-01-01') AND COALESCE(b.EffectiveEndDate, '9999-12-31')
)
SELECT
    COUNT(*)                                                    AS total_rows_after_filter,
    (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM f) d)          AS unique_keys,
    COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM f) d) AS duplicate_keys
FROM f;
