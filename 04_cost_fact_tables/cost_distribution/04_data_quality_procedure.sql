CREATE OR ALTER PROCEDURE silver.dq_cost_distribution @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    -- key is unique (uses every key column)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.cost_distribution', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT expenditure_item_id, line_num FROM silver.cost_distribution
          GROUP BY expenditure_item_id, line_num HAVING COUNT(*) > 1) x;

    -- key not null
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.cost_distribution', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.cost_distribution
    WHERE expenditure_item_id IS NULL OR line_num IS NULL;

    -- main column filled (warning only)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.cost_distribution', 'burdened_cost_proj_curr not null', 'WARN', COUNT(*), @now
    FROM silver.cost_distribution
    WHERE burdened_cost_proj_curr IS NULL AND _is_deleted = 0;

    -- Silver active rows = Bronze distinct keys
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.cost_distribution', 'row count matches bronze', 'ERROR',
           ABS((SELECT COUNT(*) FROM silver.cost_distribution WHERE _is_deleted = 0)
             - (SELECT COUNT(*) FROM (SELECT DISTINCT b.PjcCostDistLinesAllExpenditureItemId AS k1, b.PjcCostDistLinesAllLineNum AS k2 FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjcbiccextractam_projectcostdistribution] b) d)), @now;

    -- extra test (Task 9)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.cost_distribution', 'expenditure_item exists in silver.expenditure_item', 'ERROR',
           (SELECT COUNT(*) FROM silver.cost_distribution c
              WHERE c._is_deleted = 0
                AND NOT EXISTS (SELECT 1 FROM silver.expenditure_item e
                                WHERE e.expenditure_item_id = c.expenditure_item_id AND e._is_deleted = 0)), @now;

    -- extra test (Task 9)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.cost_distribution', 'project_id and task_id not null', 'ERROR',
           (SELECT COUNT(*) FROM silver.cost_distribution WHERE _is_deleted = 0 AND (project_id IS NULL OR task_id IS NULL)), @now;

    -- extra test (Task 9)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.cost_distribution', 'single currency (proj = projfunc burdened cost)', 'WARN',
           (SELECT COUNT(*) FROM silver.cost_distribution WHERE _is_deleted = 0 AND burdened_cost_proj_curr <> burdened_cost_projfunc), @now;
END;
