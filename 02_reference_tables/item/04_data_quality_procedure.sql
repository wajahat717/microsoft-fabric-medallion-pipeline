CREATE OR ALTER PROCEDURE silver.dq_item @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    -- key is unique (uses every key column)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.item', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT inventory_item_id, organization_id FROM silver.item
          GROUP BY inventory_item_id, organization_id HAVING COUNT(*) > 1) x;

    -- key not null
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.item', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.item
    WHERE inventory_item_id IS NULL OR organization_id IS NULL;

    -- main column filled (warning only)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.item', 'item_number not null', 'WARN', COUNT(*), @now
    FROM silver.item
    WHERE item_number IS NULL AND _is_deleted = 0;

    -- Silver active rows = Bronze distinct keys (after filter)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.item', 'row count matches bronze', 'ERROR',
           ABS(
             (SELECT COUNT(*) FROM silver.item WHERE _is_deleted = 0)
           - (SELECT COUNT(*) FROM (SELECT DISTINCT b.ItemBasePEOInventoryItemId, b.ItemBasePEOOrganizationId
                                    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_scmextractam_egpbiccextractam_item] b) d)
           ), @now;
END;
