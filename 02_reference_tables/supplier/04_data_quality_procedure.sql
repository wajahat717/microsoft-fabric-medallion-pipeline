CREATE OR ALTER PROCEDURE silver.dq_supplier @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    -- key is unique (uses every key column)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.supplier', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT vendor_id FROM silver.supplier
          GROUP BY vendor_id HAVING COUNT(*) > 1) x;

    -- key not null
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.supplier', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.supplier
    WHERE vendor_id IS NULL;

    -- main column filled (warning only)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.supplier', 'supplier_number not null', 'WARN', COUNT(*), @now
    FROM silver.supplier
    WHERE supplier_number IS NULL AND _is_deleted = 0;

    -- Silver active rows = Bronze distinct keys (after filter)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.supplier', 'row count matches bronze', 'ERROR',
           ABS(
             (SELECT COUNT(*) FROM silver.supplier WHERE _is_deleted = 0)
           - (SELECT COUNT(*) FROM (SELECT DISTINCT b.VendorId
                                    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prcextractam_pozbiccextractam_supplier] b) d)
           ), @now;
END;
