/* Gold dimensions. Each view returns one row per key and only active Silver rows.
   Every dimension also gets an "Unknown" row (key -1), so a fact row with a
   missing reference still shows up in reports instead of disappearing. */

CREATE OR ALTER VIEW gold.dim_organization AS
WITH current_map AS (
    SELECT m.organization_id,
           m.location_segment,
           ROW_NUMBER() OVER (PARTITION BY m.organization_id
                              ORDER BY m.effective_start_date DESC) AS rn
    FROM silver.org_location_map m
    WHERE m._is_deleted = 0
      AND m.enabled_flag = 'Y'
      AND CAST(GETDATE() AS DATE) BETWEEN COALESCE(m.effective_start_date, '1900-01-01')
                                      AND COALESCE(m.effective_end_date, '9999-12-31')
)
SELECT
    o.organization_id                                 AS organization_key,
    o.organization_name,
    cm.location_segment,
    COALESCE(lh.location_name, o.organization_name)   AS location_name,
    COALESCE(lh.region_segment, 'UNMAPPED')           AS region_segment,
    COALESCE(lh.region_name, 'Unmapped')              AS region_name
FROM silver.organization o
LEFT JOIN current_map cm
       ON cm.organization_id = o.organization_id AND cm.rn = 1
LEFT JOIN silver.location_hierarchy lh
       ON lh.location_segment = cm.location_segment
WHERE o._is_deleted = 0
UNION ALL
SELECT -1, 'Unknown', NULL, 'Unknown', 'UNKNOWN', 'Unknown';
GO

/* Needs silver.expenditure_type (the first table built with the Silver pattern):
   expenditure_type_id, expenditure_type_name, expenditure_category_id. */
CREATE OR ALTER VIEW gold.dim_expenditure_type AS
SELECT
    et.expenditure_type_id                                   AS expenditure_type_key,
    et.expenditure_type_name,
    COALESCE(ec.expenditure_category_name, 'Uncategorised')  AS expenditure_category_name
FROM silver.expenditure_type et
LEFT JOIN silver.expenditure_category ec
       ON ec.expenditure_category_id = et.expenditure_category_id
      AND ec._is_deleted = 0
WHERE et._is_deleted = 0
UNION ALL
SELECT -1, 'Unknown', 'Unknown';
GO

CREATE OR ALTER VIEW gold.dim_transaction_source AS
SELECT
    ts.transaction_source_id AS transaction_source_key,
    ts.user_transaction_source AS transaction_source_name
FROM silver.transaction_source ts
WHERE ts._is_deleted = 0
UNION ALL
SELECT -1, 'Manual / no source';
GO

CREATE OR ALTER VIEW gold.dim_project_role AS
SELECT
    pr.project_role_id   AS project_role_key,
    pr.project_role_name
FROM silver.project_role pr
WHERE pr._is_deleted = 0
UNION ALL
SELECT -1, 'Unknown';
GO
