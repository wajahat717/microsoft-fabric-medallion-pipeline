/* Weekly delete check for incrementally loaded tables.
   Incremental runs never soft-delete, because a short extract does not list
   every row. Once a week, compare Silver keys with ALL Bronze keys and
   soft-delete only the rows that are truly gone from the source. */

CREATE OR ALTER PROCEDURE silver.delete_check_cost_distribution @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    DROP TABLE IF EXISTS silver.stg_cost_distribution_keys;

    CREATE TABLE silver.stg_cost_distribution_keys AS
    SELECT DISTINCT
        b.PjcCostDistLinesAllExpenditureItemId AS expenditure_item_id,
        CAST(b.PjcCostDistLinesAllLineNum AS INT) AS line_num
    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjcbiccextractam_projectcostdistribution] b;

    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.cost_distribution t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_cost_distribution_keys k
                      WHERE k.expenditure_item_id = t.expenditure_item_id
                        AND k.line_num = t.line_num);

    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.cost_distribution', 'weekly delete check: rows soft-deleted', 'WARN',
           (SELECT COUNT(*) FROM silver.cost_distribution WHERE _run_id = @run_id AND _is_deleted = 1),
           @now;

    DROP TABLE IF EXISTS silver.stg_cost_distribution_keys;
END;
