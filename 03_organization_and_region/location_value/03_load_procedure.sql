CREATE OR ALTER PROCEDURE silver.load_location_value @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    DROP TABLE IF EXISTS silver.stg_location_value;

    CREATE TABLE silver.stg_location_value AS
    SELECT
        x.value_id, x.value_set_id, x.location_segment, x.location_name, x.attribute_category, x.language, x.enabled_flag,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.value_set_id, '|', x.location_segment, '|', x.location_name, '|', x.attribute_category, '|', x.language, '|', x.enabled_flag, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            b.ValueId                                                      AS value_id,
            b.ValueSetId                                                   AS value_set_id,
            CAST(b.Value AS VARCHAR(30))                                   AS location_segment,
            CAST(b.Description AS VARCHAR(240))                            AS location_name,
            CAST(b.AttributeCategory AS VARCHAR(150))                      AS attribute_category,
            CAST(b.Language AS VARCHAR(4))                                 AS language,
            CAST(b.EnabledFlag AS VARCHAR(1))                              AS enabled_flag,
            ROW_NUMBER() OVER (
                PARTITION BY b.ValueId
                ORDER BY b._LoadDTS DESC
            ) AS rn
        FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_finextractam_analyticsextractserviceam_valuesetvalues] b
        WHERE b.AttributeCategory = 'Location Tree'
              AND b.Language = 'US'
    ) x
    WHERE x.rn = 1;

    UPDATE t
    SET
        t.value_set_id             = s.value_set_id,
        t.location_segment         = s.location_segment,
        t.location_name            = s.location_name,
        t.attribute_category       = s.attribute_category,
        t.language                 = s.language,
        t.enabled_flag             = s.enabled_flag,
        t._row_hash               = s._row_hash,
        t._silver_loaded_at       = @now,
        t._is_deleted             = 0,
        t._run_id                 = @run_id
    FROM silver.location_value t
    INNER JOIN silver.stg_location_value s
        ON t.value_id = s.value_id
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    INSERT INTO silver.location_value
        (value_id, value_set_id, location_segment, location_name, attribute_category, language, enabled_flag,
         _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.value_id, s.value_set_id, s.location_segment, s.location_name, s.attribute_category, s.language, s.enabled_flag,
           s._row_hash, @now, 0, @run_id
    FROM silver.stg_location_value s
    WHERE NOT EXISTS (SELECT 1 FROM silver.location_value t
                      WHERE t.value_id = s.value_id);

    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.location_value t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_location_value s
                      WHERE s.value_id = t.value_id);

    DROP TABLE IF EXISTS silver.stg_location_value;
END;
