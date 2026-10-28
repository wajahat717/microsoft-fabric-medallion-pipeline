/* Gold as tables instead of views.
   Power BI Direct Lake reads Delta tables directly; a view makes it fall back
   to slower DirectQuery. This procedure rebuilds each Gold table from its view
   into a _new table, checks it, and only then swaps it in, so reports never
   see a half-built table. */

CREATE OR ALTER PROCEDURE gold.refresh_gold_tables @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @silver_cost DECIMAL(38,4);
    DECLARE @gold_cost   DECIMAL(38,4);

    /* 1. Build new copies. */
    DROP TABLE IF EXISTS gold.t_fact_project_cost_new;
    CREATE TABLE gold.t_fact_project_cost_new AS SELECT * FROM gold.fact_project_cost;

    DROP TABLE IF EXISTS gold.t_dim_organization_new;
    CREATE TABLE gold.t_dim_organization_new AS SELECT * FROM gold.dim_organization;

    DROP TABLE IF EXISTS gold.t_dim_expenditure_type_new;
    CREATE TABLE gold.t_dim_expenditure_type_new AS SELECT * FROM gold.dim_expenditure_type;

    /* 2. Check: Gold money must equal Silver money before swapping. */
    SELECT @silver_cost = SUM(burdened_cost_proj_curr) FROM silver.cost_distribution WHERE _is_deleted = 0;
    SELECT @gold_cost   = SUM(burdened_cost) FROM gold.t_fact_project_cost_new;

    INSERT INTO ops.dq_result
    SELECT @run_id, 'gold.t_fact_project_cost', 'gold cost equals silver cost', 'ERROR',
           CASE WHEN ABS(COALESCE(@silver_cost, 0) - COALESCE(@gold_cost, 0)) < 0.01 THEN 0 ELSE 1 END,
           SYSUTCDATETIME();

    IF ABS(COALESCE(@silver_cost, 0) - COALESCE(@gold_cost, 0)) >= 0.01
    BEGIN
        THROW 50001, 'Gold refresh stopped: Gold cost does not equal Silver cost. Old tables kept.', 1;
    END;

    /* 3. Swap: drop the old table, rename the new one. */
    DROP TABLE IF EXISTS gold.t_fact_project_cost;
    EXEC sp_rename 'gold.t_fact_project_cost_new', 't_fact_project_cost';

    DROP TABLE IF EXISTS gold.t_dim_organization;
    EXEC sp_rename 'gold.t_dim_organization_new', 't_dim_organization';

    DROP TABLE IF EXISTS gold.t_dim_expenditure_type;
    EXEC sp_rename 'gold.t_dim_expenditure_type_new', 't_dim_expenditure_type';
END;
GO
