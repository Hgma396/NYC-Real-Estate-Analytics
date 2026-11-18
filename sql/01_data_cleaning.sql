-- NYC Real Estate Analytics | 01 Data Cleaning
-- RECONSTRUCTED documentation query, not a verbatim recovered historical job.
-- BigQuery Standard SQL. DO NOT RUN on the existing project without reviewing:
-- CREATE OR REPLACE TABLE overwrites its target.
-- Purpose: reproduce a typed snake_case working table from rawsales.
-- Existing target: active-campus-470021-s3.real_estate_raw.real_estate_cleaned

DECLARE select_list STRING;

SET select_list = (
  SELECT STRING_AGG(
    CASE
      WHEN cleaned_name IN ('sale_price', 'gross_square_feet', 'land_square_feet') THEN
        FORMAT('SAFE_CAST(NULLIF(REPLACE(TRIM(CAST(`%s` AS STRING)), ",", ""), "") AS NUMERIC) AS `%s`', column_name, cleaned_name)
      WHEN cleaned_name IN ('borough', 'block', 'lot', 'zip_code', 'residential_units', 'commercial_units', 'total_units', 'year_built') THEN
        FORMAT('SAFE_CAST(NULLIF(REPLACE(TRIM(CAST(`%s` AS STRING)), ",", ""), "") AS INT64) AS `%s`', column_name, cleaned_name)
      WHEN cleaned_name = 'sale_date' THEN
        FORMAT('SAFE_CAST(`%s` AS DATE) AS `%s`', column_name, cleaned_name)
      ELSE FORMAT('`%s` AS `%s`', column_name, cleaned_name)
    END,
    ',\n  ' ORDER BY ordinal_position
  )
  FROM (
    SELECT column_name, ordinal_position,
      TRIM(REGEXP_REPLACE(LOWER(TRIM(column_name)), r'[^a-z0-9]+', '_'), '_') AS cleaned_name
    FROM `active-campus-470021-s3.real_estate_raw.INFORMATION_SCHEMA.COLUMNS`
    WHERE table_name = 'rawsales'
  )
);

EXECUTE IMMEDIATE FORMAT('''
  CREATE OR REPLACE TABLE `active-campus-470021-s3.real_estate_raw.real_estate_cleaned` AS
  SELECT
    %s
  FROM `active-campus-470021-s3.real_estate_raw.rawsales`
''', select_list);

-- Verify the schema and row count separately before treating the result as final.
