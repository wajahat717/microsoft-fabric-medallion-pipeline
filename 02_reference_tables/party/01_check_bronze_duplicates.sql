SELECT COUNT(*) AS total_rows,
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT b.PartyId FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_hzbiccextractam_party] b) d) AS duplicate_keys,
       (SELECT COUNT(*) FROM (SELECT DISTINCT b.PartyId FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_hzbiccextractam_party] b) d) AS unique_keys
FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_hzbiccextractam_party] b;
