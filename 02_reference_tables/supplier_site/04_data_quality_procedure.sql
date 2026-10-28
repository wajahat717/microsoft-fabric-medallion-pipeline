CREATE OR ALTER PROCEDURE silver.dq_supplier_site @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    -- key is unique (uses every key column)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.supplier_site', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT vendor_site_id FROM silver.supplier_site
          GROUP BY vendor_site_id HAVING COUNT(*) > 1) x;

    -- key not null
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.supplier_site', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.supplier_site
    WHERE vendor_site_id IS NULL;

    -- main column filled (warning only)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.supplier_site', 'vendor_site_code not null', 'WARN', COUNT(*), @now
    FROM silver.supplier_site
    WHERE vendor_site_code IS NULL AND _is_deleted = 0;

    -- Silver active rows = Bronze distinct keys (after filter)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.supplier_site', 'row count matches bronze', 'ERROR',
           ABS(
             (SELECT COUNT(*) FROM silver.supplier_site WHERE _is_deleted = 0)
           - (SELECT COUNT(*) FROM (SELECT DISTINCT b.VendorSiteId
                                    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prcextractam_pozbiccextractam_suppliersite] b) d)
           ), @now;
END;
