EXEC silver.load_org_location_map @run_id = 'org_location_map-test-1';
EXEC silver.dq_org_location_map   @run_id = 'org_location_map-test-1';
EXEC silver.load_org_location_map @run_id = 'org_location_map-test-2';
EXEC silver.dq_org_location_map   @run_id = 'org_location_map-test-2';

SELECT COUNT(*) AS active_rows,
       SUM(CASE WHEN _run_id = 'org_location_map-test-2' THEN 1 ELSE 0 END) AS rows_touched_by_run2
FROM silver.org_location_map WHERE _is_deleted = 0;

SELECT run_id, test_name, severity, failed_rows
FROM ops.dq_result
WHERE table_name = 'silver.org_location_map'
ORDER BY run_id, test_name;
