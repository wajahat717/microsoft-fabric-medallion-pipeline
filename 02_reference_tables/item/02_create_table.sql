CREATE TABLE silver.item (
    inventory_item_id          BIGINT         NOT NULL,
    organization_id            BIGINT         NOT NULL,
    item_number                VARCHAR(300)   NULL,
    source_last_update_date    DATETIME2(6)   NULL,
    _row_hash                  VARBINARY(32)  NULL,
    _silver_loaded_at          DATETIME2(6)   NOT NULL,
    _is_deleted                BIT            NOT NULL,
    _run_id                    VARCHAR(100)   NULL
);
