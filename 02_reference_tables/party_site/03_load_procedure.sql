CREATE OR ALTER PROCEDURE silver.load_party_site @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    DROP TABLE IF EXISTS silver.stg_party_site;

    CREATE TABLE silver.stg_party_site AS
    SELECT
        x.party_site_id, x.party_site_name,
        x.source_last_update_date,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.party_site_name, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            b.PartySiteId                                                  AS party_site_id,
            CAST(b.PartySiteName AS VARCHAR(240))                          AS party_site_name,
            b.LastUpdateDate                                               AS source_last_update_date,
            ROW_NUMBER() OVER (
                PARTITION BY b.PartySiteId
                ORDER BY b.LastUpdateDate DESC, b._LoadDTS DESC
            ) AS rn
        FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_hzbiccextractam_partysite] b
        -- no filter for this table
    ) x
    WHERE x.rn = 1;

    UPDATE t
    SET
        t.party_site_name          = s.party_site_name,
        t.source_last_update_date  = s.source_last_update_date,
        t._row_hash                = s._row_hash,
        t._silver_loaded_at        = @now,
        t._is_deleted              = 0,
        t._run_id                  = @run_id
    FROM silver.party_site t
    INNER JOIN silver.stg_party_site s
        ON t.party_site_id = s.party_site_id
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    INSERT INTO silver.party_site
        (party_site_id, party_site_name,
         source_last_update_date, _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.party_site_id, s.party_site_name,
           s.source_last_update_date, s._row_hash, @now, 0, @run_id
    FROM silver.stg_party_site s
    WHERE NOT EXISTS (SELECT 1 FROM silver.party_site t
                      WHERE t.party_site_id = s.party_site_id);

    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.party_site t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_party_site s
                      WHERE s.party_site_id = t.party_site_id);

    DROP TABLE IF EXISTS silver.stg_party_site;
END;
