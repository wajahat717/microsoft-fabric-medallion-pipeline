EXEC silver.load_location_tree_node @run_id = 'location_tree_node-test-1';
EXEC silver.dq_location_tree_node   @run_id = 'location_tree_node-test-1';
EXEC silver.load_location_tree_node @run_id = 'location_tree_node-test-2';
EXEC silver.dq_location_tree_node   @run_id = 'location_tree_node-test-2';

SELECT COUNT(*) AS active_rows,
       SUM(CASE WHEN _run_id = 'location_tree_node-test-2' THEN 1 ELSE 0 END) AS rows_touched_by_run2
FROM silver.location_tree_node WHERE _is_deleted = 0;

SELECT run_id, test_name, severity, failed_rows
FROM ops.dq_result
WHERE table_name = 'silver.location_tree_node'
ORDER BY run_id, test_name;
