SELECT COUNT(*) AS total_rows,
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT b.ProjectRoleTypeTranslationProjectRoleId FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_projectroletypetranslation] b WHERE b.ProjectRoleTypeTranslationLanguage = 'US') d) AS duplicate_keys,
       (SELECT COUNT(*) FROM (SELECT DISTINCT b.ProjectRoleTypeTranslationProjectRoleId FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_projectroletypetranslation] b WHERE b.ProjectRoleTypeTranslationLanguage = 'US') d) AS unique_keys
FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_projectroletypetranslation] b WHERE b.ProjectRoleTypeTranslationLanguage = 'US';
