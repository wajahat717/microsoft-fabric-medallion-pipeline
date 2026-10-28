CREATE OR ALTER PROCEDURE silver.dq_organization @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    -- key is unique (uses every key column)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.organization', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT organization_id FROM silver.organization
          GROUP BY organization_id HAVING COUNT(*) > 1) x;

    -- key not null
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.organization', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.organization
    WHERE organization_id IS NULL;

    -- main column filled (warning only)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.organization', 'organization_name not null', 'WARN', COUNT(*), @now
    FROM silver.organization
    WHERE organization_name IS NULL AND _is_deleted = 0;

    -- Silver active rows = Bronze distinct keys (after filter)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.organization', 'row count matches bronze', 'ERROR',
           ABS(
             (SELECT COUNT(*) FROM silver.organization WHERE _is_deleted = 0)
           - (SELECT COUNT(*) FROM (
                SELECT DISTINCT b.OrganizationId AS k1
                FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_hcm_organizationam_organizationunit] b
                WHERE b.OrganizationUnitTranslationPEOLanguage = 'US'
                      AND CAST(GETDATE() AS DATE) BETWEEN COALESCE(b.EffectiveStartDate, '1900-01-01') AND COALESCE(b.EffectiveEndDate, '9999-12-31')
             ) d)
           ), @now;
END;
