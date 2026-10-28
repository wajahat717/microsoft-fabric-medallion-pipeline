EXEC silver.load_transaction_source @run_id = 'transaction_source-test-1';
EXEC silver.dq_transaction_source   @run_id = 'transaction_source-test-1';
EXEC silver.load_transaction_source @run_id = 'transaction_source-test-2';
EXEC silver.dq_transaction_source   @run_id = 'transaction_source-test-2';

SELECT COUNT(*) AS active_rows,
       SUM(CASE WHEN _run_id = 'transaction_source-test-2' THEN 1 ELSE 0 END) AS rows_touched_by_run2
FROM silver.transaction_source WHERE _is_deleted = 0;

SELECT run_id, test_name, severity, failed_rows
FROM ops.dq_result
WHERE table_name = 'silver.transaction_source'
ORDER BY run_id, test_name;
