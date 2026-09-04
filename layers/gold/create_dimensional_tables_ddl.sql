-- Customer Dimension
CREATE TABLE `gold.dim_customer` (
    customer_sk       INT64,       -- Surrogate Key
    customer_id       INT64,       -- Natural/Business Key
    name              STRING,
    email             STRING,
    country           STRING,
    registration_date DATETIME,
    valid_from        TIMESTAMP,   -- For SCD Type 2 tracking
    valid_to          TIMESTAMP,
    is_current        BOOL,
    -- Metadata
    row_hash          STRING,      -- Hash of tracked columns for change detection
    created_at        TIMESTAMP,
    updated_at        TIMESTAMP
);

-- Product Dimension
CREATE TABLE `gold.dim_product` (
    product_sk        INT64,       -- Surrogate Key
    product_id        INT64,       -- Natural/Business Key
    name              STRING,
    category          STRING,
    description       STRING,
    base_price        NUMERIC,
    base_currency     STRING,
    valid_from        TIMESTAMP,   -- SCD Type 2 tracking
    valid_to          TIMESTAMP,
    is_current        BOOL,
    -- Metadata
    row_hash          STRING,      -- Hash of tracked columns for change detection
    created_at        TIMESTAMP,
    updated_at        TIMESTAMP
)

-- Date Dimension
CREATE TABLE `gold.dim_date` (
    date_key          INT64,       -- Format: YYYYMMDD (e.g., 20260902)
    full_date         DATE,
    year              INT64,
    quarter           INT64,
    month             INT64,
    month_name        STRING,
    day_of_month      INT64,
    day_of_week_name  STRING,
    is_weekend        BOOL
);

-- Currency Rate Dimension
CREATE TABLE `gold.dim_currency_rate` (
    currency_rate_sk  INT64,       -- Surrogate Key
    rate_date         DATE,        -- Joins to dim_date or fact date_key
    base_currency     STRING,      -- e.g., 'USD'
    usd_rate          FLOAT64,
    eur_rate          FLOAT64,
    gbp_rate          FLOAT64
);

-- Fact Order Items
CREATE TABLE `gold.fact_order_items` (
    -- Surrogate Foreign Keys (Dimension Joins)
    order_item_id        INT64,     -- Primary Key at line item grain
    customer_sk          INT64,     -- FK to dim_customer
    product_sk           INT64,     -- FK to dim_product
    order_date_key       INT64,     -- FK to dim_date (YYYYMMDD)
    
    -- Degenerate Dimensions (Header Context)
    order_id             INT64,     -- Operational Order Header ID
    order_status         STRING,    -- Status from silver.orders
    currency             STRING,    -- Transaction currency
    
    -- Additive Measures
    quantity             INT64,
    unit_price           NUMERIC,
    extended_amount      NUMERIC,   -- Derived: (quantity * unit_price)
    
    -- Metadata / ETL
    created_at           TIMESTAMP
)
PARTITION BY RANGE_BUCKET(order_date_key, GENERATE_ARRAY(20200101, 20301231, 10000))
CLUSTER BY customer_sk, product_sk;

