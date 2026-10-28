CREATE TABLE silver.expenditure_category (
    expenditure_category_id    BIGINT         NOT NULL,
    expenditure_category_name  VARCHAR(240)   NULL,
    source_last_update_date    DATETIME2(6)   NULL,
    _row_hash                  VARBINARY(32)  NULL,
    _silver_loaded_at          DATETIME2(6)   NOT NULL,
    _is_deleted                BIT            NOT NULL,
    _run_id                    VARCHAR(100)   NULL
);
