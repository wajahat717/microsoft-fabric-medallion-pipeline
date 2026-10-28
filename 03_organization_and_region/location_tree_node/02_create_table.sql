CREATE TABLE silver.location_tree_node (
    tree_node_id               VARCHAR(64)    NOT NULL,
    tree_version_id            VARCHAR(64)    NULL,
    tree_code                  VARCHAR(30)    NOT NULL,
    tree_structure_code        VARCHAR(30)    NOT NULL,
    location_segment           VARCHAR(30)    NULL,
    parent_location_segment    VARCHAR(30)    NULL,
    depth                      INT            NULL,
    _row_hash                  VARBINARY(32)  NULL,
    _silver_loaded_at          DATETIME2(6)   NOT NULL,
    _is_deleted                BIT            NOT NULL,
    _run_id                    VARCHAR(100)   NULL
);
