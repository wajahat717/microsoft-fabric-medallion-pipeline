SELECT
    (SELECT COUNT(*) FROM silver.location_tree_node WHERE _is_deleted = 0) AS tree_nodes,
    (SELECT COUNT(*) FROM silver.location_tree_node WHERE _is_deleted = 0
       AND depth = (SELECT MAX(depth) FROM silver.location_tree_node WHERE _is_deleted = 0)) AS bottom_locations,
    (SELECT COUNT(*) FROM silver.location_value WHERE _is_deleted = 0) AS location_names;
