/* SCD Type 2: keep the history of each organization's name, location and region.
   When an organization moves to another region, the old row is closed
   (valid_to = today, is_current = 0) and a new row is opened. Cost posted
   before the move keeps reporting under the old region.

   Source: gold.dim_organization (the current-state view).
   Surrogate keys come from MAX + ROW_NUMBER, so this works in any Fabric
   Warehouse without relying on IDENTITY columns. */

CREATE TABLE gold.dim_organization_history (
    organization_sk      BIGINT        NOT NULL,
    organization_key     BIGINT        NOT NULL,
    organization_name    VARCHAR(240)  NULL,
    location_name        VARCHAR(240)  NULL,
    region_name          VARCHAR(240)  NULL,
    attribute_hash       VARBINARY(32) NULL,
    valid_from           DATE          NOT NULL,
    valid_to             DATE          NOT NULL,
    is_current           BIT           NOT NULL,
    _run_id              VARCHAR(100)  NULL
);
GO

CREATE OR ALTER PROCEDURE gold.load_dim_organization_history @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @today DATE = CAST(SYSUTCDATETIME() AS DATE);
    DECLARE @max_sk BIGINT;

    DROP TABLE IF EXISTS gold.stg_org_current;

    CREATE TABLE gold.stg_org_current AS
    SELECT
        organization_key, organization_name, location_name, region_name,
        CAST(HASHBYTES('SHA2_256', CONCAT(organization_name, '|', location_name, '|', region_name, '|'))
             AS VARBINARY(32)) AS attribute_hash
    FROM gold.dim_organization;

    /* 1. Close the current row of every organization whose attributes changed. */
    UPDATE h
    SET h.valid_to = DATEADD(DAY, -1, @today), h.is_current = 0, h._run_id = @run_id
    FROM gold.dim_organization_history h
    INNER JOIN gold.stg_org_current s
        ON s.organization_key = h.organization_key
    WHERE h.is_current = 1
      AND h.attribute_hash <> s.attribute_hash;

    /* 2. Insert a new current row for new organizations and for the ones just closed. */
    SELECT @max_sk = COALESCE(MAX(organization_sk), 0) FROM gold.dim_organization_history;

    INSERT INTO gold.dim_organization_history
        (organization_sk, organization_key, organization_name, location_name, region_name,
         attribute_hash, valid_from, valid_to, is_current, _run_id)
    SELECT
        @max_sk + ROW_NUMBER() OVER (ORDER BY s.organization_key),
        s.organization_key, s.organization_name, s.location_name, s.region_name,
        s.attribute_hash,
        CASE WHEN EXISTS (SELECT 1 FROM gold.dim_organization_history x
                          WHERE x.organization_key = s.organization_key)
             THEN @today ELSE '1900-01-01' END,
        '9999-12-31', 1, @run_id
    FROM gold.stg_org_current s
    WHERE NOT EXISTS (SELECT 1 FROM gold.dim_organization_history h
                      WHERE h.organization_key = s.organization_key AND h.is_current = 1);

    DROP TABLE IF EXISTS gold.stg_org_current;
END;
GO
