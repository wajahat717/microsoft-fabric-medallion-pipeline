/* Test: the incremental load must give exactly the same Silver result
   as the full load. Run on the practice warehouse. */

/* 1. Take a snapshot of the current Silver totals (after a full load). */
DROP TABLE IF EXISTS ops.test_snapshot_cost;
CREATE TABLE ops.test_snapshot_cost AS
SELECT COUNT(*) AS active_rows, SUM(burdened_cost_proj_curr) AS burdened_cost
FROM silver.cost_distribution WHERE _is_deleted = 0;

/* 2. Run the incremental load twice. Run 1 picks up only recent changes;
      run 2 should change nothing at all. */
EXEC silver.load_cost_distribution_incremental @run_id = 'incr-test-1';
EXEC silver.load_cost_distribution_incremental @run_id = 'incr-test-2';

/* 3. Compare. Expect: same totals as a full load would give,
      rows_touched_by_run2 = 0, and the watermark moved forward. */
SELECT
    s.active_rows   AS before_rows,
    (SELECT COUNT(*) FROM silver.cost_distribution WHERE _is_deleted = 0) AS after_rows,
    s.burdened_cost AS before_cost,
    (SELECT SUM(burdened_cost_proj_curr) FROM silver.cost_distribution WHERE _is_deleted = 0) AS after_cost,
    (SELECT COUNT(*) FROM silver.cost_distribution WHERE _run_id = 'incr-test-2') AS rows_touched_by_run2
FROM ops.test_snapshot_cost s;

SELECT * FROM ops.load_watermark WHERE table_name = 'silver.cost_distribution';

DROP TABLE IF EXISTS ops.test_snapshot_cost;
