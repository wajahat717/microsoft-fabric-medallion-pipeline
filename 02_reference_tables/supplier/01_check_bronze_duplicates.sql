SELECT COUNT(*) AS total_rows,
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT b.VendorId FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prcextractam_pozbiccextractam_supplier] b) d) AS duplicate_keys,
       (SELECT COUNT(*) FROM (SELECT DISTINCT b.VendorId FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prcextractam_pozbiccextractam_supplier] b) d) AS unique_keys
FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prcextractam_pozbiccextractam_supplier] b;
