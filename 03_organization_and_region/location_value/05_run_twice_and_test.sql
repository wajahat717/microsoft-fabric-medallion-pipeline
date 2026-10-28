EXEC silver.load_location_value @run_id = 'location_value-test-1';
EXEC silver.dq_location_value   @run_id = 'location_value-test-1';
EXEC silver.load_location_value @run_id = 'location_value-test-2';
EXEC silver.dq_location_value   @run_id = 'location_value-test-2';

SELECT COUNT(*) AS active_rows,
       SUM(CASE WHEN _run_id = 'location_value-test-2' THEN 1 ELSE 0 END) AS rows_touched_by_run2
FROM silver.location_value WHERE _is_deleted = 0;

SELECT run_id, test_name, severity, failed_rows
FROM ops.dq_result
WHERE table_name = 'silver.location_value'
ORDER BY run_id, test_name;
