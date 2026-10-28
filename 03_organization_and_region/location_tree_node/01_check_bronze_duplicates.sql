WITH f AS (
    SELECT b.TreeNodeId AS k1, b.TreeCode AS k2, b.TreeStructureCode AS k3
    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreenode] b
    WHERE b.TreeCode = 'Location Tree'
          AND b.TreeStructureCode = 'GL_ACCT_FLEX'
          AND b.TreeVersionId IN (
              SELECT v.TreeVersionId
              FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreeversion] v
              WHERE v.TreeCode = 'Location Tree'
                AND v.TreeStructureCode = 'GL_ACCT_FLEX'
                AND v.Status = 'ACTIVE'
                AND CAST(GETDATE() AS DATE) BETWEEN v.EffectiveStartDate AND COALESCE(v.EffectiveEndDate, '9999-12-31')
          )
)
SELECT
    COUNT(*)                                                    AS total_rows_after_filter,
    (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM f) d)          AS unique_keys,
    COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM f) d) AS duplicate_keys
FROM f;
