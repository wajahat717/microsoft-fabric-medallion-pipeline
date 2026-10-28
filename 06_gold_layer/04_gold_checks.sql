/* Gold checks. Run after creating the views. Every query should return what
   the comment says before Power BI is pointed at the Gold layer. */

/* 1. Gold cost must equal Silver cost (the view must not add or drop money).
      Expect difference = 0. */
SELECT
    (SELECT SUM(burdened_cost_proj_curr) FROM silver.cost_distribution WHERE _is_deleted = 0) AS silver_cost,
    (SELECT SUM(burdened_cost) FROM gold.fact_project_cost)                                   AS gold_cost,
    (SELECT SUM(burdened_cost_proj_curr) FROM silver.cost_distribution WHERE _is_deleted = 0)
  - (SELECT SUM(burdened_cost) FROM gold.fact_project_cost)                                   AS difference;

/* 2. Fact grain is unique. Expect 0 rows. */
SELECT expenditure_item_id, line_num, COUNT(*) AS copies
FROM gold.fact_project_cost
GROUP BY expenditure_item_id, line_num
HAVING COUNT(*) > 1;

/* 3. Dimension keys are unique. Expect 0 rows from each. */
SELECT organization_key, COUNT(*) FROM gold.dim_organization GROUP BY organization_key HAVING COUNT(*) > 1;
SELECT expenditure_type_key, COUNT(*) FROM gold.dim_expenditure_type GROUP BY expenditure_type_key HAVING COUNT(*) > 1;
SELECT date_key, COUNT(*) FROM gold.dim_date GROUP BY date_key HAVING COUNT(*) > 1;

/* 4. Every fact key finds its dimension row. Expect orphan_rows = 0 for each. */
SELECT 'organization' AS dimension, COUNT(*) AS orphan_rows
FROM gold.fact_project_cost f
LEFT JOIN gold.dim_organization d ON d.organization_key = f.organization_key
WHERE d.organization_key IS NULL
UNION ALL
SELECT 'expenditure_type', COUNT(*)
FROM gold.fact_project_cost f
LEFT JOIN gold.dim_expenditure_type d ON d.expenditure_type_key = f.expenditure_type_key
WHERE d.expenditure_type_key IS NULL
UNION ALL
SELECT 'gl_date', COUNT(*)
FROM gold.fact_project_cost f
LEFT JOIN gold.dim_date d ON d.date_key = f.gl_date_key
WHERE d.date_key IS NULL AND f.gl_date_key IS NOT NULL;

/* 5. How much cost sits on "Unknown" or "Unmapped" members. Not an error, but
      report it so the business knows what is not yet classified. */
SELECT d.region_name, SUM(f.burdened_cost) AS burdened_cost, COUNT(*) AS lines
FROM gold.fact_project_cost f
JOIN gold.dim_organization d ON d.organization_key = f.organization_key
WHERE d.region_name IN ('Unknown', 'Unmapped')
GROUP BY d.region_name;
