/* Run once in the Fabric Warehouse before building any Silver table. */

CREATE SCHEMA silver;
GO
CREATE SCHEMA ops;
GO
CREATE SCHEMA ref;
GO

/* Every data quality procedure writes one row per test into this table.
   The pipeline reads it after each load and stops if any ERROR test failed. */
CREATE TABLE ops.dq_result (
    run_id       VARCHAR(100)  NOT NULL,
    table_name   VARCHAR(200)  NOT NULL,
    test_name    VARCHAR(200)  NOT NULL,
    severity     VARCHAR(10)   NOT NULL,
    failed_rows  BIGINT        NOT NULL,
    checked_at   DATETIME2(6)  NOT NULL
);
