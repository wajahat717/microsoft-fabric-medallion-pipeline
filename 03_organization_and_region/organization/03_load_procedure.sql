CREATE OR ALTER PROCEDURE silver.load_organization @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    DROP TABLE IF EXISTS silver.stg_organization;

    CREATE TABLE silver.stg_organization AS
    SELECT
        x.organization_id, x.organization_name, x.language, x.effective_start_date, x.effective_end_date, x.last_update_date,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.organization_name, '|', x.language, '|', x.effective_start_date, '|', x.effective_end_date, '|', x.last_update_date, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            b.OrganizationId                                               AS organization_id,
            CAST(b.OrganizationUnitTranslationPEOName AS VARCHAR(240))     AS organization_name,
            CAST(b.OrganizationUnitTranslationPEOLanguage AS VARCHAR(4))   AS language,
            CAST(b.EffectiveStartDate AS DATE)                             AS effective_start_date,
            CAST(b.EffectiveEndDate AS DATE)                               AS effective_end_date,
            b.OrganizationUnitPEOLastUpdateDate                            AS last_update_date,
            ROW_NUMBER() OVER (
                PARTITION BY b.OrganizationId
                ORDER BY b.OrganizationUnitPEOLastUpdateDate DESC, b._LoadDTS DESC
            ) AS rn
        FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_hcm_organizationam_organizationunit] b
        WHERE b.OrganizationUnitTranslationPEOLanguage = 'US'
              AND CAST(GETDATE() AS DATE) BETWEEN COALESCE(b.EffectiveStartDate, '1900-01-01') AND COALESCE(b.EffectiveEndDate, '9999-12-31')
    ) x
    WHERE x.rn = 1;

    UPDATE t
    SET
        t.organization_name        = s.organization_name,
        t.language                 = s.language,
        t.effective_start_date     = s.effective_start_date,
        t.effective_end_date       = s.effective_end_date,
        t.last_update_date         = s.last_update_date,
        t._row_hash               = s._row_hash,
        t._silver_loaded_at       = @now,
        t._is_deleted             = 0,
        t._run_id                 = @run_id
    FROM silver.organization t
    INNER JOIN silver.stg_organization s
        ON t.organization_id = s.organization_id
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    INSERT INTO silver.organization
        (organization_id, organization_name, language, effective_start_date, effective_end_date, last_update_date,
         _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.organization_id, s.organization_name, s.language, s.effective_start_date, s.effective_end_date, s.last_update_date,
           s._row_hash, @now, 0, @run_id
    FROM silver.stg_organization s
    WHERE NOT EXISTS (SELECT 1 FROM silver.organization t
                      WHERE t.organization_id = s.organization_id);

    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.organization t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_organization s
                      WHERE s.organization_id = t.organization_id);

    DROP TABLE IF EXISTS silver.stg_organization;
END;
