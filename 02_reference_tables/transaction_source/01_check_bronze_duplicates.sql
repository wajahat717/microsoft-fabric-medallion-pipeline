SELECT COUNT(*) AS total_rows,
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT b.TransactionSourceBasePEOTransactionSourceId FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_transactionsource] b WHERE b.TransactionSourceTLPEOLanguage = 'US') d) AS duplicate_keys,
       (SELECT COUNT(*) FROM (SELECT DISTINCT b.TransactionSourceBasePEOTransactionSourceId FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_transactionsource] b WHERE b.TransactionSourceTLPEOLanguage = 'US') d) AS unique_keys
FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_transactionsource] b WHERE b.TransactionSourceTLPEOLanguage = 'US';
