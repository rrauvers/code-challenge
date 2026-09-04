CREATE TABLE `silver.base_currency` (
  base STRING,
  date DATE,
  rates STRUCT<
    USD FLOAT64,
    EUR FLOAT64,
    GBP FLOAT64
  >
);