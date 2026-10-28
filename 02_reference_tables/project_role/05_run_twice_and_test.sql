EXEC silver.load_project_role @run_id = 'project_role-test-1';
EXEC silver.dq_project_role   @run_id = 'project_role-test-1';
EXEC silver.load_project_role @run_id = 'project_role-test-2';
EXEC silver.dq_project_role   @run_id = 'project_role-test-2';

SELECT COUNT(*) AS active_rows,
       SUM(CASE WHEN _run_id = 'project_role-test-2' THEN 1 ELSE 0 END) AS rows_touched_by_run2
FROM silver.project_role WHERE _is_deleted = 0;

SELECT run_id, test_name, severity, failed_rows
FROM ops.dq_result
WHERE table_name = 'silver.project_role'
ORDER BY run_id, test_name;
