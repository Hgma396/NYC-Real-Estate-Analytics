-- NYC Real Estate Analytics | 03 Potential Bulk-Sale Detection
-- Read-only detection; heuristic flags are not verified bulk transactions.
-- Matching borough + block + date + price with >= 5 distinct lots and sale price >= $1M.
-- Historical analysis identified 60 groups and 1,320 flagged records.

WITH transaction_groups AS (
  SELECT
    borough, block, sale_date, sale_price,
    COUNT(*) AS records_in_group,
    COUNT(DISTINCT lot) AS distinct_lots
  FROM `active-campus-470021-s3.real_estate_raw.real_estate_cleaned`
  WHERE sale_price >= 1000000
    AND borough IS NOT NULL
    AND block IS NOT NULL
    AND lot IS NOT NULL
    AND sale_date IS NOT NULL
  GROUP BY 1,2,3,4
),
potential_bulk_groups AS (
  SELECT *
  FROM transaction_groups
  WHERE records_in_group >= 5
    AND distinct_lots >= 5
)
SELECT
  COUNT(*) AS flagged_groups,
  SUM(records_in_group) AS flagged_record_count,
  SUM(sale_price * records_in_group) AS sum_of_recorded_prices
FROM potential_bulk_groups;

-- Detail inspection of suspicious groups
WITH transaction_groups AS (
  SELECT borough, block, sale_date, sale_price,
         COUNT(*) AS records_in_group,
         COUNT(DISTINCT lot) AS distinct_lots
  FROM `active-campus-470021-s3.real_estate_raw.real_estate_cleaned`
  WHERE sale_price >= 1000000 AND lot IS NOT NULL
  GROUP BY 1,2,3,4
)
SELECT *
FROM transaction_groups
WHERE records_in_group >= 5 AND distinct_lots >= 5
ORDER BY records_in_group DESC, sale_price DESC;

-- Do not claim summing duplicate-looking prices is proven financial overstatement.
