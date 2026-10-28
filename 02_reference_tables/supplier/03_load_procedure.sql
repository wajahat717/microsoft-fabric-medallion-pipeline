CREATE OR ALTER PROCEDURE silver.load_supplier @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    DROP TABLE IF EXISTS silver.stg_supplier;

    CREATE TABLE silver.stg_supplier AS
    SELECT
        x.vendor_id, x.party_id, x.supplier_number,
        x.source_last_update_date,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.party_id, '|', x.supplier_number, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            CAST(b.VendorId AS BIGINT)                                     AS vendor_id,
            CAST(b.PartyId AS BIGINT)                                      AS party_id,
            CAST(b.Segment1 AS VARCHAR(30))                                AS supplier_number,
            b.LastUpdateDate                                               AS source_last_update_date,
            ROW_NUMBER() OVER (
                PARTITION BY b.VendorId
                ORDER BY b.LastUpdateDate DESC, b._LoadDTS DESC
            ) AS rn
        FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prcextractam_pozbiccextractam_supplier] b
        -- no filter for this table
    ) x
    WHERE x.rn = 1;

    UPDATE t
    SET
        t.party_id                 = s.party_id,
        t.supplier_number          = s.supplier_number,
        t.source_last_update_date  = s.source_last_update_date,
        t._row_hash                = s._row_hash,
        t._silver_loaded_at        = @now,
        t._is_deleted              = 0,
        t._run_id                  = @run_id
    FROM silver.supplier t
    INNER JOIN silver.stg_supplier s
        ON t.vendor_id = s.vendor_id
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    INSERT INTO silver.supplier
        (vendor_id, party_id, supplier_number,
         source_last_update_date, _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.vendor_id, s.party_id, s.supplier_number,
           s.source_last_update_date, s._row_hash, @now, 0, @run_id
    FROM silver.stg_supplier s
    WHERE NOT EXISTS (SELECT 1 FROM silver.supplier t
                      WHERE t.vendor_id = s.vendor_id);

    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.supplier t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_supplier s
                      WHERE s.vendor_id = t.vendor_id);

    DROP TABLE IF EXISTS silver.stg_supplier;
END;
