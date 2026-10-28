SELECT COUNT(*)                                       AS total_rows,
       COUNT(DISTINCT b.PjcExpItemsAllExpenditureItemId)          AS unique_keys,
       COUNT(*) - COUNT(DISTINCT b.PjcExpItemsAllExpenditureItemId) AS duplicate_keys
FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjcbiccextractam_expenditureitem] b;
