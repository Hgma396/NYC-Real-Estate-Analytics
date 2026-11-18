-- NYC Real Estate Analytics | 05 Exploratory Data Analysis
-- Read-only queries against the FINAL analytical table.

-- 1. Borough activity and standard pricing candidates
SELECT
  CASE borough
    WHEN 1 THEN 'Manhattan'
    WHEN 2 THEN 'Bronx'
    WHEN 3 THEN 'Brooklyn'
    WHEN 4 THEN 'Queens'
    WHEN 5 THEN 'Staten Island'
    ELSE 'Unknown'
  END AS borough_name,
  COUNT(*) AS total_records,
  COUNTIF(is_standard_pricing_candidate) AS pricing_candidates,
  COUNTIF(is_zero_price) AS zero_price_records
FROM `active-campus-470021-s3.real_estate_raw.real_estate_analytical`
GROUP BY 1
ORDER BY total_records DESC;

-- 2. Borough median prices (BigQuery exact median using PERCENTILE_CONT)
SELECT DISTINCT
  borough,
  PERCENTILE_CONT(IF(is_standard_pricing_candidate, sale_price, NULL), 0.5)
    OVER (PARTITION BY borough) AS median_sale_price
FROM `active-campus-470021-s3.real_estate_raw.real_estate_analytical`
ORDER BY median_sale_price DESC;

-- 3. Residential segments by borough and building type
SELECT
  borough,
  building_class_category,
  COUNTIF(is_standard_pricing_candidate) AS pricing_candidates
FROM `active-campus-470021-s3.real_estate_raw.real_estate_analytical`
WHERE building_class_category IN (
  '01 ONE FAMILY DWELLINGS',
  '02 TWO FAMILY DWELLINGS',
  '03 THREE FAMILY DWELLINGS',
  '10 COOPS - ELEVATOR APARTMENTS',
  '13 CONDOS - ELEVATOR APARTMENTS'
)
GROUP BY 1,2
ORDER BY borough, pricing_candidates DESC;

-- 4. Median sale-price-per-square-foot by borough
WITH eligible AS (
  SELECT borough, SAFE_DIVIDE(sale_price, gross_square_feet) AS price_per_sq_ft
  FROM `active-campus-470021-s3.real_estate_raw.real_estate_analytical`
  WHERE is_price_per_sqft_candidate
)
SELECT DISTINCT
  borough,
  PERCENTILE_CONT(price_per_sq_ft, 0.5) OVER (PARTITION BY borough)
    AS median_price_per_sq_ft
FROM eligible
ORDER BY median_price_per_sq_ft DESC;

-- 5. Monthly activity and pricing candidates
SELECT
  DATE_TRUNC(sale_date, MONTH) AS sale_month,
  COUNT(*) AS total_records,
  COUNTIF(is_standard_pricing_candidate) AS pricing_candidates
FROM `active-campus-470021-s3.real_estate_raw.real_estate_analytical`
GROUP BY 1
ORDER BY 1;

-- 6. Focused check: unusual Staten Island activity in September 2026
SELECT
  DATE_TRUNC(sale_date, MONTH) AS sale_month,
  COUNT(*) AS total_records,
  COUNTIF(is_zero_price) AS zero_price_records
FROM `active-campus-470021-s3.real_estate_raw.real_estate_analytical`
WHERE borough = 5 AND sale_date >= DATE '2026-07-01'
GROUP BY 1
ORDER BY 1;
