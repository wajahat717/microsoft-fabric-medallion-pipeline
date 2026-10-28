# Microsoft Fabric Medallion Pipeline (Oracle Fusion → Bronze → Silver)

A Microsoft Fabric data warehouse build that turns raw Oracle Fusion Cloud extracts into clean, tested **Silver** tables, ready for a Gold reporting layer and Power BI.

Built with **T-SQL stored procedures** in a Fabric Warehouse and run by a **Fabric Data Pipeline** with an automatic **data quality gate**.

---

## What problem this solves

Oracle Fusion data lands in Fabric as raw **Bronze** tables (BICC extracts). Bronze data is hard to use:
- every column is text, with long system names like `PjcExpItemsAllExpenditureItemId`
- the same record can appear more than once (re-extracts)
- deleted records in the source are not removed

This project builds **Silver** tables that are typed, de-duplicated, renamed to business names, and checked automatically every run.

## Architecture

```
Oracle Fusion Cloud
        │  (BICC extract connector)
        ▼
 BRONZE  (Lakehouse)   raw copies, all text, duplicates possible
        │  T-SQL load procedures (this repo)
        ▼
 SILVER  (Warehouse)   typed, one row per key, business column names,
        │              change tracking + soft delete, DQ tested
        ▼
 GOLD    (Warehouse)   star schema for reporting
        │
        ▼
   Power BI
```

## The load pattern (same for every table)

Each Silver table has two stored procedures: `silver.load_<table>` and `silver.dq_<table>`.

The load procedure runs four steps:

| Step | What it does |
|---|---|
| 1. Stage | Copy Bronze into a staging table, cast types, keep only the newest row per key (`ROW_NUMBER`), and build a row hash (`HASHBYTES SHA2_256`) |
| 2. Update | Update Silver rows whose hash changed |
| 3. Insert | Insert keys that are new |
| 4. Soft delete | Mark rows as `_is_deleted = 1` when the key is no longer in Bronze |

Every Silver table also carries tracking columns: `_row_hash`, `_silver_loaded_at`, `_is_deleted`, `_run_id`.

**The load is idempotent:** running it twice in a row changes nothing on the second run. Each table's `05_run_twice_and_test.sql` proves this.

## Data quality checks

Each `dq_<table>` procedure writes its results to `ops.dq_result`:

| Test | Severity |
|---|---|
| Key is unique | ERROR |
| Key is not null | ERROR |
| Silver active row count = Bronze distinct keys | ERROR |
| Main business column is filled | WARN |
| Table-specific tests (for example, every cost line has a parent expenditure item) | ERROR / WARN |

The pipeline runs a gate query after the loads (`01_setup/02_pipeline_dq_gate_check.sql`). If any ERROR test fails, the pipeline stops with a Fail activity, so bad data never reaches reporting.

## Pipeline

```
Load table ──► Run DQ tests ──► (next tables …) ──► DQ check (Lookup)
                                                        │
                                              error_count > 0 ?
                                              ├── yes ──► Fail: DQ gate failed
                                              └── no  ──► success
```

`run_id` is passed from `@pipeline().RunId`, so every DQ result can be traced back to the pipeline run that produced it. Tested by seeding a duplicate row on purpose: the pipeline failed as expected, then passed again after cleanup.

## Folder guide

| Folder | Contents |
|---|---|
| `01_setup` | Schemas, the `ops.dq_result` table, the pipeline gate query |
| `02_reference_tables` | 10 reference tables: supplier, supplier site, party, party site, item, lookup values, expenditure category, transaction source, document entry, project role |
| `03_organization_and_region` | Organizations mapped to regions through a GL location tree (tree versions, tree nodes, value sets, mapping sets) and a flattened `location_hierarchy` |
| `04_cost_fact_tables` | Two large fact tables: `expenditure_item` (about 4 million rows) and `cost_distribution`, with derived columns |
| `05_validation` | Month-by-month reconciliation of Bronze vs Silver (row counts and amounts), and a sample query for manual spot checks |
| `06_gold_layer` | Star schema for Power BI: `dim_date`, `dim_organization` (with region), `dim_expenditure_type`, `dim_transaction_source`, `dim_project_role`, and `fact_project_cost`, plus Gold checks |

## Gold layer (star schema)

```
            dim_date
               │
dim_organization ─┼─ dim_expenditure_type
               │
       fact_project_cost  (one row per cost distribution line)
               │
  dim_transaction_source · dim_project_role
```

- Every dimension has an **Unknown (-1)** row, so no cost disappears when a reference is missing.
- `dim_date` is generated in T-SQL without recursion (Fabric Warehouse does not support recursive CTEs).
- `04_gold_checks.sql` proves Gold cost = Silver cost, the fact grain is unique, and every fact key finds its dimension.

## Next phase → [`07_extensions/`](07_extensions/)

Production features designed and written for the next phase (not yet run in production): **incremental loading** with watermarks, **SCD Type 2** history, **monitoring** (run log, DQ trend, freshness), **Gold tables for Direct Lake**, **PySpark notebooks** with Delta MERGE, the full **pipeline JSON**, and a **CI/CD** plan (Git + Dev → Test → Prod).

The Power BI report built on this model is in my [Power BI repo](https://github.com/wajahat717/power-bi-dashboard-troubleshooting/tree/main/project-cost-dashboard).

Inside each table folder, run the files in number order:

```
01_check_bronze_duplicates.sql   check the source key first
02_create_table.sql              create the Silver table
03_load_procedure.sql            stage → update → insert → soft delete
04_data_quality_procedure.sql    write test results to ops.dq_result
05_run_twice_and_test.sql        run load + DQ twice, prove run 2 changes nothing
```

Each folder also has `00_check_bronze_column_names.sql`, which checks that every Bronze column the scripts use really exists before anything is built.

## Things I learned building this

- In Fabric Warehouse, `HASHBYTES` output must be wrapped in `CAST(... AS VARBINARY(32))` or the insert fails.
- Some Oracle tree IDs look like numbers in the mapping documents but are stored as text. Profile the data before choosing column types.
- Translated Oracle tables (`_TL`) need a language filter (`'US'`), and effective-dated tables need a "current row today" filter, or keys duplicate.
- Reconciling month by month (not just grand totals) is what finds real gaps, for example a source history gap in one table that grand totals would hide.
- Very large Bronze tables can hit Fabric capacity limits. Waiting and re-running the same step works because the loads are idempotent.

## Tools

Microsoft Fabric (Lakehouse, Warehouse, Data Pipelines, Notebooks, Deployment pipelines) · T-SQL · PySpark · Delta Lake · Git · Oracle Fusion Cloud (PPM, Procurement, TCA, HCM, Subledger Accounting)

> All names, IDs and connection details are generic. No client data is included.
