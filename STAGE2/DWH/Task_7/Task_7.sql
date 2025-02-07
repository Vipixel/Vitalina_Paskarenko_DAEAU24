BEGIN;

CREATE SCHEMA IF NOT EXISTS BL_DM;

------------------------------------------------------------------------------
-- DIM_CUSTOMER_SCD

CREATE TABLE IF NOT EXISTS BL_DM.DIM_CUSTOMER_SCD (
    customer_surr_id  BIGINT       NOT NULL PRIMARY KEY,
    customer_id       BIGINT,
    customer_src_id   VARCHAR(100),
    customer_name     VARCHAR(50),
    customer_age      INT,
    customer_level    VARCHAR(50),
    gender            VARCHAR(10),
    customer_income   INT,
    start_dt          DATE,
    end_dt            DATE,
    is_active         CHAR(1),
    insert_dt         DATE,
    update_dt         DATE
);

-- Insert default row 
INSERT INTO BL_DM.DIM_CUSTOMER_SCD (
    customer_surr_id,
    customer_id,
    customer_src_id,
    customer_name,
    customer_age,
    customer_level,
    gender,
    customer_income,
    start_dt,
    end_dt,
    is_active,
    insert_dt,
    update_dt
)
SELECT
    0,
    -1,
    COALESCE(NULL, 'UNKNOWN'),
    'Unknown',
    -1,
    'Unknown',
    'U',
    -1,
    '1900-01-01',
    '1900-01-01',
    'N',
    CURRENT_DATE,
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM BL_DM.DIM_CUSTOMER_SCD
    WHERE customer_surr_id = 0
);


------------------------------------------------------------------------------
-- DIM_PRODUCT_SUPPLIER

CREATE TABLE IF NOT EXISTS BL_DM.DIM_PRODUCT_SUPPLIER (
    product_surr_id   BIGINT       NOT NULL PRIMARY KEY,
    product_id        BIGINT,
    product_src_id    VARCHAR(100),
    product_name      VARCHAR(50),
    category_id       BIGINT,
    category_name     VARCHAR(50),
    unit_price        DECIMAL(10,2),
    supplier_id       BIGINT,
    supplier_src_id   VARCHAR(100),
    supplier_lead     INT,
    insert_dt         DATE,
    update_dt         DATE
);

-- Default row
INSERT INTO BL_DM.DIM_PRODUCT_SUPPLIER (
    product_surr_id,
    product_id,
    product_src_id,
    product_name,
    category_id,
    category_name,
    unit_price,
    supplier_id,
    supplier_src_id,
    supplier_lead,
    insert_dt,
    update_dt
)
SELECT
    0,
    -1,
    'UNKNOWN',
    'Unknown Product',
    -1,
    'Unknown Category',
    0.00,
    -1,
    'UNKNOWN',
    -1,
    CURRENT_DATE,
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM BL_DM.DIM_PRODUCT_SUPPLIER
    WHERE product_surr_id = 0
);

------------------------------------------------------------------------------
-- DIM_STORES

CREATE TABLE IF NOT EXISTS BL_DM.DIM_STORES (
    store_surr_id   BIGINT      NOT NULL PRIMARY KEY,
    store_id        BIGINT,
    store_src_id    VARCHAR(100),
    store_location  VARCHAR(50),
    state           VARCHAR(2),
    insert_dt       DATE,
    update_dt       DATE
);

-- Default row
INSERT INTO BL_DM.DIM_STORES (
    store_surr_id,
    store_id,
    store_src_id,
    store_location,
    state,
    insert_dt,
    update_dt
)
SELECT
    0,
    -1,
    'UNKNOWN',
    'Unknown Store',
    '??',
    CURRENT_DATE,
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM BL_DM.DIM_STORES
    WHERE store_surr_id = 0
);

-----------------------------------------------------------------------------
-- DIM_DATES

CREATE TABLE IF NOT EXISTS BL_DM.DIM_DATES (
    date_dt      DATE  NOT NULL PRIMARY KEY,
    day_of_week  INT,
    day_of_month INT,
    day_of_year  INT,
    week_of_year INT,
    month        INT,
    quarter      INT,
    year         INT
);

-- Default row 

INSERT INTO BL_DM.DIM_DATES (
    date_dt,
    day_of_week,
    day_of_month,
    day_of_year,
    week_of_year,
    month,
    quarter,
    year
)
SELECT
    '1900-01-01',
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1
WHERE NOT EXISTS (
    SELECT 1 FROM BL_DM.DIM_DATES
    WHERE date_dt = '1900-01-01'
);


------------------------------------------------------------------------------
-- DIM_PROMOTION

CREATE TABLE IF NOT EXISTS BL_DM.DIM_PROMOTION (
    promotion_surr_id  BIGINT       NOT NULL PRIMARY KEY,
    promotion_id       BIGINT,
    promotion_src_id   VARCHAR(100),
    promotion_applied  VARCHAR(50),
    insert_dt          DATE,
    update_dt          DATE
);

-- Default row
INSERT INTO BL_DM.DIM_PROMOTION (
    promotion_surr_id,
    promotion_id,
    promotion_src_id,
    promotion_applied,
    insert_dt,
    update_dt
)
SELECT
    0,
    -1,
    'UNKNOWN',
    'Unknown Promo',
    CURRENT_DATE,
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM BL_DM.DIM_PROMOTION
    WHERE promotion_surr_id = 0
);

------------------------------------------------------------------------------
-- FCT_SALES_DD

CREATE TABLE IF NOT EXISTS BL_DM.FCT_SALES_DD (
    transaction_id     BIGINT    NOT NULL,
    transaction_src_id VARCHAR(100),
    customer_surr_id   BIGINT,
    store_surr_id      BIGINT,
    date_dt            DATE      NOT NULL,
    product_surr_id    BIGINT,
    time               TIME,
    promotion_surr_id  BIGINT,
    quantity_sold      INT,
    total_cost         DECIMAL(15,2),
    source_entity      VARCHAR(100),
    source_system      VARCHAR(100),
	
    CONSTRAINT fk_sales_customer
       FOREIGN KEY (customer_surr_id)
       REFERENCES BL_DM.DIM_CUSTOMER_SCD(customer_surr_id),
	   
    CONSTRAINT fk_sales_store
       FOREIGN KEY (store_surr_id)
       REFERENCES BL_DM.DIM_STORES(store_surr_id),

    CONSTRAINT fk_sales_date
       FOREIGN KEY (date_dt)
       REFERENCES BL_DM.DIM_DATES(date_dt),

    CONSTRAINT fk_sales_product
       FOREIGN KEY (product_surr_id)
       REFERENCES BL_DM.DIM_PRODUCT_SUPPLIER(product_surr_id),

    CONSTRAINT fk_sales_promo
       FOREIGN KEY (promotion_surr_id)
       REFERENCES BL_DM.DIM_PROMOTION(promotion_surr_id)
);

COMMIT;

