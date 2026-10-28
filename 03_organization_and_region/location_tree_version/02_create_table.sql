CREATE TABLE silver.location_tree_version (
    tree_version_id            VARCHAR(64)    NOT NULL,
    status                     VARCHAR(30)    NULL,
    effective_start_date       DATE           NULL,
    effective_end_date         DATE           NULL,
    _row_hash                  VARBINARY(32)  NULL,
    _silver_loaded_at          DATETIME2(6)   NOT NULL,
    _is_deleted                BIT            NOT NULL,
    _run_id                    VARCHAR(100)   NULL
);
