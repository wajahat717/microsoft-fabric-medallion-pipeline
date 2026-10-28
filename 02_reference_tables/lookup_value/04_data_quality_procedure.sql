CREATE OR ALTER PROCEDURE silver.dq_lookup_value @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    -- key is unique (uses every key column)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.lookup_value', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT lookup_type, lookup_code, set_id, view_application_id FROM silver.lookup_value
          GROUP BY lookup_type, lookup_code, set_id, view_application_id HAVING COUNT(*) > 1) x;

    -- key not null
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.lookup_value', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.lookup_value
    WHERE lookup_type IS NULL OR lookup_code IS NULL OR set_id IS NULL OR view_application_id IS NULL;

    -- main column filled (warning only)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.lookup_value', 'meaning not null', 'WARN', COUNT(*), @now
    FROM silver.lookup_value
    WHERE meaning IS NULL AND _is_deleted = 0;

    -- Silver active rows = Bronze distinct keys (after filter)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.lookup_value', 'row count matches bronze', 'ERROR',
           ABS(
             (SELECT COUNT(*) FROM silver.lookup_value WHERE _is_deleted = 0)
           - (SELECT COUNT(*) FROM (SELECT DISTINCT b.LookupType, b.LookupCode, b.SetId, b.ViewApplicationId
                                    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_lookupvaluestl] b WHERE b.Language = 'US' AND b.LookupType = 'PJF_REVENUE_CATEGORY') d)
           ), @now;
END;
