CREATE OR ALTER PROCEDURE silver.load_item @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    DROP TABLE IF EXISTS silver.stg_item;

    CREATE TABLE silver.stg_item AS
    SELECT
        x.inventory_item_id, x.organization_id, x.item_number,
        x.source_last_update_date,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.item_number, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            b.ItemBasePEOInventoryItemId                                   AS inventory_item_id,
            b.ItemBasePEOOrganizationId                                    AS organization_id,
            CAST(b.ItemBasePEOItemNumber AS VARCHAR(300))                  AS item_number,
            b.ItemBasePEOLastUpdateDate                                    AS source_last_update_date,
            ROW_NUMBER() OVER (
                PARTITION BY b.ItemBasePEOInventoryItemId, b.ItemBasePEOOrganizationId
                ORDER BY b.ItemBasePEOLastUpdateDate DESC, b._LoadDTS DESC
            ) AS rn
        FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_scmextractam_egpbiccextractam_item] b
        -- no filter for this table
    ) x
    WHERE x.rn = 1;

    UPDATE t
    SET
        t.item_number              = s.item_number,
        t.source_last_update_date  = s.source_last_update_date,
        t._row_hash                = s._row_hash,
        t._silver_loaded_at        = @now,
        t._is_deleted              = 0,
        t._run_id                  = @run_id
    FROM silver.item t
    INNER JOIN silver.stg_item s
        ON t.inventory_item_id = s.inventory_item_id AND t.organization_id = s.organization_id
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    INSERT INTO silver.item
        (inventory_item_id, organization_id, item_number,
         source_last_update_date, _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.inventory_item_id, s.organization_id, s.item_number,
           s.source_last_update_date, s._row_hash, @now, 0, @run_id
    FROM silver.stg_item s
    WHERE NOT EXISTS (SELECT 1 FROM silver.item t
                      WHERE t.inventory_item_id = s.inventory_item_id AND t.organization_id = s.organization_id);

    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.item t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_item s
                      WHERE s.inventory_item_id = t.inventory_item_id AND s.organization_id = t.organization_id);

    DROP TABLE IF EXISTS silver.stg_item;
END;
