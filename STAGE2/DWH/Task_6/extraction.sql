-- Create sequences for all tables
CREATE SEQUENCE IF NOT EXISTS BL_3NF.category_id_seq;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.supplier_id_seq;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.product_id_seq;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.address_id_seq;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.customer_id_seq;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.store_id_seq;
----CREATE SEQUENCE IF NOT EXISTS BL_3NF.date_id_seq;--- deleted
CREATE SEQUENCE IF NOT EXISTS BL_3NF.promotion_id_seq;
CREATE SEQUENCE IF NOT EXISTS BL_3NF.transaction_id_seq;

-- Combining data from only one source and checking existence before inserting
-- Populate categories

WITH combined_categories AS (
    SELECT DISTINCT
        c.category AS CATEGORY_NAME,
        c.category AS SOURCE_ID,
        'sa_offline_sales' AS SOURCE_SYSTEM,
        'src_offline_sales' AS SOURCE_ENTITY
    FROM sa_offline_sales.src_offline_sales c
)
INSERT INTO BL_3NF.CE_CATEGORIES (
    category_id, category_name, source_id, source_entity, source_system
)
SELECT
    nextval('BL_3NF.category_id_seq') AS category_id,
    cc.CATEGORY_NAME,
    cc.SOURCE_ID,
    cc.SOURCE_ENTITY,
    cc.SOURCE_SYSTEM
FROM combined_categories cc
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_CATEGORIES
    WHERE source_id = cc.SOURCE_ID
      AND source_system = cc.SOURCE_SYSTEM
      AND source_entity = cc.SOURCE_ENTITY
);

COMMIT;

-- Populate Customers

WITH combined_customers AS (
    SELECT DISTINCT
        c.customer_id AS SOURCE_ID,
        c.customer_age::INTEGER AS CUSTOMER_AGE,
        o.customer_level AS CUSTOMER_LEVEL,
        c.customer_gender AS GENDER,
        c.customer_income::NUMERIC::INTEGER AS CUSTOMER_INCOME,
        'sa_offline_sales' AS SOURCE_SYSTEM,
        'src_offline_sales' AS SOURCE_ENTITY
    FROM sa_offline_sales.src_offline_sales c
    LEFT JOIN sa_online_sales.src_online_sales o 
        ON c.customer_id = o.customer_id
)
INSERT INTO BL_3NF.CE_CUSTOMER_SCD (
    customer_id, customer_age, customer_level, gender, customer_income, source_id, source_entity, source_system
)
SELECT
    nextval('BL_3NF.customer_id_seq') AS customer_id,
    cc.CUSTOMER_AGE,
    cc.CUSTOMER_LEVEL,
    cc.GENDER,
    cc.CUSTOMER_INCOME,
    cc.SOURCE_ID,
    cc.SOURCE_ENTITY,
    cc.SOURCE_SYSTEM
FROM combined_customers cc
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_CUSTOMER_SCD
    WHERE source_id = cc.SOURCE_ID
      AND source_system = cc.SOURCE_SYSTEM
      AND source_entity = cc.SOURCE_ENTITY
);

COMMIT;

-- Populate CE_PRODUCTS

ALTER TABLE BL_3NF.CE_PRODUCTS
  ALTER COLUMN unit_price TYPE NUMERIC(10,2);
  
WITH combined_products AS (
    SELECT
        c.product_id AS SOURCE_ID,
        c.product_name AS PRODUCT_NAME,
        c.category AS CATEGORY_NAME,
        c.unit_price::NUMERIC(10,2)  AS UNIT_PRICE,
        'sa_offline_sales'AS SOURCE_SYSTEM,
        'src_offline_sales' AS SOURCE_ENTITY
    FROM sa_offline_sales.src_offline_sales c
)
INSERT INTO BL_3NF.CE_PRODUCTS (
    product_id, 
    product_name, 
    category_id, 
    unit_price, 
    source_id, 
    source_entity, 
    source_system
)
SELECT
    nextval('BL_3NF.product_id_seq') AS product_id,
    cp.PRODUCT_NAME,
    (SELECT category_id 
       FROM BL_3NF.CE_CATEGORIES 
      WHERE category_name = cp.CATEGORY_NAME
      LIMIT 1
    ) AS CATEGORY_ID,
    cp.UNIT_PRICE,
    cp.SOURCE_ID,
    cp.SOURCE_ENTITY,
    cp.SOURCE_SYSTEM
FROM combined_products cp
WHERE NOT EXISTS (
    SELECT 1 
      FROM BL_3NF.CE_PRODUCTS 
     WHERE source_id = cp.SOURCE_ID
       AND source_system = cp.SOURCE_SYSTEM
       AND source_entity = cp.SOURCE_ENTITY
);

COMMIT;

-- Populate CE_STORES
WITH combined_stores AS (
    SELECT DISTINCT
        c.store_id AS SOURCE_ID,
        c.store_location AS STORE_LOCATION,
        c.state AS STATE,
        'sa_offline_sales' AS SOURCE_SYSTEM,
        'src_offline_sales' AS SOURCE_ENTITY
    FROM sa_offline_sales.src_offline_sales c
)
INSERT INTO BL_3NF.CE_STORES (
    store_id, store_location, state, source_id, source_entity, source_system
)
SELECT
    nextval('BL_3NF.store_id_seq') AS store_id,
    cs.STORE_LOCATION,
    cs.STATE,
    cs.SOURCE_ID,
    cs.SOURCE_ENTITY,
    cs.SOURCE_SYSTEM
FROM combined_stores cs
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_STORES
    WHERE source_id = cs.SOURCE_ID
      AND source_system = cs.SOURCE_SYSTEM
      AND source_entity = cs.SOURCE_ENTITY
);

COMMIT;

-- Populate CE_DATES
WITH combined_dates AS (
    SELECT DISTINCT
        c.transaction_date::date AS transaction_date,
        c.transaction_date        AS source_id,
        'sa_offline_sales'        AS source_system,
        'src_offline_sales'       AS source_entity
    FROM sa_offline_sales.src_offline_sales c
)
INSERT INTO BL_3NF.CE_DATES (
    date_id,
    transaction_date,
    source_id,
    source_entity,
    source_system
)
SELECT
    nextval('BL_3NF.date_id_seq') AS date_id,
    cd.transaction_date, 
    cd.source_id,
    cd.source_entity,
    cd.source_system
FROM combined_dates cd
WHERE NOT EXISTS (
    SELECT 1 
      FROM BL_3NF.CE_DATES d
     WHERE d.source_id     = cd.source_id
       AND d.source_system = cd.source_system
       AND d.source_entity = cd.source_entity
);

COMMIT;

-- Populate CE_PROMOTION

WITH combined_promotions AS (
    SELECT DISTINCT
        o.promotion_applied AS PROMOTION_APPLIED,
        o.promotion_applied AS SOURCE_ID,
        'sa_offline_sales' AS SOURCE_SYSTEM,
        'src_offline_sales' AS SOURCE_ENTITY
    FROM sa_online_sales.src_online_sales o 
)
INSERT INTO BL_3NF.CE_PROMOTION (
    promotion_id, promotion_applied, source_id, source_entity, source_system
)
SELECT
    nextval('BL_3NF.promotion_id_seq') AS promotion_id,
    cp.PROMOTION_APPLIED,
    cp.SOURCE_ID,
    cp.SOURCE_ENTITY,
    cp.SOURCE_SYSTEM
FROM combined_promotions cp
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_PROMOTION
    WHERE source_id = cp.SOURCE_ID
      AND source_system = cp.SOURCE_SYSTEM
      AND source_entity = cp.SOURCE_ENTITY
);

COMMIT;

---Populate Sales
WITH combined_sales AS (
    SELECT
        c.t_id AS source_id,
        cust.customer_id AS customer_id,
        st.store_id AS store_id,
        d.date_id AS date_id,
        p.product_id AS product_id,
        c.time::time AS time,
        promo.promotion_id AS promotion_id,
        c.unit_price::decimal(10,2) AS unit_price,
        c.quantity_sold::integer AS quantity_sold,
        'sa_offline_sales' AS source_system,
        'src_offline_sales' AS source_entity
    FROM sa_offline_sales.src_offline_sales c
    LEFT JOIN sa_online_sales.src_online_sales o
           ON c.customer_id = o.customer_id
    LEFT JOIN BL_3NF.CE_CUSTOMER_SCD cust
           ON cust.source_id = c.customer_id
          AND cust.source_system = 'sa_offline_sales'
          AND cust.source_entity = 'src_offline_sales'
    LEFT JOIN BL_3NF.CE_STORES st
           ON st.source_id = c.store_id
          AND st.source_system = 'sa_offline_sales'
          AND st.source_entity = 'src_offline_sales'
    LEFT JOIN BL_3NF.CE_DATES d
           ON d.source_id = c.transaction_date
          AND d.source_system = 'sa_offline_sales'
          AND d.source_entity = 'src_offline_sales'
    LEFT JOIN BL_3NF.CE_PRODUCTS p
           ON p.source_id = c.product_id
          AND p.source_system = 'sa_offline_sales'
          AND p.source_entity = 'src_offline_sales'
    LEFT JOIN BL_3NF.CE_PROMOTION promo
           ON promo.source_id = o.promotion_applied
          AND promo.source_system = 'sa_offline_sales'
          AND promo.source_entity = 'src_offline_sales'
)
INSERT INTO BL_3NF.CE_SALES_DD (
    t_id,
    customer_id,
    store_id,
    date_id,
    product_id,
    time,
    promotion_id,
    unit_price,
    quantity_sold,
    source_id,
    source_entity,
    source_system
)
SELECT
    nextval('BL_3NF.transaction_id_seq') AS transaction_id,
    cs.customer_id,
    cs.store_id,
    cs.date_id,
    cs.product_id,
    cs.time,
    cs.promotion_id,
    cs.unit_price,
    cs.quantity_sold,
    cs.source_id,
    cs.source_entity,
    cs.source_system
FROM combined_sales cs
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_SALES_DD dd
    WHERE dd.source_id = cs.source_id
      AND dd.source_system = cs.source_system
      AND dd.source_entity = cs.source_entity
);

COMMIT;
