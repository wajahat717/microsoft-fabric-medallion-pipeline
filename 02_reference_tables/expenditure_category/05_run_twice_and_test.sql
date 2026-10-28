EXEC silver.load_expenditure_category @run_id = 'expenditure_category-test-1';
EXEC silver.dq_expenditure_category   @run_id = 'expenditure_category-test-1';
EXEC silver.load_expenditure_category @run_id = 'expenditure_category-test-2';
EXEC silver.dq_expenditure_category   @run_id = 'expenditure_category-test-2';

SELECT COUNT(*) AS active_rows,
       SUM(CASE WHEN _run_id = 'expenditure_category-test-2' THEN 1 ELSE 0 END) AS rows_touched_by_run2
FROM silver.expenditure_category WHERE _is_deleted = 0;

SELECT run_id, test_name, severity, failed_rows
FROM ops.dq_result
WHERE table_name = 'silver.expenditure_category'
ORDER BY run_id, test_name;
