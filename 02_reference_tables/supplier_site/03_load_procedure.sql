CREATE OR ALTER PROCEDURE silver.load_supplier_site @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    DROP TABLE IF EXISTS silver.stg_supplier_site;

    CREATE TABLE silver.stg_supplier_site AS
    SELECT
        x.vendor_site_id, x.party_site_id, x.vendor_site_code,
        x.source_last_update_date,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.party_site_id, '|', x.vendor_site_code, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            CAST(b.VendorSiteId AS BIGINT)                                 AS vendor_site_id,
            b.PartySiteId                                                  AS party_site_id,
            CAST(b.VendorSiteCode AS VARCHAR(240))                         AS vendor_site_code,
            b.LastUpdateDate                                               AS source_last_update_date,
            ROW_NUMBER() OVER (
                PARTITION BY b.VendorSiteId
                ORDER BY b.LastUpdateDate DESC, b._LoadDTS DESC
            ) AS rn
        FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prcextractam_pozbiccextractam_suppliersite] b
        -- no filter for this table
    ) x
    WHERE x.rn = 1;

    UPDATE t
    SET
        t.party_site_id            = s.party_site_id,
        t.vendor_site_code         = s.vendor_site_code,
        t.source_last_update_date  = s.source_last_update_date,
        t._row_hash                = s._row_hash,
        t._silver_loaded_at        = @now,
        t._is_deleted              = 0,
        t._run_id                  = @run_id
    FROM silver.supplier_site t
    INNER JOIN silver.stg_supplier_site s
        ON t.vendor_site_id = s.vendor_site_id
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    INSERT INTO silver.supplier_site
        (vendor_site_id, party_site_id, vendor_site_code,
         source_last_update_date, _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.vendor_site_id, s.party_site_id, s.vendor_site_code,
           s.source_last_update_date, s._row_hash, @now, 0, @run_id
    FROM silver.stg_supplier_site s
    WHERE NOT EXISTS (SELECT 1 FROM silver.supplier_site t
                      WHERE t.vendor_site_id = s.vendor_site_id);

    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.supplier_site t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_supplier_site s
                      WHERE s.vendor_site_id = t.vendor_site_id);

    DROP TABLE IF EXISTS silver.stg_supplier_site;
END;
