CREATE OR ALTER PROCEDURE silver.load_project_role @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    DROP TABLE IF EXISTS silver.stg_project_role;

    CREATE TABLE silver.stg_project_role AS
    SELECT
        x.project_role_id, x.project_role_name,
        x.source_last_update_date,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.project_role_name, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            b.ProjectRoleTypeTranslationProjectRoleId                      AS project_role_id,
            CAST(b.ProjectRoleTypeTranslationProjectRoleName AS VARCHAR(240)) AS project_role_name,
            b.ProjectRoleTypeTranslationLastUpdateDate                     AS source_last_update_date,
            ROW_NUMBER() OVER (
                PARTITION BY b.ProjectRoleTypeTranslationProjectRoleId
                ORDER BY b.ProjectRoleTypeTranslationLastUpdateDate DESC, b._LoadDTS DESC
            ) AS rn
        FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_projectroletypetranslation] b
        WHERE b.ProjectRoleTypeTranslationLanguage = 'US'
    ) x
    WHERE x.rn = 1;

    UPDATE t
    SET
        t.project_role_name        = s.project_role_name,
        t.source_last_update_date  = s.source_last_update_date,
        t._row_hash                = s._row_hash,
        t._silver_loaded_at        = @now,
        t._is_deleted              = 0,
        t._run_id                  = @run_id
    FROM silver.project_role t
    INNER JOIN silver.stg_project_role s
        ON t.project_role_id = s.project_role_id
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    INSERT INTO silver.project_role
        (project_role_id, project_role_name,
         source_last_update_date, _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.project_role_id, s.project_role_name,
           s.source_last_update_date, s._row_hash, @now, 0, @run_id
    FROM silver.stg_project_role s
    WHERE NOT EXISTS (SELECT 1 FROM silver.project_role t
                      WHERE t.project_role_id = s.project_role_id);

    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.project_role t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_project_role s
                      WHERE s.project_role_id = t.project_role_id);

    DROP TABLE IF EXISTS silver.stg_project_role;
END;
