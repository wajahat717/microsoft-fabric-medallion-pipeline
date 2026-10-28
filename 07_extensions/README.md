# Next phase: production features

Folders `01_setup` to `06_gold_layer` are the build I ran and tested. This folder holds the **next phase**: the features a production Fabric warehouse needs once the first build is approved.

> **Status: designed and written, not yet run in production.** Each part follows the same patterns as the tested build, and each has its own test script.

| Folder | What it adds | Why it matters |
|---|---|---|
| [`01_incremental_load`](01_incremental_load/) | Watermark table, incremental `cost_distribution` load with a safety overlap, weekly delete check, test script | Loads only changed rows instead of millions every day; deletes are still caught once a week |
| [`02_scd_type2_history`](02_scd_type2_history/) | `dim_organization_history` with valid-from / valid-to, a cost fact that joins the version valid on the GL date, tests | When an organization moves region, old cost still reports under the old region |
| [`03_monitoring`](03_monitoring/) | `ops.pipeline_run_log`, logging procedures, views for run history, DQ trend and data freshness | Anyone can see what ran, how long it took, and whether the data is fresh, without opening the pipeline |
| [`04_gold_tables_for_direct_lake`](04_gold_tables_for_direct_lake/) | Procedure that rebuilds Gold views as tables, checks Gold = Silver, then swaps them in | Power BI Direct Lake needs tables; reports never see a half-built table |
| [`05_pyspark_notebooks`](05_pyspark_notebooks/) | Config-driven Bronze → Silver loader with Delta `MERGE` (including soft delete), DQ gate, Bronze profiling notebook | The same pattern as the T-SQL procedures, written once; a new table is one config entry |
| [`06_pipeline_definition`](06_pipeline_definition/) | `pl_daily_medallion_load` JSON: parallel ForEach for reference tables, retries, DQ gate, Gold refresh, logging on success and failure | The full daily orchestration in one place |
| [`07_ci_cd`](07_ci_cd/) | Git integration, pull request checks, Dev → Test → Prod deployment pipeline, rollback | Safe releases with no manual edits in production |

## Order to run (in a practice warehouse)

1. `03_monitoring/01_pipeline_run_log.sql` and `02_monitoring_views.sql`
2. `01_incremental_load/01` → `02` → `04` (test), and `03` weekly
3. `02_scd_type2_history/01` → `02`
4. `04_gold_tables_for_direct_lake/01`, then `EXEC gold.refresh_gold_tables @run_id = 'test-1'`
5. Import `06_pipeline_definition/pl_daily_medallion_load.json` as a pipeline, replace the warehouse placeholders, and run it once by hand
6. Notebooks: import into a Fabric workspace attached to the Bronze lakehouse. The notebook writes Silver tables to the lakehouse (Delta), as an alternative to the warehouse procedures.
