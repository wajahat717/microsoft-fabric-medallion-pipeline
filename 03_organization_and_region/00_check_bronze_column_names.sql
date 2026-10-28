SELECT e.table_name, e.column_name AS missing_column
FROM (VALUES
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreenode', 'Depth'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreenode', 'ParentPk1Value'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreenode', 'Pk1StartValue'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreenode', 'TreeCode'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreenode', 'TreeNodeId'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreenode', 'TreeStructureCode'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreenode', 'TreeVersionId'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreenode', '_LoadDTS'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreeversion', 'EffectiveEndDate'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreeversion', 'EffectiveStartDate'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreeversion', 'Status'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreeversion', 'TreeCode'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreeversion', 'TreeStructureCode'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreeversion', 'TreeVersionId'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_fndtreeversion', '_LoadDTS'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_valuesetvalues', 'AttributeCategory'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_valuesetvalues', 'Description'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_valuesetvalues', 'EnabledFlag'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_valuesetvalues', 'Language'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_valuesetvalues', 'Value'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_valuesetvalues', 'ValueId'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_valuesetvalues', 'ValueSetId'),
    ('br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_valuesetvalues', '_LoadDTS'),
    ('br_oracle_fusion_fscm_finextractam_xlabiccextractam_subledgermappingsetvalue', 'MappingSetValueEffectiveEndDate'),
    ('br_oracle_fusion_fscm_finextractam_xlabiccextractam_subledgermappingsetvalue', 'MappingSetValueEffectiveStartDate'),
    ('br_oracle_fusion_fscm_finextractam_xlabiccextractam_subledgermappingsetvalue', 'MappingSetValueEnabledFlag'),
    ('br_oracle_fusion_fscm_finextractam_xlabiccextractam_subledgermappingsetvalue', 'MappingSetValueInputValueConstant1'),
    ('br_oracle_fusion_fscm_finextractam_xlabiccextractam_subledgermappingsetvalue', 'MappingSetValueMappingSetCode'),
    ('br_oracle_fusion_fscm_finextractam_xlabiccextractam_subledgermappingsetvalue', 'MappingSetValueValueConstant'),
    ('br_oracle_fusion_fscm_finextractam_xlabiccextractam_subledgermappingsetvalue', '_LoadDTS'),
    ('br_oracle_fusion_hcm_organizationam_organizationunit', 'EffectiveEndDate'),
    ('br_oracle_fusion_hcm_organizationam_organizationunit', 'EffectiveStartDate'),
    ('br_oracle_fusion_hcm_organizationam_organizationunit', 'OrganizationId'),
    ('br_oracle_fusion_hcm_organizationam_organizationunit', 'OrganizationUnitPEOLastUpdateDate'),
    ('br_oracle_fusion_hcm_organizationam_organizationunit', 'OrganizationUnitTranslationPEOLanguage'),
    ('br_oracle_fusion_hcm_organizationam_organizationunit', 'OrganizationUnitTranslationPEOName'),
    ('br_oracle_fusion_hcm_organizationam_organizationunit', '_LoadDTS')
) AS e(table_name, column_name)
LEFT JOIN [bronze_lakehouse].INFORMATION_SCHEMA.COLUMNS c
       ON c.TABLE_SCHEMA = 'bronze'
      AND c.TABLE_NAME   = e.table_name
      AND c.COLUMN_NAME  = e.column_name
WHERE c.COLUMN_NAME IS NULL
ORDER BY e.table_name, e.column_name;
