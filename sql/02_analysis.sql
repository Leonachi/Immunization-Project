/* =====================================================================
   02_analysis.sql   (Microsoft SQL Server / SSMS)
   Gap analysis queries. Run each query on its own (highlight, press F5).
   Gap = 95 - coverage.  Positive gap = below the 95% target.
   ===================================================================== */

USE ImmunizationDB;
GO

/* Q1. Latest-year scorecard: how far is each country from 95%? */
SELECT country,
       dtp1_coverage, dtp3_coverage, mcv1_coverage, mcv2_coverage,
       mcv1_gap_to_95, mcv2_gap_to_95
FROM dbo.wuenic_west_africa
WHERE [year] = (SELECT MAX([year]) FROM dbo.wuenic_west_africa)
ORDER BY mcv1_gap_to_95 DESC;
GO

/* Q2. Rank countries by MCV1 gap in the latest year (1 = furthest from target). */
SELECT RANK() OVER (ORDER BY mcv1_gap_to_95 DESC) AS gap_rank,
       country, mcv1_coverage, mcv1_gap_to_95
FROM dbo.wuenic_west_africa
WHERE [year] = (SELECT MAX([year]) FROM dbo.wuenic_west_africa)
ORDER BY gap_rank, country;
GO

/* Q3. Zero-dose children (never received DTP1) and DTP1->DTP3 dropout, latest year. */
SELECT country, dtp1_coverage, dtp3_coverage, zero_dose_pct, dtp_dropout_pct
FROM dbo.wuenic_west_africa
WHERE [year] = (SELECT MAX([year]) FROM dbo.wuenic_west_africa)
ORDER BY zero_dose_pct DESC;
GO

/* Q4. Progress since 2000: MCV1 coverage then vs now. */
SELECT a.country,
       a.mcv1_coverage                      AS mcv1_2000,
       b.mcv1_coverage                      AS mcv1_latest,
       b.mcv1_coverage - a.mcv1_coverage    AS change_pts
FROM dbo.wuenic_west_africa AS a
JOIN dbo.wuenic_west_africa AS b
  ON a.iso3c = b.iso3c
WHERE a.[year] = 2000
  AND b.[year] = (SELECT MAX([year]) FROM dbo.wuenic_west_africa)
ORDER BY change_pts;
GO

/* Q5. Year-on-year change in MCV1 for every country (window function LAG). */
SELECT country, [year], mcv1_coverage,
       mcv1_coverage - LAG(mcv1_coverage) OVER (PARTITION BY iso3c ORDER BY [year]) AS yoy_change
FROM dbo.wuenic_west_africa
ORDER BY country, [year];
GO

/* Q6. How many years has each country been below the 95% MCV1 target? */
SELECT country,
       SUM(CASE WHEN mcv1_gap_to_95 > 0 THEN 1 ELSE 0 END) AS years_below_95,
       COUNT(*)                                            AS years_total
FROM dbo.wuenic_west_africa
GROUP BY country
ORDER BY years_below_95 DESC, country;
GO

/* Q7. Regional average by year (simple average of the 16 countries, not population-weighted). */
SELECT [year],
       CAST(AVG(dtp1_coverage) AS DECIMAL(5,1)) AS avg_dtp1,
       CAST(AVG(dtp3_coverage) AS DECIMAL(5,1)) AS avg_dtp3,
       CAST(AVG(mcv1_coverage) AS DECIMAL(5,1)) AS avg_mcv1,
       CAST(AVG(mcv2_coverage) AS DECIMAL(5,1)) AS avg_mcv2   -- ignores NULLs
FROM dbo.wuenic_west_africa
GROUP BY [year]
ORDER BY [year];
GO
