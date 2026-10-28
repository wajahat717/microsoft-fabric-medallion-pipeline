/* Monitoring: every pipeline step writes a start and an end row here,
   so anyone can see what ran, how long it took, how many rows changed,
   and where a failure happened, without opening the pipeline itself. */

CREATE TABLE ops.pipeline_run_log (
    run_id         VARCHAR(100)  NOT NULL,
    pipeline_name  VARCHAR(200)  NOT NULL,
    step_name      VARCHAR(200)  NOT NULL,
    status         VARCHAR(20)   NOT NULL,
    rows_changed   BIGINT        NULL,
    message        VARCHAR(4000) NULL,
    logged_at      DATETIME2(6)  NOT NULL
);
GO

CREATE OR ALTER PROCEDURE ops.log_step
    @run_id        VARCHAR(100),
    @pipeline_name VARCHAR(200),
    @step_name     VARCHAR(200),
    @status        VARCHAR(20),
    @rows_changed  BIGINT = NULL,
    @message       VARCHAR(4000) = NULL
AS
BEGIN
    INSERT INTO ops.pipeline_run_log
        (run_id, pipeline_name, step_name, status, rows_changed, message, logged_at)
    VALUES
        (@run_id, @pipeline_name, @step_name, @status, @rows_changed, @message, SYSUTCDATETIME());
END;
GO

/* Rows changed by a load = rows whose _run_id is this run. Call after each load. */
CREATE OR ALTER PROCEDURE ops.log_rows_changed
    @run_id VARCHAR(100), @pipeline_name VARCHAR(200), @table_name VARCHAR(200)
AS
BEGIN
    DECLARE @sql NVARCHAR(400) =
        N'SELECT @n = COUNT(*) FROM ' + @table_name + N' WHERE _run_id = @r';
    DECLARE @n BIGINT;
    EXEC sp_executesql @sql, N'@n BIGINT OUTPUT, @r VARCHAR(100)', @n = @n OUTPUT, @r = @run_id;
    EXEC ops.log_step @run_id, @pipeline_name, @table_name, 'Succeeded', @n, NULL;
END;
GO
