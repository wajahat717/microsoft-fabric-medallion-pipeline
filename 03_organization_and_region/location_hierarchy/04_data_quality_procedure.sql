CREATE OR ALTER PROCEDURE silver.dq_location_hierarchy @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_hierarchy', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT location_segment FROM silver.location_hierarchy
          GROUP BY location_segment HAVING COUNT(*) > 1) x;

    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_hierarchy', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.location_hierarchy WHERE location_segment IS NULL;

    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_hierarchy', 'region found', 'ERROR', COUNT(*), @now
    FROM silver.location_hierarchy WHERE region_segment IS NULL;

    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_hierarchy', 'region_name not null', 'WARN', COUNT(*), @now
    FROM silver.location_hierarchy WHERE region_name IS NULL;

    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_hierarchy', 'row count matches tree', 'ERROR',
           ABS((SELECT COUNT(*) FROM silver.location_hierarchy)
             - (SELECT COUNT(*) FROM silver.location_tree_node WHERE _is_deleted = 0
                  AND depth = (SELECT MAX(depth) FROM silver.location_tree_node WHERE _is_deleted = 0))), @now;
END;
