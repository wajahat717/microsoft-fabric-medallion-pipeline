CREATE OR ALTER PROCEDURE silver.dq_party_site @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    -- key is unique (uses every key column)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.party_site', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT party_site_id FROM silver.party_site
          GROUP BY party_site_id HAVING COUNT(*) > 1) x;

    -- key not null
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.party_site', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.party_site
    WHERE party_site_id IS NULL;

    -- main column filled (warning only)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.party_site', 'party_site_name not null', 'WARN', COUNT(*), @now
    FROM silver.party_site
    WHERE party_site_name IS NULL AND _is_deleted = 0;

    -- Silver active rows = Bronze distinct keys (after filter)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.party_site', 'row count matches bronze', 'ERROR',
           ABS(
             (SELECT COUNT(*) FROM silver.party_site WHERE _is_deleted = 0)
           - (SELECT COUNT(*) FROM (SELECT DISTINCT b.PartySiteId
                                    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_hzbiccextractam_partysite] b) d)
           ), @now;
END;
