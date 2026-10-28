CREATE OR ALTER PROCEDURE silver.dq_location_value @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    -- key is unique (uses every key column)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_value', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT value_id FROM silver.location_value
          GROUP BY value_id HAVING COUNT(*) > 1) x;

    -- key not null
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_value', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.location_value
    WHERE value_id IS NULL;

    -- main column filled (warning only)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_value', 'location_name not null', 'WARN', COUNT(*), @now
    FROM silver.location_value
    WHERE location_name IS NULL AND _is_deleted = 0;

    -- Silver active rows = Bronze distinct keys (after filter)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.location_value', 'row count matches bronze', 'ERROR',
           ABS(
             (SELECT COUNT(*) FROM silver.location_value WHERE _is_deleted = 0)
           - (SELECT COUNT(*) FROM (
                SELECT DISTINCT b.ValueId AS k1
                FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_valuesetvalues] b
                WHERE b.AttributeCategory = 'Location Tree'
                      AND b.Language = 'US'
             ) d)
           ), @now;
END;
