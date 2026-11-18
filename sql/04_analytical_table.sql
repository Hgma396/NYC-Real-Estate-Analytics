-- NYC Real Estate Analytics | 04 Analytical Table
-- RECONSTRUCTED from previously documented business rules.
-- DO NOT RUN against the existing final table without reviewing first:
-- CREATE OR REPLACE TABLE overwrites the current analytical table.

CREATE OR REPLACE TABLE `active-campus-470021-s3.real_estate_raw.real_estate_analytical` AS
WITH bulk_groups AS (
  SELECT
    borough, block, sale_date, sale_price
  FROM `active-campus-470021-s3.real_estate_raw.real_estate_cleaned`
  WHERE sale_price >= 1000000 AND lot IS NOT NULL
  GROUP BY 1,2,3,4
  HAVING COUNT(*) >= 5 AND COUNT(DISTINCT lot) >= 5
),
flagged AS (
  SELECT
    c.*,
    (c.sale_price = 0) AS is_zero_price,
    (c.sale_price BETWEEN 1 AND 10000) AS is_low_price,
    (c.sale_price > 10000) AS is_pricing_candidate,
    (c.gross_square_feet IS NULL) AS is_missing_area,
    (c.gross_square_feet = 0) AS is_zero_area,
    (c.gross_square_feet > 0) AS has_valid_area,
    (b.borough IS NOT NULL) AS potential_bulk_sale
  FROM `active-campus-470021-s3.real_estate_raw.real_estate_cleaned` AS c
  LEFT JOIN bulk_groups AS b
    ON c.borough = b.borough
   AND c.block = b.block
   AND c.sale_date = b.sale_date
   AND c.sale_price = b.sale_price
)
SELECT
  *,
  (is_pricing_candidate AND NOT potential_bulk_sale) AS is_standard_pricing_candidate,
  (is_pricing_candidate AND NOT potential_bulk_sale AND has_valid_area) AS is_price_per_sqft_candidate
FROM flagged;

-- Benchmark checks from previously completed analysis:
-- 82,576 total | 1,320 bulk flagged | 51,112 standard pricing
-- 22,442 eligible price-per-sq-ft records.
-- Review row count, schema, and flags against the existing table before execution.
