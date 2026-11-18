-- NYC Real Estate Analytics | 02 Data Quality
-- Read-only validation queries for the prepared table.
-- Known historical results are noted below; rerunning may differ if data changes.

-- 1. Missing values and eligibility-related issues
SELECT
  COUNT(*) AS total_records,
  COUNTIF(sale_price IS NULL) AS missing_sale_price,
  COUNTIF(sale_price = 0) AS zero_sale_price,
  COUNTIF(sale_price < 0) AS negative_sale_price,
  COUNTIF(sale_price BETWEEN 1 AND 10000) AS low_positive_sale_price,
  COUNTIF(gross_square_feet IS NULL) AS missing_gross_square_feet,
  COUNTIF(gross_square_feet = 0) AS zero_gross_square_feet,
  COUNTIF(gross_square_feet < 0) AS negative_gross_square_feet,
  COUNTIF(sale_date IS NULL) AS missing_sale_date,
  MIN(sale_date) AS earliest_sale_date,
  MAX(sale_date) AS latest_sale_date
FROM `active-campus-470021-s3.real_estate_raw.real_estate_cleaned`;
-- Previously observed: 82,576 records; 28,475 zero-price;
-- 37,716 missing gross area; 1,782 zero gross area; 1,669 low positive prices.

-- 2. Missing building area by category (do not impute every missing area as zero)
SELECT
  building_class_category,
  COUNT(*) AS records,
  COUNTIF(gross_square_feet IS NULL) AS missing_area_records,
  ROUND(SAFE_DIVIDE(COUNTIF(gross_square_feet IS NULL), COUNT(*)) * 100, 2) AS missing_area_pct
FROM `active-campus-470021-s3.real_estate_raw.real_estate_cleaned`
GROUP BY 1
ORDER BY missing_area_records DESC;

-- 3. Repeated exact records: exploratory review only
SELECT
  borough, block, lot, sale_date, sale_price,
  COUNT(*) AS matching_rows
FROM `active-campus-470021-s3.real_estate_raw.real_estate_cleaned`
GROUP BY 1,2,3,4,5
HAVING COUNT(*) > 1
ORDER BY matching_rows DESC;
-- The prior project found 0 duplicate groups under its full-row exact-match definition.
-- This narrower key check is NOT equivalent to that historical duplicate test.

-- 4. Monthly volumes, with zero vs positive price
SELECT
  FORMAT_DATE('%Y-%m', sale_date) AS sale_month,
  COUNT(*) AS total_records,
  COUNTIF(sale_price > 0) AS positive_price_records,
  COUNTIF(sale_price = 0) AS zero_price_records
FROM `active-campus-470021-s3.real_estate_raw.real_estate_cleaned`
WHERE sale_date IS NOT NULL
GROUP BY 1
ORDER BY 1;
