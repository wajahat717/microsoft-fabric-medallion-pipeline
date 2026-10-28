WITH f AS (
    SELECT b.TreeVersionId AS k1
    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreeversion] b
    WHERE b.TreeCode = 'Location Tree'
          AND b.TreeStructureCode = 'GL_ACCT_FLEX'
          AND b.Status = 'ACTIVE'
          AND CAST(GETDATE() AS DATE) BETWEEN b.EffectiveStartDate AND COALESCE(b.EffectiveEndDate, '9999-12-31')
)
SELECT
    COUNT(*)                                                    AS total_rows_after_filter,
    (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM f) d)          AS unique_keys,
    COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM f) d) AS duplicate_keys
FROM f;
