CREATE TABLE silver.organization (
    organization_id            BIGINT         NOT NULL,
    organization_name          VARCHAR(240)   NULL,
    language                   VARCHAR(4)     NULL,
    effective_start_date       DATE           NULL,
    effective_end_date         DATE           NULL,
    last_update_date           DATETIME2(6)   NULL,
    _row_hash                  VARBINARY(32)  NULL,
    _silver_loaded_at          DATETIME2(6)   NOT NULL,
    _is_deleted                BIT            NOT NULL,
    _run_id                    VARCHAR(100)   NULL
);
