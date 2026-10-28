CREATE OR ALTER PROCEDURE silver.load_location_hierarchy @run_id VARCHAR(100), @region_depth INT = 3
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();
    DECLARE @leaf_depth INT = (SELECT MAX(depth) FROM silver.location_tree_node WHERE _is_deleted = 0);

    DELETE FROM silver.location_hierarchy;

    INSERT INTO silver.location_hierarchy
        (location_segment, location_name, location_depth,
         region_segment, region_name, region_depth, _silver_loaded_at, _run_id)
    SELECT
        h.location_segment,
        lv.location_name,
        h.depth,
        h.region_segment,
        rv.location_name,
        @region_depth,
        @now,
        @run_id
    FROM (
        -- walk up to 4 levels and keep the ancestor at the region depth
        SELECT
            n.location_segment,
            n.depth,
            CASE
                WHEN n.depth  = @region_depth THEN n.location_segment
                WHEN p1.depth = @region_depth THEN p1.location_segment
                WHEN p2.depth = @region_depth THEN p2.location_segment
                WHEN p3.depth = @region_depth THEN p3.location_segment
                WHEN p4.depth = @region_depth THEN p4.location_segment
            END AS region_segment
        FROM silver.location_tree_node n
        LEFT JOIN silver.location_tree_node p1 ON p1.location_segment = n.parent_location_segment  AND p1._is_deleted = 0
        LEFT JOIN silver.location_tree_node p2 ON p2.location_segment = p1.parent_location_segment AND p2._is_deleted = 0
        LEFT JOIN silver.location_tree_node p3 ON p3.location_segment = p2.parent_location_segment AND p3._is_deleted = 0
        LEFT JOIN silver.location_tree_node p4 ON p4.location_segment = p3.parent_location_segment AND p4._is_deleted = 0
        WHERE n._is_deleted = 0
          AND n.depth = @leaf_depth
    ) h
    LEFT JOIN (SELECT location_segment, MAX(location_name) AS location_name
               FROM silver.location_value WHERE _is_deleted = 0
               GROUP BY location_segment) lv ON lv.location_segment = h.location_segment
    LEFT JOIN (SELECT location_segment, MAX(location_name) AS location_name
               FROM silver.location_value WHERE _is_deleted = 0
               GROUP BY location_segment) rv ON rv.location_segment = h.region_segment;
END;
