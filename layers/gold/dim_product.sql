-- SQL to insert data into product dimension tables using SCD Type 2
CREATE TEMP TABLE product_changes AS
WITH source_data AS (
  SELECT
   id,
   name,
   category,
   description,
   base_price,
   currency,
   -- Create a hash of all tracked columns for change detection
   TO_HEX(MD5(TO_JSON_STRING(STRUCT(
   id,
   name,
   category,
   description,
   base_price,
   currency
    )))) AS row_hash
  FROM `silver.product_descriptions`
),
current_dimension AS (
  SELECT product_id, row_hash
  FROM `gold.dim_product`
  WHERE is_current = TRUE
)
SELECT
  s.*,
  CASE
    WHEN d.product_id IS NULL THEN 'INSERT'
    WHEN d.row_hash IS DISTINCT FROM s.row_hash THEN 'UPDATE'
    ELSE 'NO_CHANGE'
  END AS change_type
FROM source_data s
LEFT JOIN current_dimension d ON s.id = d.product_id
WHERE d.product_id IS NULL OR d.row_hash IS DISTINCT FROM s.row_hash;

-- Expire the current rows that have changes
MERGE INTO `gold.dim_product` AS target
USING product_changes AS source
ON target.product_id = source.id
  AND target.is_current = TRUE
  AND source.change_type = 'UPDATE'
WHEN MATCHED THEN
  UPDATE SET
    valid_to = CURRENT_TIMESTAMP(),
    is_current = FALSE,
    updated_at = CURRENT_TIMESTAMP();

-- Insert new rows for both new products and changed products
INSERT INTO `gold.dim_product`
(product_sk, product_id, name, category, description, base_price, base_currency, valid_from, valid_to, is_current, row_hash, created_at, updated_at)
SELECT
  -- Generate a surrogate key using a sequence or hash
  FARM_FINGERPRINT(CONCAT(id, CAST(CURRENT_TIMESTAMP() AS STRING))) AS product_sk,
  id,
  name,
  category,
  description,
  base_price,
  currency,
  CURRENT_TIMESTAMP() AS valid_from,
  NULL AS valid_to,
  TRUE AS is_current,
  row_hash,
  CURRENT_TIMESTAMP() AS created_at,
  CURRENT_TIMESTAMP() AS updated_at
FROM product_changes
WHERE change_type IN ('INSERT', 'UPDATE');

