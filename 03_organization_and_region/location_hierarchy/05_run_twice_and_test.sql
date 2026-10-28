EXEC silver.load_location_hierarchy @run_id = 'location_hierarchy-test-1';
EXEC silver.dq_location_hierarchy   @run_id = 'location_hierarchy-test-1';
EXEC silver.load_location_hierarchy @run_id = 'location_hierarchy-test-2';
EXEC silver.dq_location_hierarchy   @run_id = 'location_hierarchy-test-2';

SELECT region_name, COUNT(*) AS locations
FROM silver.location_hierarchy
GROUP BY region_name
ORDER BY region_name;

SELECT run_id, test_name, severity, failed_rows
FROM ops.dq_result
WHERE table_name = 'silver.location_hierarchy'
ORDER BY run_id, test_name;
