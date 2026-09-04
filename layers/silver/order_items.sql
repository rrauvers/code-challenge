CREATE TABLE `silver.order_items` (
    id          INT64,
    order_id    INT64,
    product_id  INT64,
    quantity    INT64,
    unit_price  NUMERIC,
    currency    STRING
);