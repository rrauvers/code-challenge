CREATE TABLE `bronze.product_descriptions` (
  id INT64,
  name STRING,
  category STRING,
  description STRING,
  base_price NUMERIC,
  currency STRING DEFAULT 'USD',
  valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  valid_to TIMESTAMP
);