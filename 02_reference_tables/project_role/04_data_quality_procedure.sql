CREATE OR ALTER PROCEDURE silver.dq_project_role @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    -- key is unique (uses every key column)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.project_role', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT project_role_id FROM silver.project_role
          GROUP BY project_role_id HAVING COUNT(*) > 1) x;

    -- key not null
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.project_role', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.project_role
    WHERE project_role_id IS NULL;

    -- main column filled (warning only)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.project_role', 'project_role_name not null', 'WARN', COUNT(*), @now
    FROM silver.project_role
    WHERE project_role_name IS NULL AND _is_deleted = 0;

    -- Silver active rows = Bronze distinct keys (after filter)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.project_role', 'row count matches bronze', 'ERROR',
           ABS(
             (SELECT COUNT(*) FROM silver.project_role WHERE _is_deleted = 0)
           - (SELECT COUNT(*) FROM (SELECT DISTINCT b.ProjectRoleTypeTranslationProjectRoleId
                                    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_projectroletypetranslation] b WHERE b.ProjectRoleTypeTranslationLanguage = 'US') d)
           ), @now;
END;
