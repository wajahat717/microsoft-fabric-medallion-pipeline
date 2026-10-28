/* Views for a small monitoring report in Power BI (or a SQL query each morning). */

/* 1. One row per pipeline run: start, end, duration, result. */
CREATE OR ALTER VIEW ops.v_pipeline_runs AS
SELECT
    run_id,
    pipeline_name,
    MIN(logged_at)                                          AS started_at,
    MAX(logged_at)                                          AS finished_at,
    DATEDIFF(SECOND, MIN(logged_at), MAX(logged_at)) / 60.0 AS duration_minutes,
    SUM(COALESCE(rows_changed, 0))                          AS rows_changed,
    CASE WHEN SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) > 0
         THEN 'Failed' ELSE 'Succeeded' END                 AS run_status
FROM ops.pipeline_run_log
GROUP BY run_id, pipeline_name;
GO

/* 2. Data quality trend: failed rows per table and test, by day.
      A test that slowly gets worse shows up here before it breaks the gate. */
CREATE OR ALTER VIEW ops.v_dq_trend AS
SELECT
    CAST(checked_at AS DATE) AS check_date,
    table_name,
    test_name,
    severity,
    MAX(failed_rows)         AS failed_rows
FROM ops.dq_result
GROUP BY CAST(checked_at AS DATE), table_name, test_name, severity;
GO

/* 3. Freshness: how old is the newest source row in each incremental table.
      Over 26 hours on a daily load means the extract or the pipeline stopped. */
CREATE OR ALTER VIEW ops.v_data_freshness AS
SELECT
    table_name,
    last_value                                         AS newest_source_row,
    DATEDIFF(HOUR, last_value, SYSUTCDATETIME())       AS hours_old,
    CASE WHEN DATEDIFF(HOUR, last_value, SYSUTCDATETIME()) > 26
         THEN 'Stale' ELSE 'Fresh' END                 AS freshness_status
FROM ops.load_watermark;
GO

/* Morning check: anything to look at? */
SELECT * FROM ops.v_pipeline_runs WHERE started_at >= DATEADD(DAY, -1, SYSUTCDATETIME()) ORDER BY started_at DESC;
SELECT * FROM ops.v_dq_trend WHERE check_date = CAST(SYSUTCDATETIME() AS DATE) AND failed_rows > 0;
SELECT * FROM ops.v_data_freshness WHERE freshness_status = 'Stale';
