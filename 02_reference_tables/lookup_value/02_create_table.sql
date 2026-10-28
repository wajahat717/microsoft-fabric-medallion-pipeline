CREATE TABLE silver.lookup_value (
    lookup_type                VARCHAR(30)    NOT NULL,
    lookup_code                VARCHAR(30)    NOT NULL,
    set_id                     BIGINT         NOT NULL,
    view_application_id        BIGINT         NOT NULL,
    meaning                    VARCHAR(80)    NULL,
    source_last_update_date    DATETIME2(6)   NULL,
    _row_hash                  VARBINARY(32)  NULL,
    _silver_loaded_at          DATETIME2(6)   NOT NULL,
    _is_deleted                BIT            NOT NULL,
    _run_id                    VARCHAR(100)   NULL
);
