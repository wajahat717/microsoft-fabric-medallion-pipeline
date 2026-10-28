WITH bronze AS (
    SELECT CONVERT(CHAR(7), PjcCostDistLinesAllPrvdrPaDate, 120) AS pa_month,
           COUNT(*) AS row_count,
           SUM(PjcCostDistLinesAllProjectBurdenedCost) AS burdened_cost
    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjcbiccextractam_projectcostdistribution]
    GROUP BY CONVERT(CHAR(7), PjcCostDistLinesAllPrvdrPaDate, 120)
),
silver AS (
    SELECT CONVERT(CHAR(7), pa_date, 120) AS pa_month,
           COUNT(*) AS row_count,
           SUM(burdened_cost_proj_curr) AS burdened_cost
    FROM silver.cost_distribution
    WHERE _is_deleted = 0
    GROUP BY CONVERT(CHAR(7), pa_date, 120)
)
SELECT COALESCE(b.pa_month, s.pa_month) AS pa_month,
       b.row_count     AS bronze_rows,
       s.row_count     AS silver_rows,
       b.burdened_cost AS bronze_cost,
       s.burdened_cost AS silver_cost,
       COALESCE(b.burdened_cost, 0) - COALESCE(s.burdened_cost, 0) AS difference
FROM bronze b
FULL OUTER JOIN silver s ON b.pa_month = s.pa_month
ORDER BY pa_month;
