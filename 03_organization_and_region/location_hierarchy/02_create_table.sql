CREATE TABLE silver.location_hierarchy (
    location_segment           VARCHAR(30)    NOT NULL,
    location_name              VARCHAR(240)   NULL,
    location_depth             INT            NULL,
    region_segment             VARCHAR(30)    NULL,
    region_name                VARCHAR(240)   NULL,
    region_depth               INT            NULL,
    _silver_loaded_at          DATETIME2(6)   NOT NULL,
    _run_id                    VARCHAR(100)   NULL
);
