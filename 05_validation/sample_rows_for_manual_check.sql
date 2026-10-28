SELECT TOP 20 *
FROM (
    SELECT e.expenditure_item_id, e.expenditure_item_date, et.expenditure_type_name,
           ts.user_transaction_source, e.orig_transaction_reference, e.waste_detail_text,
           e.manifest_number, e.manifest_line_number, e.source_manifest,
           e.waste_type, e.waste_facility, e.treatment_technology,
           CASE WHEN ts.user_transaction_source = 'External Costing System' THEN 'External Costing System'
                WHEN e.manifest_number IS NOT NULL AND e.source_manifest IS NULL THEN 'Manifest PO'
                WHEN et.expenditure_type_name IN ('Per Piece Labor', 'Per Piece Transport', 'Manifest Fees') THEN 'Per Piece'
           END AS sample_group,
           ROW_NUMBER() OVER (PARTITION BY
               CASE WHEN ts.user_transaction_source = 'External Costing System' THEN 'External Costing System'
                    WHEN e.manifest_number IS NOT NULL AND e.source_manifest IS NULL THEN 'Manifest PO'
                    WHEN et.expenditure_type_name IN ('Per Piece Labor', 'Per Piece Transport', 'Manifest Fees') THEN 'Per Piece'
               END ORDER BY e.expenditure_item_id) AS rn
    FROM silver.expenditure_item e
    LEFT JOIN silver.expenditure_type   et ON et.expenditure_type_id   = e.expenditure_type_id
    LEFT JOIN silver.transaction_source ts ON ts.transaction_source_id = e.transaction_source_id
    WHERE e._is_deleted = 0
      AND e.expenditure_item_date >= '2026-08-01' AND e.expenditure_item_date < '2026-09-01'   -- closed month
) x
WHERE sample_group IS NOT NULL AND rn <= 7
ORDER BY sample_group, expenditure_item_id;
