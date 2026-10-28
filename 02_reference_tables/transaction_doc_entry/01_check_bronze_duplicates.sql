SELECT COUNT(*) AS total_rows,
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT b.TransactionDocEntryBasePEODocEntryId FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_transactiondocumententry] b WHERE b.TransactionDocEntryTLPEOLanguage = 'US') d) AS duplicate_keys,
       (SELECT COUNT(*) FROM (SELECT DISTINCT b.TransactionDocEntryBasePEODocEntryId FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_transactiondocumententry] b WHERE b.TransactionDocEntryTLPEOLanguage = 'US') d) AS unique_keys
FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_transactiondocumententry] b WHERE b.TransactionDocEntryTLPEOLanguage = 'US';
