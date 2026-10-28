SELECT COUNT(*) AS total_rows,
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT b.ItemBasePEOInventoryItemId, b.ItemBasePEOOrganizationId FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_scmextractam_egpbiccextractam_item] b) d) AS duplicate_keys,
       (SELECT COUNT(*) FROM (SELECT DISTINCT b.ItemBasePEOInventoryItemId, b.ItemBasePEOOrganizationId FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_scmextractam_egpbiccextractam_item] b) d) AS unique_keys
FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_scmextractam_egpbiccextractam_item] b;
