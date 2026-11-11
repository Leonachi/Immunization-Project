/* =====================================================================
   01_create_and_load.sql   (Microsoft SQL Server / SSMS)
   Creates the database + table and loads data/processed/wuenic_west_africa_wide.csv
   Run the script with python/02_transform.py FIRST so the CSV exists.
   ===================================================================== */

IF DB_ID('ImmunizationDB') IS NULL
    CREATE DATABASE ImmunizationDB;
GO

USE ImmunizationDB;
GO

DROP TABLE IF EXISTS dbo.wuenic_west_africa;
GO

/* Grain: one row per country per year (primary key enforces it). */
CREATE TABLE dbo.wuenic_west_africa (
    iso3c               CHAR(3)       NOT NULL,
    country             NVARCHAR(60)  NOT NULL,
    [year]              SMALLINT      NOT NULL,
    dtp1_coverage       DECIMAL(5,1)  NULL,
    dtp3_coverage       DECIMAL(5,1)  NULL,
    mcv1_coverage       DECIMAL(5,1)  NULL,
    mcv2_coverage       DECIMAL(5,1)  NULL,   -- NULL before the country introduced MCV2
    zero_dose_pct       DECIMAL(5,1)  NULL,
    dtp_dropout_pct     DECIMAL(5,1)  NULL,
    dtp1_gap_to_95      DECIMAL(5,1)  NULL,
    dtp3_gap_to_95      DECIMAL(5,1)  NULL,
    mcv1_gap_to_95      DECIMAL(5,1)  NULL,
    mcv2_gap_to_95      DECIMAL(5,1)  NULL,
    mcv1_to_mcv2_drop   DECIMAL(5,1)  NULL,
    CONSTRAINT PK_wuenic_west_africa PRIMARY KEY (iso3c, [year])
);
GO

/* ---------------------------------------------------------------------
   LOAD OPTION A: BULK INSERT
   1. Change the path below to the FULL path of your CSV.
   2. SQL Server reads the file using its own Windows account, so the file
      must be somewhere it is allowed to read. A OneDrive Desktop folder
      often is NOT. If you get "Operating system error 5 (Access is denied)",
      copy the CSV to C:\data\ and use that path, or use OPTION B.
   --------------------------------------------------------------------- */
BULK INSERT dbo.wuenic_west_africa
FROM 'C:\data\wuenic_west_africa_wide.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,          -- skip the header row
    FIELDTERMINATOR = ',',
    FIELDQUOTE = '"',
    KEEPNULLS,             -- empty cells (e.g. early MCV2) become NULL
    CODEPAGE = '65001'     -- UTF-8
);
GO

/* ---------------------------------------------------------------------
   LOAD OPTION B (no file permissions needed):
   In SSMS: right-click the database ImmunizationDB -> Tasks -> Import Flat File...
   Pick the CSV, name the table wuenic_west_africa_import, check the column types,
   then finish. Or skip SQL loading for now and use Power BI's CSV import.
   --------------------------------------------------------------------- */

/* Check the load: expect 416 rows and 16 countries. */
SELECT COUNT(*)                 AS row_count,
       COUNT(DISTINCT iso3c)    AS countries,
       MIN([year])              AS first_year,
       MAX([year])              AS last_year
FROM dbo.wuenic_west_africa;
GO
