/* Gold fact: one row per cost distribution line (the grain the GL sees).
   Cost lines come from silver.cost_distribution; the descriptive keys come from
   the parent silver.expenditure_item. A LEFT JOIN keeps cost lines whose parent
   item is missing, and they land on the -1 "Unknown" members. */

CREATE OR ALTER VIEW gold.fact_project_cost AS
SELECT
    cd.expenditure_item_id,
    cd.line_num,
    CAST(CONVERT(CHAR(8), cd.gl_date, 112) AS INT)            AS gl_date_key,
    CAST(CONVERT(CHAR(8), ei.expenditure_item_date, 112) AS INT) AS item_date_key,
    cd.project_id                                            AS project_key,
    cd.task_id                                               AS task_key,
    COALESCE(ei.expenditure_organization_id, -1)             AS organization_key,
    COALESCE(ei.expenditure_type_id, -1)                     AS expenditure_type_key,
    COALESCE(ei.transaction_source_id, -1)                   AS transaction_source_key,
    COALESCE(ei.project_role_id, -1)                         AS project_role_key,
    COALESCE(ei.billable_flag, 'N')                          AS billable_flag,
    cd.line_type,
    cd.gl_period_name,
    cd.project_currency_code,
    cd.quantity,
    cd.raw_cost_proj_curr                                    AS raw_cost,
    cd.burdened_cost_proj_curr                               AS burdened_cost,
    CASE WHEN ei.expenditure_item_id IS NULL THEN 1 ELSE 0 END AS missing_parent_item
FROM silver.cost_distribution cd
LEFT JOIN silver.expenditure_item ei
       ON ei.expenditure_item_id = cd.expenditure_item_id
      AND ei._is_deleted = 0
WHERE cd._is_deleted = 0;
GO
