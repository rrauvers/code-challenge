-- SQL to insert data into dimension tables using SCD Type 2
CREATE TEMP TABLE customer_changes AS
WITH source_data AS (
  SELECT
   id,
   name,
   email,
   registration_date,
   country,
   -- Create a hash of all tracked columns for change detection
   TO_HEX(MD5(TO_JSON_STRING(STRUCT(
   id,
   name,
   email,
   registration_date,
   country
    )))) AS row_hash
  FROM `silver.customers`
),
current_dimension AS (
  SELECT customer_id, row_hash
  FROM `gold.dim_customer`
  WHERE is_current = TRUE
)
SELECT
  s.*,
  CASE
    WHEN d.customer_id IS NULL THEN 'INSERT'
    WHEN d.row_hash IS DISTINCT FROM s.row_hash THEN 'UPDATE'
    ELSE 'NO_CHANGE'
  END AS change_type
FROM source_data s
LEFT JOIN current_dimension d ON s.id = d.customer_id
WHERE d.customer_id IS NULL OR d.row_hash IS DISTINCT FROM s.row_hash;

-- Expire the current rows that have changes
MERGE INTO `gold.dim_customer` AS target
USING customer_changes AS source
ON target.customer_id = source.id
  AND target.is_current = TRUE
  AND source.change_type = 'UPDATE'
WHEN MATCHED THEN
  UPDATE SET
    valid_to = CURRENT_TIMESTAMP(),
    is_current = FALSE,
    updated_at = CURRENT_TIMESTAMP();

-- Insert new rows for both new customers and changed customers
INSERT INTO `gold.dim_customer`
(customer_sk, customer_id, name, email, country, registration_date, valid_from, valid_to, is_current, row_hash,
 created_at, updated_at)
SELECT
  -- Generate a surrogate key using a sequence or hash
  FARM_FINGERPRINT(CONCAT(id, CAST(CURRENT_TIMESTAMP() AS STRING))) AS customer_sk,
  id,
  name,
  email,
  country,
  registration_date,
  CURRENT_TIMESTAMP() AS valid_from,
  NULL AS valid_to,
  TRUE AS is_current,
  row_hash,
  CURRENT_TIMESTAMP() AS created_at,
  CURRENT_TIMESTAMP() AS updated_at
FROM customer_changes
WHERE change_type IN ('INSERT', 'UPDATE');