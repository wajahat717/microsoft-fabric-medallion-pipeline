CREATE TABLE silver.location_value (
    value_id                   BIGINT         NOT NULL,
    value_set_id               BIGINT         NULL,
    location_segment           VARCHAR(30)    NULL,
    location_name              VARCHAR(240)   NULL,
    attribute_category         VARCHAR(150)   NULL,
    language                   VARCHAR(4)     NULL,
    enabled_flag               VARCHAR(1)     NULL,
    _row_hash                  VARBINARY(32)  NULL,
    _silver_loaded_at          DATETIME2(6)   NOT NULL,
    _is_deleted                BIT            NOT NULL,
    _run_id                    VARCHAR(100)   NULL
);
