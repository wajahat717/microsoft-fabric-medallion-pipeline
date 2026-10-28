/* Join cost to the organization version that was valid on the GL date,
   so history reports show the region as it was at the time of the cost. */

CREATE OR ALTER VIEW gold.fact_project_cost_history AS
SELECT
    f.*,
    COALESCE(h.organization_sk, -1) AS organization_sk
FROM gold.fact_project_cost f
LEFT JOIN gold.dim_date d
       ON d.date_key = f.gl_date_key
LEFT JOIN gold.dim_organization_history h
       ON h.organization_key = f.organization_key
      AND d.calendar_date BETWEEN h.valid_from AND h.valid_to;
GO

/* Tests (expect 0 rows from each) */

/* 1. Only one current row per organization. */
SELECT organization_key, COUNT(*) AS current_rows
FROM gold.dim_organization_history
WHERE is_current = 1
GROUP BY organization_key
HAVING COUNT(*) > 1;

/* 2. No overlapping date ranges for the same organization. */
SELECT a.organization_key, a.organization_sk, b.organization_sk
FROM gold.dim_organization_history a
JOIN gold.dim_organization_history b
  ON a.organization_key = b.organization_key
 AND a.organization_sk < b.organization_sk
 AND a.valid_from <= b.valid_to
 AND b.valid_from <= a.valid_to;

/* 3. The history join must not duplicate cost lines. */
SELECT expenditure_item_id, line_num, COUNT(*) AS copies
FROM gold.fact_project_cost_history
GROUP BY expenditure_item_id, line_num
HAVING COUNT(*) > 1;
