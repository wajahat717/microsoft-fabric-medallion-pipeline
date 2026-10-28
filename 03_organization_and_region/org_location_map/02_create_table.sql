CREATE TABLE silver.org_location_map (
    organization_id            BIGINT         NOT NULL,
    location_segment           VARCHAR(30)    NULL,
    mapping_set_code           VARCHAR(30)    NULL,
    enabled_flag               VARCHAR(1)     NULL,
    effective_start_date       DATE           NULL,
    effective_end_date         DATE           NULL,
    _row_hash                  VARBINARY(32)  NULL,
    _silver_loaded_at          DATETIME2(6)   NOT NULL,
    _is_deleted                BIT            NOT NULL,
    _run_id                    VARCHAR(100)   NULL
);
