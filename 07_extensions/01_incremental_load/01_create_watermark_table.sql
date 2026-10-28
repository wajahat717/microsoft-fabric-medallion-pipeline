/* Incremental loading: one row per Silver table that loads incrementally.
   last_value = the newest source LastUpdateDate already loaded into Silver.

   Seed it from Silver once, after the first full load, so the first
   incremental run starts where the full load finished. */

CREATE TABLE ops.load_watermark (
    table_name   VARCHAR(200)  NOT NULL,
    last_value   DATETIME2(6)  NULL,
    updated_at   DATETIME2(6)  NULL,
    run_id       VARCHAR(100)  NULL
);

INSERT INTO ops.load_watermark (table_name, last_value, updated_at, run_id)
SELECT 'silver.cost_distribution', MAX(last_update_date), SYSUTCDATETIME(), 'seed-from-full-load'
FROM silver.cost_distribution;

INSERT INTO ops.load_watermark (table_name, last_value, updated_at, run_id)
SELECT 'silver.expenditure_item', MAX(last_update_date), SYSUTCDATETIME(), 'seed-from-full-load'
FROM silver.expenditure_item;

SELECT * FROM ops.load_watermark;
