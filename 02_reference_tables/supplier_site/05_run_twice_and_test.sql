EXEC silver.load_supplier_site @run_id = 'supplier_site-test-1';
EXEC silver.dq_supplier_site   @run_id = 'supplier_site-test-1';
EXEC silver.load_supplier_site @run_id = 'supplier_site-test-2';
EXEC silver.dq_supplier_site   @run_id = 'supplier_site-test-2';

SELECT COUNT(*) AS active_rows,
       SUM(CASE WHEN _run_id = 'supplier_site-test-2' THEN 1 ELSE 0 END) AS rows_touched_by_run2
FROM silver.supplier_site WHERE _is_deleted = 0;

SELECT run_id, test_name, severity, failed_rows
FROM ops.dq_result
WHERE table_name = 'silver.supplier_site'
ORDER BY run_id, test_name;
