CREATE OR ALTER PROCEDURE silver.dq_location_tree_node @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    -- key is unique (uses every key column)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_tree_node', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT tree_node_id, tree_code, tree_structure_code FROM silver.location_tree_node
          GROUP BY tree_node_id, tree_code, tree_structure_code HAVING COUNT(*) > 1) x;

    -- key not null
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_tree_node', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.location_tree_node
    WHERE tree_node_id IS NULL OR tree_code IS NULL OR tree_structure_code IS NULL;

    -- main column filled (warning only)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_tree_node', 'location_segment not null', 'WARN', COUNT(*), @now
    FROM silver.location_tree_node
    WHERE location_segment IS NULL AND _is_deleted = 0;

    -- Silver active rows = Bronze distinct keys (after filter)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_tree_node', 'row count matches bronze', 'ERROR',
           ABS(
             (SELECT COUNT(*) FROM silver.location_tree_node WHERE _is_deleted = 0)
           - (SELECT COUNT(*) FROM (
                SELECT DISTINCT b.TreeNodeId AS k1, b.TreeCode AS k2, b.TreeStructureCode AS k3
                FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreenode] b
                WHERE b.TreeCode = 'Location Tree'
                      AND b.TreeStructureCode = 'GL_ACCT_FLEX'
                      AND b.TreeVersionId IN (
                          SELECT v.TreeVersionId
                          FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreeversion] v
                          WHERE v.TreeCode = 'Location Tree'
                            AND v.TreeStructureCode = 'GL_ACCT_FLEX'
                            AND v.Status = 'ACTIVE'
                            AND CAST(GETDATE() AS DATE) BETWEEN v.EffectiveStartDate AND COALESCE(v.EffectiveEndDate, '9999-12-31')
                      )
             ) d)
           ), @now;
END;
