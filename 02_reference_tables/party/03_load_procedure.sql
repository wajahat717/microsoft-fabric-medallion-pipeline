CREATE OR ALTER PROCEDURE silver.load_party @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    DROP TABLE IF EXISTS silver.stg_party;

    CREATE TABLE silver.stg_party AS
    SELECT
        x.party_id, x.party_name, x.party_number, x.party_type,
        x.source_last_update_date,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.party_name, '|', x.party_number, '|', x.party_type, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            b.PartyId                                                      AS party_id,
            CAST(b.PartyName AS VARCHAR(360))                              AS party_name,
            CAST(b.PartyNumber AS VARCHAR(30))                             AS party_number,
            CAST(b.PartyType AS VARCHAR(30))                               AS party_type,
            b.LastUpdateDate                                               AS source_last_update_date,
            ROW_NUMBER() OVER (
                PARTITION BY b.PartyId
                ORDER BY b.LastUpdateDate DESC, b._LoadDTS DESC
            ) AS rn
        FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_hzbiccextractam_party] b
        -- no filter for this table
    ) x
    WHERE x.rn = 1;

    UPDATE t
    SET
        t.party_name               = s.party_name,
        t.party_number             = s.party_number,
        t.party_type               = s.party_type,
        t.source_last_update_date  = s.source_last_update_date,
        t._row_hash                = s._row_hash,
        t._silver_loaded_at        = @now,
        t._is_deleted              = 0,
        t._run_id                  = @run_id
    FROM silver.party t
    INNER JOIN silver.stg_party s
        ON t.party_id = s.party_id
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    INSERT INTO silver.party
        (party_id, party_name, party_number, party_type,
         source_last_update_date, _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.party_id, s.party_name, s.party_number, s.party_type,
           s.source_last_update_date, s._row_hash, @now, 0, @run_id
    FROM silver.stg_party s
    WHERE NOT EXISTS (SELECT 1 FROM silver.party t
                      WHERE t.party_id = s.party_id);

    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.party t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_party s
                      WHERE s.party_id = t.party_id);

    DROP TABLE IF EXISTS silver.stg_party;
END;
