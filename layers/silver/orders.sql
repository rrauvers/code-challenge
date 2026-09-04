CREATE TABLE `silver.orders` (
    id            INT64,
    customer_id   INT64,
    order_date    DATETIME,
    total_amount  NUMERIC,
    currency      STRING,
    status        STRING,
    valid_from    TIMESTAMP DEFAULT CURRENT_TIMESTAMP() ,
    valid_to      TIMESTAMP
)
-- Partitioning by order_date improves query performance and cost efficiency
PARTITION BY DATE(order_date);