CREATE OR ALTER PROCEDURE silver.load_location_tree_node @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    DROP TABLE IF EXISTS silver.stg_location_tree_node;

    CREATE TABLE silver.stg_location_tree_node AS
    SELECT
        x.tree_node_id, x.tree_version_id, x.tree_code, x.tree_structure_code, x.location_segment, x.parent_location_segment, x.depth,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.tree_version_id, '|', x.location_segment, '|', x.parent_location_segment, '|', x.depth, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            CAST(b.TreeNodeId AS VARCHAR(64))                              AS tree_node_id,
            CAST(b.TreeVersionId AS VARCHAR(64))                           AS tree_version_id,
            CAST(b.TreeCode AS VARCHAR(30))                                AS tree_code,
            CAST(b.TreeStructureCode AS VARCHAR(30))                       AS tree_structure_code,
            CAST(b.Pk1StartValue AS VARCHAR(30))                           AS location_segment,
            CAST(b.ParentPk1Value AS VARCHAR(30))                          AS parent_location_segment,
            CAST(b.Depth AS INT)                                           AS depth,
            ROW_NUMBER() OVER (
                PARTITION BY b.TreeNodeId, b.TreeCode, b.TreeStructureCode
                ORDER BY b._LoadDTS DESC
            ) AS rn
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
    ) x
    WHERE x.rn = 1;

    UPDATE t
    SET
        t.tree_version_id          = s.tree_version_id,
        t.location_segment         = s.location_segment,
        t.parent_location_segment  = s.parent_location_segment,
        t.depth                    = s.depth,
        t._row_hash               = s._row_hash,
        t._silver_loaded_at       = @now,
        t._is_deleted             = 0,
        t._run_id                 = @run_id
    FROM silver.location_tree_node t
    INNER JOIN silver.stg_location_tree_node s
        ON t.tree_node_id = s.tree_node_id AND t.tree_code = s.tree_code AND t.tree_structure_code = s.tree_structure_code
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    INSERT INTO silver.location_tree_node
        (tree_node_id, tree_version_id, tree_code, tree_structure_code, location_segment, parent_location_segment, depth,
         _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.tree_node_id, s.tree_version_id, s.tree_code, s.tree_structure_code, s.location_segment, s.parent_location_segment, s.depth,
           s._row_hash, @now, 0, @run_id
    FROM silver.stg_location_tree_node s
    WHERE NOT EXISTS (SELECT 1 FROM silver.location_tree_node t
                      WHERE t.tree_node_id = s.tree_node_id AND t.tree_code = s.tree_code AND t.tree_structure_code = s.tree_structure_code);

    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.location_tree_node t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_location_tree_node s
                      WHERE s.tree_node_id = t.tree_node_id AND s.tree_code = t.tree_code AND s.tree_structure_code = t.tree_structure_code);

    DROP TABLE IF EXISTS silver.stg_location_tree_node;
END;
