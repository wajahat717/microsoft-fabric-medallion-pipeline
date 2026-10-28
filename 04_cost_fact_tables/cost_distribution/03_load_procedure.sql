CREATE OR ALTER PROCEDURE silver.load_cost_distribution @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    /* ---------- STEP 1: STAGE ---------- */
    DROP TABLE IF EXISTS silver.stg_cost_distribution;

    CREATE TABLE silver.stg_cost_distribution AS
    SELECT
        x.expenditure_item_id, x.line_num, x.line_type, x.project_id, x.task_id, x.pa_date, x.pa_period_name, x.gl_date, x.gl_period_name, x.quantity, x.raw_cost_proj_curr, x.burdened_cost_proj_curr, x.project_currency_code, x.raw_cost_projfunc, x.burdened_cost_projfunc, x.reversed_flag, x.line_num_reversed, x.acct_event_id, x.transfer_status_code, x.last_update_date,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.line_type, '|',
            x.project_id, '|',
            x.task_id, '|',
            x.pa_date, '|',
            x.pa_period_name, '|',
            x.gl_date, '|',
            x.gl_period_name, '|',
            x.quantity, '|',
            x.raw_cost_proj_curr, '|',
            x.burdened_cost_proj_curr, '|',
            x.project_currency_code, '|',
            x.raw_cost_projfunc, '|',
            x.burdened_cost_projfunc, '|',
            x.reversed_flag, '|',
            x.line_num_reversed, '|',
            x.acct_event_id, '|',
            x.transfer_status_code, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            b.PjcCostDistLinesAllExpenditureItemId                     AS expenditure_item_id,
            CAST(b.PjcCostDistLinesAllLineNum AS INT)                  AS line_num,
            CAST(b.PjcCostDistLinesAllLineType AS VARCHAR(30))         AS line_type,
            b.PjcCostDistLinesAllProjectId                             AS project_id,
            b.PjcCostDistLinesAllTaskId                                AS task_id,
            CAST(b.PjcCostDistLinesAllPrvdrPaDate AS DATE)             AS pa_date,
            CAST(b.PjcCostDistLinesAllPrvdrPaPeriodName AS VARCHAR(15)) AS pa_period_name,
            CAST(b.PjcCostDistLinesAllPrvdrGlDate AS DATE)             AS gl_date,
            CAST(b.PjcCostDistLinesAllPrvdrGlPeriodName AS VARCHAR(15)) AS gl_period_name,
            CAST(b.PjcCostDistLinesAllQuantity AS DECIMAL(19,4))       AS quantity,
            CAST(b.PjcCostDistLinesAllProjectRawCost AS DECIMAL(19,4)) AS raw_cost_proj_curr,
            CAST(b.PjcCostDistLinesAllProjectBurdenedCost AS DECIMAL(19,4)) AS burdened_cost_proj_curr,
            CAST(b.PjcCostDistLinesAllProjectCurrencyCode AS VARCHAR(15)) AS project_currency_code,
            CAST(b.PjcCostDistLinesAllProjfuncRawCost AS DECIMAL(19,4)) AS raw_cost_projfunc,
            CAST(b.PjcCostDistLinesAllProjfuncBurdenedCost AS DECIMAL(19,4)) AS burdened_cost_projfunc,
            CAST(b.PjcCostDistLinesAllReversedFlag AS VARCHAR(1))      AS reversed_flag,
            CAST(b.PjcCostDistLinesAllLineNumReversed AS INT)          AS line_num_reversed,
            b.PjcCostDistLinesAllAcctEventId                           AS acct_event_id,
            CAST(b.PjcCostDistLinesAllTransferStatusCode AS VARCHAR(30)) AS transfer_status_code,
            b.PjcCostDistLinesAllLastUpdateDate                        AS last_update_date,
            ROW_NUMBER() OVER (
                PARTITION BY b.PjcCostDistLinesAllExpenditureItemId, b.PjcCostDistLinesAllLineNum
                ORDER BY b.PjcCostDistLinesAllLastUpdateDate DESC, b._LoadDTS DESC
            ) AS rn
        FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjcbiccextractam_projectcostdistribution] b
        -- no filter
    ) x
    WHERE x.rn = 1;

    /* ---------- STEP 2: UPDATE rows that changed ---------- */
    UPDATE t
    SET
        t.line_type                      = s.line_type,
        t.project_id                     = s.project_id,
        t.task_id                        = s.task_id,
        t.pa_date                        = s.pa_date,
        t.pa_period_name                 = s.pa_period_name,
        t.gl_date                        = s.gl_date,
        t.gl_period_name                 = s.gl_period_name,
        t.quantity                       = s.quantity,
        t.raw_cost_proj_curr             = s.raw_cost_proj_curr,
        t.burdened_cost_proj_curr        = s.burdened_cost_proj_curr,
        t.project_currency_code          = s.project_currency_code,
        t.raw_cost_projfunc              = s.raw_cost_projfunc,
        t.burdened_cost_projfunc         = s.burdened_cost_projfunc,
        t.reversed_flag                  = s.reversed_flag,
        t.line_num_reversed              = s.line_num_reversed,
        t.acct_event_id                  = s.acct_event_id,
        t.transfer_status_code           = s.transfer_status_code,
        t.last_update_date               = s.last_update_date,
        t._row_hash                       = s._row_hash,
        t._silver_loaded_at               = @now,
        t._is_deleted                     = 0,
        t._run_id                         = @run_id
    FROM silver.cost_distribution t
    INNER JOIN silver.stg_cost_distribution s
        ON t.expenditure_item_id = s.expenditure_item_id AND t.line_num = s.line_num
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    /* ---------- STEP 3: INSERT new rows ---------- */
    INSERT INTO silver.cost_distribution
        (expenditure_item_id, line_num, line_type, project_id, task_id, pa_date, pa_period_name, gl_date, gl_period_name, quantity, raw_cost_proj_curr, burdened_cost_proj_curr, project_currency_code, raw_cost_projfunc, burdened_cost_projfunc, reversed_flag, line_num_reversed, acct_event_id, transfer_status_code, last_update_date,
         _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.expenditure_item_id, s.line_num, s.line_type, s.project_id, s.task_id, s.pa_date, s.pa_period_name, s.gl_date, s.gl_period_name, s.quantity, s.raw_cost_proj_curr, s.burdened_cost_proj_curr, s.project_currency_code, s.raw_cost_projfunc, s.burdened_cost_projfunc, s.reversed_flag, s.line_num_reversed, s.acct_event_id, s.transfer_status_code, s.last_update_date,
           s._row_hash, @now, 0, @run_id
    FROM silver.stg_cost_distribution s
    WHERE NOT EXISTS (SELECT 1 FROM silver.cost_distribution t
                      WHERE t.expenditure_item_id = s.expenditure_item_id AND t.line_num = s.line_num);

    /* ---------- STEP 4: SOFT-DELETE rows gone from Bronze ---------- */
    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.cost_distribution t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_cost_distribution s
                      WHERE s.expenditure_item_id = t.expenditure_item_id AND s.line_num = t.line_num);

    DROP TABLE IF EXISTS silver.stg_cost_distribution;
END;
