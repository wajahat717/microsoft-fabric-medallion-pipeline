CREATE OR ALTER PROCEDURE silver.dq_location_tree_version @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    -- key is unique (uses every key column)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_tree_version', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT tree_version_id FROM silver.location_tree_version
          GROUP BY tree_version_id HAVING COUNT(*) > 1) x;

    -- key not null
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_tree_version', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.location_tree_version
    WHERE tree_version_id IS NULL;

    -- main column filled (warning only)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_tree_version', 'status not null', 'WARN', COUNT(*), @now
    FROM silver.location_tree_version
    WHERE status IS NULL AND _is_deleted = 0;

    -- Silver active rows = Bronze distinct keys (after filter)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_tree_version', 'row count matches bronze', 'ERROR',
           ABS(
             (SELECT COUNT(*) FROM silver.location_tree_version WHERE _is_deleted = 0)
           - (SELECT COUNT(*) FROM (
                SELECT DISTINCT b.TreeVersionId AS k1
                FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreeversion] b
                WHERE b.TreeCode = 'Location Tree'
                      AND b.TreeStructureCode = 'GL_ACCT_FLEX'
                      AND b.Status = 'ACTIVE'
                      AND CAST(GETDATE() AS DATE) BETWEEN b.EffectiveStartDate AND COALESCE(b.EffectiveEndDate, '9999-12-31')
             ) d)
           ), @now;

    -- extra test
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_tree_version', 'exactly one active version', 'ERROR',
           ((SELECT ABS(COUNT(*) - 1) FROM silver.location_tree_version WHERE _is_deleted = 0)), @now;
END;
