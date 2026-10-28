CREATE OR ALTER PROCEDURE silver.load_expenditure_item @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    /* ---------- STEP 1: STAGE ---------- */
    DROP TABLE IF EXISTS silver.stg_expenditure_item;

    CREATE TABLE silver.stg_expenditure_item AS
    SELECT
        x.expenditure_item_id, x.expenditure_item_date, x.expenditure_type_id, x.expenditure_organization_id, x.incurred_by_organization_id, x.incurred_by_person_id, x.billing_job_id, x.project_role_id, x.transaction_source_id, x.doc_entry_id, x.inventory_item_id, x.po_header_id, x.po_line_id, x.orig_transaction_reference, x.billable_flag, x.burden_cost_rate, x.unit_of_measure, x.adjusted_expenditure_item_id, x.transferred_from_exp_item_id, x.vehicle_number, x.waste_facility_entered, x.treatment_technology_entered, x.weight_volume, x.container_size, x.profile_number, x.weight_volume_uom, x.container_count, x.waste_detail_text, x.site_name, x.waste_weight, x.process_code, x.waste_type, x.waste_facility, x.treatment_technology, x.manifest_number, x.manifest_line_number, x.source_manifest, x.last_update_date,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.expenditure_item_date, '|',
            x.expenditure_type_id, '|',
            x.expenditure_organization_id, '|',
            x.incurred_by_organization_id, '|',
            x.incurred_by_person_id, '|',
            x.billing_job_id, '|',
            x.project_role_id, '|',
            x.transaction_source_id, '|',
            x.doc_entry_id, '|',
            x.inventory_item_id, '|',
            x.po_header_id, '|',
            x.po_line_id, '|',
            x.orig_transaction_reference, '|',
            x.billable_flag, '|',
            x.burden_cost_rate, '|',
            x.unit_of_measure, '|',
            x.adjusted_expenditure_item_id, '|',
            x.transferred_from_exp_item_id, '|',
            x.vehicle_number, '|',
            x.waste_facility_entered, '|',
            x.treatment_technology_entered, '|',
            x.weight_volume, '|',
            x.container_size, '|',
            x.profile_number, '|',
            x.weight_volume_uom, '|',
            x.container_count, '|',
            x.waste_detail_text, '|',
            x.site_name, '|',
            x.waste_weight, '|',
            x.process_code, '|',
            x.waste_type, '|',
            x.waste_facility, '|',
            x.treatment_technology, '|',
            x.manifest_number, '|',
            x.manifest_line_number, '|',
            x.source_manifest, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            b.PjcExpItemsAllExpenditureItemId                          AS expenditure_item_id,
            CAST(b.PjcExpItemsAllExpenditureItemDate AS DATE)          AS expenditure_item_date,
            b.PjcExpItemsAllExpenditureTypeId                          AS expenditure_type_id,
            b.PjcExpItemsAllExpenditureOrganizationId                  AS expenditure_organization_id,
            b.PjcExpItemsAllIncurredByOrganizationId                   AS incurred_by_organization_id,
            b.PjcExpItemsAllIncurredByPersonId                         AS incurred_by_person_id,
            b.PjcExpItemsAllPersonJobId                                AS billing_job_id,
            b.PjcExpItemsAllProjectRoleId                              AS project_role_id,
            b.PjcExpItemsAllTransactionSourceId                        AS transaction_source_id,
            b.PjcExpItemsAllDocEntryId                                 AS doc_entry_id,
            b.PjcExpItemsAllInventoryItemId                            AS inventory_item_id,
            b.PjcExpItemsAllParentHeaderId                             AS po_header_id,
            b.PjcExpItemsAllParentLineNumber                           AS po_line_id,
            CAST(b.PjcExpItemsAllOrigTransactionReference AS VARCHAR(120)) AS orig_transaction_reference,
            CAST(b.PjcExpItemsAllBillableFlag AS VARCHAR(1))           AS billable_flag,
            CAST(b.PjcExpItemsAllBurdenCostRate AS DECIMAL(19,6))      AS burden_cost_rate,
            CAST(b.PjcExpItemsAllUnitOfMeasure AS VARCHAR(30))         AS unit_of_measure,
            b.PjcExpItemsAllAdjustedExpenditureItemId                  AS adjusted_expenditure_item_id,
            b.PjcExpItemsAllTransferredFromExpItemId                   AS transferred_from_exp_item_id,
            CAST(b.PjcExpItemsAllAttribute4 AS VARCHAR(150))           AS vehicle_number,
            CAST(b.PjcExpItemsAllAttribute3 AS VARCHAR(150))           AS waste_facility_entered,
            CAST(b.PjcExpItemsAllAttribute5 AS VARCHAR(150))           AS treatment_technology_entered,
            TRY_CAST(b.PjcExpItemsAllUserDefAttribute1 AS DECIMAL(19,4)) AS weight_volume,
            CAST(b.PjcExpItemsAllUserDefAttribute2 AS VARCHAR(150))    AS container_size,
            CAST(b.PjcExpItemsAllUserDefAttribute3 AS VARCHAR(150))    AS profile_number,
            CAST(b.PjcExpItemsAllUserDefAttribute4 AS VARCHAR(150))    AS weight_volume_uom,
            TRY_CAST(b.PjcExpItemsAllUserDefAttribute5 AS DECIMAL(19,4)) AS container_count,
            CAST(b.PjcExpItemsAllUserDefAttribute6 AS VARCHAR(150))    AS waste_detail_text,
            CAST(b.PjcExpItemsAllUserDefAttribute7 AS VARCHAR(150))    AS site_name,
            TRY_CAST(b.PjcExpItemsAllUserDefAttribute8 AS DECIMAL(19,4)) AS waste_weight,
            CAST(b.PjcExpItemsAllUserDefAttribute9 AS VARCHAR(150))    AS process_code,
            CAST(CASE WHEN b.PjcExpItemsAllUserDefAttribute9 IS NOT NULL THEN b.PjcExpItemsAllUserDefAttribute6 END AS VARCHAR(150)) AS waste_type,
            CAST(COALESCE(b.PjcExpItemsAllAttribute3, pst.party_site_name) AS VARCHAR(360)) AS waste_facility,
            CAST(b.PjcExpItemsAllAttribute5 AS VARCHAR(150))           AS treatment_technology,
            CAST(CASE
                WHEN ts.user_transaction_source = 'External Costing System' THEN
                    CASE WHEN CHARINDEX('-', b.PjcExpItemsAllOrigTransactionReference) > 0
                         THEN LEFT(b.PjcExpItemsAllOrigTransactionReference, LEN(b.PjcExpItemsAllOrigTransactionReference) - CHARINDEX('-', REVERSE(b.PjcExpItemsAllOrigTransactionReference)))
                    END
                WHEN psr.rule_name = 'Manifest PO' THEN ph.po_number
                WHEN et.expenditure_type_name IN ('Per Piece Labor', 'Per Piece Transport', 'Manifest Fees') THEN
                    CASE WHEN CHARINDEX('-', b.PjcExpItemsAllUserDefAttribute6) > 0
                         THEN TRIM(SUBSTRING(b.PjcExpItemsAllUserDefAttribute6, CHARINDEX('-', b.PjcExpItemsAllUserDefAttribute6) + 1, 4000))
                    END
            END AS VARCHAR(150)) AS manifest_number,
            CAST(CASE
                WHEN ts.user_transaction_source = 'External Costing System' AND de.doc_entry_name = 'eManifest Fee' THEN NULL
                WHEN ts.user_transaction_source = 'External Costing System' THEN
                    CASE WHEN CHARINDEX('-', b.PjcExpItemsAllOrigTransactionReference) > 0
                         THEN RIGHT(b.PjcExpItemsAllOrigTransactionReference, CHARINDEX('-', REVERSE(b.PjcExpItemsAllOrigTransactionReference)) - 1)
                         ELSE b.PjcExpItemsAllOrigTransactionReference
                    END
                WHEN psr.rule_name = 'Manifest PO' THEN CAST(pl.line_num AS VARCHAR(30))
            END AS VARCHAR(30)) AS manifest_line_number,
            CAST(CASE
                WHEN et.expenditure_type_name IN ('Per Piece Labor', 'Per Piece Transport', 'Manifest Fees')
                 AND CHARINDEX('-', b.PjcExpItemsAllUserDefAttribute6) > 0
                THEN TRIM(SUBSTRING(b.PjcExpItemsAllUserDefAttribute6, CHARINDEX('-', b.PjcExpItemsAllUserDefAttribute6) + 1, 4000))
            END AS VARCHAR(150)) AS source_manifest,
            b.PjcExpItemsAllLastUpdateDate                             AS last_update_date,
            ROW_NUMBER() OVER (
                PARTITION BY b.PjcExpItemsAllExpenditureItemId
                ORDER BY b.PjcExpItemsAllLastUpdateDate DESC, b._LoadDTS DESC
            ) AS rn
        FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjcbiccextractam_expenditureitem] b
        LEFT JOIN silver.transaction_source    ts  ON ts.transaction_source_id = b.PjcExpItemsAllTransactionSourceId AND ts._is_deleted = 0
        LEFT JOIN silver.transaction_doc_entry de  ON de.doc_entry_id          = b.PjcExpItemsAllDocEntryId          AND de._is_deleted = 0
        LEFT JOIN silver.expenditure_type      et  ON et.expenditure_type_id   = b.PjcExpItemsAllExpenditureTypeId   AND et._is_deleted = 0
        LEFT JOIN silver.po_header             ph  ON ph.po_header_id          = b.PjcExpItemsAllParentHeaderId      AND ph._is_deleted = 0
        LEFT JOIN silver.po_line               pl  ON pl.po_header_id          = ph.po_header_id
                                                  AND pl.po_line_id            = b.PjcExpItemsAllParentLineNumber    AND pl._is_deleted = 0
        LEFT JOIN silver.supplier_site         ss  ON ss.vendor_site_id        = ph.vendor_site_id       AND ss._is_deleted = 0
        LEFT JOIN silver.party_site            pst ON pst.party_site_id        = ss.party_site_id        AND pst._is_deleted = 0
        LEFT JOIN ref.po_style_rule            psr ON psr.style_id             = ph.style_id
    ) x
    WHERE x.rn = 1;

    /* ---------- STEP 2: UPDATE rows that changed ---------- */
    UPDATE t
    SET
        t.expenditure_item_date          = s.expenditure_item_date,
        t.expenditure_type_id            = s.expenditure_type_id,
        t.expenditure_organization_id    = s.expenditure_organization_id,
        t.incurred_by_organization_id    = s.incurred_by_organization_id,
        t.incurred_by_person_id          = s.incurred_by_person_id,
        t.billing_job_id                 = s.billing_job_id,
        t.project_role_id                = s.project_role_id,
        t.transaction_source_id          = s.transaction_source_id,
        t.doc_entry_id                   = s.doc_entry_id,
        t.inventory_item_id              = s.inventory_item_id,
        t.po_header_id                   = s.po_header_id,
        t.po_line_id                     = s.po_line_id,
        t.orig_transaction_reference     = s.orig_transaction_reference,
        t.billable_flag                  = s.billable_flag,
        t.burden_cost_rate               = s.burden_cost_rate,
        t.unit_of_measure                = s.unit_of_measure,
        t.adjusted_expenditure_item_id   = s.adjusted_expenditure_item_id,
        t.transferred_from_exp_item_id   = s.transferred_from_exp_item_id,
        t.vehicle_number                 = s.vehicle_number,
        t.waste_facility_entered         = s.waste_facility_entered,
        t.treatment_technology_entered   = s.treatment_technology_entered,
        t.weight_volume                  = s.weight_volume,
        t.container_size                 = s.container_size,
        t.profile_number                 = s.profile_number,
        t.weight_volume_uom              = s.weight_volume_uom,
        t.container_count                = s.container_count,
        t.waste_detail_text              = s.waste_detail_text,
        t.site_name                      = s.site_name,
        t.waste_weight                   = s.waste_weight,
        t.process_code                   = s.process_code,
        t.waste_type                     = s.waste_type,
        t.waste_facility                 = s.waste_facility,
        t.treatment_technology           = s.treatment_technology,
        t.manifest_number                = s.manifest_number,
        t.manifest_line_number           = s.manifest_line_number,
        t.source_manifest                = s.source_manifest,
        t.last_update_date               = s.last_update_date,
        t._row_hash                       = s._row_hash,
        t._silver_loaded_at               = @now,
        t._is_deleted                     = 0,
        t._run_id                         = @run_id
    FROM silver.expenditure_item t
    INNER JOIN silver.stg_expenditure_item s
        ON t.expenditure_item_id = s.expenditure_item_id
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    /* ---------- STEP 3: INSERT new rows ---------- */
    INSERT INTO silver.expenditure_item
        (expenditure_item_id, expenditure_item_date, expenditure_type_id, expenditure_organization_id, incurred_by_organization_id, incurred_by_person_id, billing_job_id, project_role_id, transaction_source_id, doc_entry_id, inventory_item_id, po_header_id, po_line_id, orig_transaction_reference, billable_flag, burden_cost_rate, unit_of_measure, adjusted_expenditure_item_id, transferred_from_exp_item_id, vehicle_number, waste_facility_entered, treatment_technology_entered, weight_volume, container_size, profile_number, weight_volume_uom, container_count, waste_detail_text, site_name, waste_weight, process_code, waste_type, waste_facility, treatment_technology, manifest_number, manifest_line_number, source_manifest, last_update_date,
         _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.expenditure_item_id, s.expenditure_item_date, s.expenditure_type_id, s.expenditure_organization_id, s.incurred_by_organization_id, s.incurred_by_person_id, s.billing_job_id, s.project_role_id, s.transaction_source_id, s.doc_entry_id, s.inventory_item_id, s.po_header_id, s.po_line_id, s.orig_transaction_reference, s.billable_flag, s.burden_cost_rate, s.unit_of_measure, s.adjusted_expenditure_item_id, s.transferred_from_exp_item_id, s.vehicle_number, s.waste_facility_entered, s.treatment_technology_entered, s.weight_volume, s.container_size, s.profile_number, s.weight_volume_uom, s.container_count, s.waste_detail_text, s.site_name, s.waste_weight, s.process_code, s.waste_type, s.waste_facility, s.treatment_technology, s.manifest_number, s.manifest_line_number, s.source_manifest, s.last_update_date,
           s._row_hash, @now, 0, @run_id
    FROM silver.stg_expenditure_item s
    WHERE NOT EXISTS (SELECT 1 FROM silver.expenditure_item t
                      WHERE t.expenditure_item_id = s.expenditure_item_id);

    /* ---------- STEP 4: SOFT-DELETE rows gone from Bronze ---------- */
    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.expenditure_item t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_expenditure_item s
                      WHERE s.expenditure_item_id = t.expenditure_item_id);

    DROP TABLE IF EXISTS silver.stg_expenditure_item;
END;
