-- SQL to generate data for DIM_DATE table
INSERT INTO `gold.dim_date` (
    date_key,
    full_date,
    year,
    quarter,
    month,
    month_name,
    day_of_month,
    day_of_week_name,
    is_weekend
)
SELECT
    -- Format: YYYYMMDD
    CAST(FORMAT_DATE('%Y%m%d', d) AS INT64) AS date_key,
    d AS full_date,
    EXTRACT(YEAR FROM d) AS year,
    EXTRACT(QUARTER FROM d) AS quarter,
    EXTRACT(MONTH FROM d) AS month,
    FORMAT_DATE('%B', d) AS month_name,
    EXTRACT(DAY FROM d) AS day_of_month,
    FORMAT_DATE('%A', d) AS day_of_week_name,
    -- Check if day is Saturday (7) or Sunday (1)
    EXTRACT(DAYOFWEEK FROM d) IN (1, 7) AS is_weekend
FROM
    UNNEST(GENERATE_DATE_ARRAY('2020-01-01', '2040-12-31', INTERVAL 1 DAY)) AS d;
