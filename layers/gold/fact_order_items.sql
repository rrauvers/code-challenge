-- SQL to insert data into FACT table
INSERT INTO `gold.fact_order_items` (
    order_item_id,
    customer_sk,
    product_sk,
    order_date_key,
    order_id,
    order_status,
    currency,
    quantity,
    unit_price,
    extended_amount,
    created_at
)
SELECT
    -- Fact Granularity ID
    oi.id AS order_item_id,

    -- Dimension Foreign Keys (SCD Type 2 Point-in-Time Match)
    dc.customer_sk,
    dp.product_sk,

    -- Date Dimension Key (YYYYMMDD Format)
    CAST(FORMAT_DATETIME('%Y%m%d', o.order_date) AS INT64) AS order_date_key,

    -- Degenerate Dimensions
    o.id AS order_id,
    o.status AS order_status,
    oi.currency,

    -- Additive Measures
    oi.quantity,
    oi.unit_price,
    CAST(oi.quantity * oi.unit_price AS NUMERIC) AS extended_amount,

    -- Metadata
    CURRENT_TIMESTAMP() AS created_at

FROM `silver.order_items` oi
INNER JOIN `silver.orders` o 
    ON oi.order_id = o.id

-- Point-in-Time Lookup for SCD Type 2 Customer Dimension
LEFT JOIN `gold.dim_customer` dc
    ON o.customer_id = dc.customer_id
   AND CAST(o.order_date AS TIMESTAMP) >= dc.valid_from
   AND (CAST(o.order_date AS TIMESTAMP) < dc.valid_to OR dc.valid_to IS NULL)

-- Point-in-Time Lookup for SCD Type 2 Product Dimension
LEFT JOIN `gold.dim_product` dp
    ON oi.product_id = dp.product_id
   AND CAST(o.order_date AS TIMESTAMP) >= dp.valid_from
   AND (CAST(o.order_date AS TIMESTAMP) < dp.valid_to OR dp.valid_to IS NULL);



