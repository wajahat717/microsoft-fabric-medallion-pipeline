WITH f AS (
    SELECT b.PjcCostDistLinesAllExpenditureItemId AS k1, b.PjcCostDistLinesAllLineNum AS k2
    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjcbiccextractam_projectcostdistribution] b
)
SELECT
    COUNT(*)                                                       AS total_rows,
    (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM f) d)            AS unique_keys,
    COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM f) d) AS duplicate_keys
FROM f;
