/* Gold layer: star schema for Power BI.
   Run after all Silver tables are loaded.

   Fabric Warehouse does not support recursive CTEs, so the date list is built
   by cross-joining digit rows (0-9) into numbers 0 to 9999. */

CREATE SCHEMA gold;
GO

DROP TABLE IF EXISTS gold.dim_date;

CREATE TABLE gold.dim_date AS
WITH digits AS (
    SELECT d FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(d)
),
numbers AS (
    SELECT a.d + b.d * 10 + c.d * 100 + e.d * 1000 AS n
    FROM digits a CROSS JOIN digits b CROSS JOIN digits c CROSS JOIN digits e
),
dates AS (
    SELECT DATEADD(DAY, n, CAST('2020-01-01' AS DATE)) AS calendar_date
    FROM numbers
    WHERE n <= DATEDIFF(DAY, '2020-01-01', '2030-12-31')
)
SELECT
    CAST(CONVERT(CHAR(8), calendar_date, 112) AS INT)        AS date_key,
    calendar_date,
    YEAR(calendar_date)                                      AS calendar_year,
    DATEPART(QUARTER, calendar_date)                         AS calendar_quarter,
    MONTH(calendar_date)                                     AS month_number,
    CAST(DATENAME(MONTH, calendar_date) AS VARCHAR(10))      AS month_name,
    CAST(LEFT(DATENAME(MONTH, calendar_date), 3) + '-'
         + RIGHT(CAST(YEAR(calendar_date) AS VARCHAR(4)), 2) AS VARCHAR(6)) AS period_name,
    CAST(CONVERT(CHAR(7), calendar_date, 120) AS VARCHAR(7)) AS year_month,
    DATEPART(ISO_WEEK, calendar_date)                        AS iso_week,
    DATEPART(WEEKDAY, calendar_date)                         AS weekday_number,
    CAST(DATENAME(WEEKDAY, calendar_date) AS VARCHAR(10))    AS weekday_name,
    CASE WHEN DATENAME(WEEKDAY, calendar_date) IN ('Saturday', 'Sunday')
         THEN 0 ELSE 1 END                                   AS is_working_day
FROM dates;

SELECT MIN(calendar_date) AS first_date, MAX(calendar_date) AS last_date, COUNT(*) AS days
FROM gold.dim_date;
