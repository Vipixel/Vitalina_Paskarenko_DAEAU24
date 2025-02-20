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
        off.category AS category_name,
        off.category AS source_id,
        'sa_offline_sales' AS source_system,
        'src_offline_sales'AS source_entity
    FROM sa_offline_sales.src_offline_sales off
    
    UNION ALL

    SELECT DISTINCT
        onl.category AS category_name,
        onl.category AS source_id,
        'sa_online_sales' AS source_system,
        'src_online_sales' AS source_entity
    FROM sa_online_sales.src_online_sales onl
)
INSERT INTO BL_3NF.CE_CATEGORIES (
    category_id,
    category_name,
    source_id,
    source_entity,
    source_system
)
SELECT
    nextval('BL_3NF.category_id_seq'),
    cc.category_name,
    cc.source_id,
    cc.source_entity,
    cc.source_system
FROM combined_categories cc
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_CATEGORIES existing
    WHERE existing.source_id     = cc.source_id
      AND existing.source_system = cc.source_system
      AND existing.source_entity = cc.source_entity
);

COMMIT;

-- Populate Customers

WITH combined_customers AS (
    SELECT DISTINCT
        off.customer_id AS source_id,
        off.customer_age::INTEGER AS customer_age,
        off.customer_gender AS gender,
        off.customer_income::NUMERIC::INTEGER AS customer_income,
        NULL AS customer_level,
        'sa_offline_sales' AS source_system,
        'src_offline_sales' AS source_entity
    FROM sa_offline_sales.src_offline_sales off
    
    UNION ALL
    
    SELECT DISTINCT
        onl.customer_id AS source_id,
        NULL::INTEGER AS customer_age, --- it is shows errore so I changed data type
        NULL::TEXT AS gender, --- it is shows errore so I changed data type
        NULL::INTEGER AS customer_income, --- it is shows errore so I changed data type
        onl.customer_level AS customer_level,
        'sa_online_sales' AS source_system,
        'src_online_sales' AS source_entity
    FROM sa_online_sales.src_online_sales onl
)
INSERT INTO BL_3NF.CE_CUSTOMER_SCD (
    customer_id,
    customer_age,
    gender,
    customer_income,
    customer_level,
    source_id,
    source_entity,
    source_system
)
SELECT
    nextval('BL_3NF.customer_id_seq'),
    cc.customer_age,
    cc.gender,
    cc.customer_income,
    cc.customer_level,
    cc.source_id,
    cc.source_entity,
    cc.source_system
FROM combined_customers cc
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_CUSTOMER_SCD existing
    WHERE existing.source_id     = cc.source_id
      AND existing.source_system = cc.source_system
      AND existing.source_entity = cc.source_entity
);

COMMIT;


-- Populate CE_PRODUCTS

ALTER TABLE BL_3NF.CE_PRODUCTS
ALTER COLUMN unit_price TYPE NUMERIC(10,2);

WITH combined_products AS (
    SELECT DISTINCT
        off.product_id                  AS source_id,
        off.product_name                AS product_name,
        off.category                    AS category_name,
        off.unit_price::NUMERIC(10,2)   AS unit_price,
        'sa_offline_sales'             AS source_system,
        'src_offline_sales'            AS source_entity
    FROM sa_offline_sales.src_offline_sales off
    
    UNION ALL
    
    SELECT DISTINCT
        onl.product_id                  AS source_id,
        onl.product_name                AS product_name,
        onl.category                    AS category_name,
        onl.unit_price::NUMERIC(10,2)   AS unit_price,
        'sa_online_sales'              AS source_system,
        'src_online_sales'             AS source_entity
    FROM sa_online_sales.src_online_sales onl
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
    nextval('BL_3NF.product_id_seq'),
    cp.product_name,
    (
      SELECT category_id
      FROM BL_3NF.CE_CATEGORIES cat
      WHERE cat.source_id     = cp.category_name
        AND cat.source_system = cp.source_system
        AND cat.source_entity = cp.source_entity
      LIMIT 1
    ) AS category_id,
    cp.unit_price,
    cp.source_id,
    cp.source_entity,
    cp.source_system
FROM combined_products cp
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_PRODUCTS existing
    WHERE existing.source_id     = cp.source_id
      AND existing.source_system = cp.source_system
      AND existing.source_entity = cp.source_entity
);

COMMIT;


-- Populate CE_STORES

WITH combined_stores AS (
    SELECT DISTINCT
        off.store_id AS source_id,
        off.store_location AS store_location,
        off.state AS state,
        'sa_offline_sales' AS source_system,
        'src_offline_sales'AS source_entity
    FROM sa_offline_sales.src_offline_sales off
    
    UNION ALL
    
    SELECT DISTINCT
        onl.store AS source_id,
        onl.store_location AS store_location,
        NULL AS state,
        'sa_online_sales' AS source_system,
        'src_online_sales' AS source_entity
    FROM sa_online_sales.src_online_sales onl
)
INSERT INTO BL_3NF.CE_STORES (
    store_id, 
	store_location, 
	state,
    source_id,
	source_entity, 
	source_system
)
SELECT
    nextval('BL_3NF.store_id_seq'),
    cs.store_location,
    COALESCE(cs.state, 'ONLINE') AS state,
    cs.source_id,
    cs.source_entity,
    cs.source_system
FROM combined_stores cs
WHERE NOT EXISTS (
    SELECT 1 
    FROM BL_3NF.CE_STORES existing
    WHERE existing.source_id     = cs.source_id
      AND existing.source_system = cs.source_system
      AND existing.source_entity = cs.source_entity
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
    transaction_date,
    source_id,
    source_entity,
    source_system
)
SELECT
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
        onl.promotion_applied    AS promotion_applied,
        onl.promotion_applied    AS source_id,
        'sa_online_sales'        AS source_system,
        'src_online_sales'       AS source_entity
    FROM sa_online_sales.src_online_sales onl
    WHERE onl.promotion_applied IS NOT NULL
)
INSERT INTO BL_3NF.CE_PROMOTION (
    promotion_id,
    promotion_applied,
    source_id,
    source_entity,
    source_system
)
SELECT
    nextval('BL_3NF.promotion_id_seq'),
    cp.promotion_applied,
    cp.source_id,
    cp.source_entity,
    cp.source_system
FROM combined_promotions cp
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_PROMOTION existing
    WHERE existing.source_id     = cp.source_id
      AND existing.source_system = cp.source_system
      AND existing.source_entity = cp.source_entity
);

COMMIT;

---Populate Suppliers

WITH combined_suppliers AS (
    SELECT
        off.supplier_id AS source_id,
        'sa_offline_sales' AS source_system,
        'src_offline_sales' AS source_entity
    FROM sa_offline_sales.src_offline_sales off
    UNION ALL
    SELECT
        onl.supplier_id AS source_id,
        'sa_online_sales' AS source_system,
        'src_online_sales' AS source_entity
    FROM sa_online_sales.src_online_sales onl
)
INSERT INTO BL_3NF.CE_SUPPLIERS (
    supplier_id,
    source_id,
    source_entity,
    source_system
)
SELECT
    nextval('BL_3NF.supplier_id_seq') AS supplier_id,
    cs.source_id,
    cs.source_entity,
    cs.source_system
FROM combined_suppliers cs
WHERE NOT EXISTS (
    SELECT 1 
    FROM BL_3NF.CE_SUPPLIERS existing
    WHERE existing.source_id     = cs.source_id
      AND existing.source_system = cs.source_system
      AND existing.source_entity = cs.source_entity
);
COMMIT;

---Populate Sales

WITH combined_sales AS (
    SELECT
        off.t_id AS source_id,
        off.transaction_date::DATE AS transaction_date,
        off.time::TIME AS time_of_day,
        off.quantity_sold::INTEGER AS quantity_sold,
        off.unit_price::NUMERIC(10,2) AS unit_price,
        'sa_offline_sales' AS source_system,
        'src_offline_sales' AS source_entity,
        cust.customer_id AS dim_customer_id,
        st.store_id AS dim_store_id,
        prod.product_id AS dim_product_id,
        NULL AS dim_promotion_id
    FROM sa_offline_sales.src_offline_sales off
    LEFT JOIN BL_3NF.CE_CUSTOMER_SCD cust
           ON cust.source_id     = off.customer_id
          AND cust.source_system = 'sa_offline_sales'
          AND cust.source_entity = 'src_offline_sales'
    LEFT JOIN BL_3NF.CE_STORES st
           ON st.source_id       = off.store_id
          AND st.source_system   = 'sa_offline_sales'
          AND st.source_entity   = 'src_offline_sales'
    LEFT JOIN BL_3NF.CE_PRODUCTS prod
           ON prod.source_id     = off.product_id
          AND prod.source_system = 'sa_offline_sales'
          AND prod.source_entity = 'src_offline_sales'
    UNION ALL
    SELECT
        onl.transaction_id AS source_id,
        TO_DATE(onl.month || '-' || onl.day || '-' || onl.year, 'MM-DD-YYYY') AS transaction_date,
        '00:00:00'::TIME AS time_of_day,
        onl.quantity_sold::INTEGER AS quantity_sold,
        onl.unit_price::NUMERIC(10,2) AS unit_price,
        'sa_online_sales' AS source_system,
        'src_online_sales' AS source_entity,
        cust.customer_id AS dim_customer_id,
        st.store_id AS dim_store_id,
        prod.product_id AS dim_product_id,
        promo.promotion_id AS dim_promotion_id
        
    FROM sa_online_sales.src_online_sales onl
    
    LEFT JOIN BL_3NF.CE_CUSTOMER_SCD cust
           ON cust.source_id     = onl.customer_id
          AND cust.source_system = 'sa_online_sales'
          AND cust.source_entity = 'src_online_sales'
          
    LEFT JOIN BL_3NF.CE_STORES st
           ON st.source_id       = onl.store
          AND st.source_system   = 'sa_online_sales'
          AND st.source_entity   = 'src_online_sales'
          
    LEFT JOIN BL_3NF.CE_PRODUCTS prod
           ON prod.source_id     = onl.product_id
          AND prod.source_system = 'sa_online_sales'
          AND prod.source_entity = 'src_online_sales'
          
    LEFT JOIN BL_3NF.CE_PROMOTION promo
           ON promo.source_id     = onl.promotion_applied
          AND promo.source_system = 'sa_online_sales'
          AND promo.source_entity = 'src_online_sales'
)
INSERT INTO BL_3NF.CE_SALES (
    t_id,
    transaction_date,
    time,
    customer_id,
    store_id,
    product_id,
    promotion_id,
    unit_price,
    quantity_sold,
    source_id,
    source_system,
    source_entity
)
SELECT
    nextval('BL_3NF.transaction_id_seq') AS t_id,
    cs.transaction_date,
    cs.time_of_day,
    cs.dim_customer_id,
    cs.dim_store_id,
    cs.dim_product_id,
    cs.dim_promotion_id,
    cs.unit_price,
    cs.quantity_sold,
    cs.source_id,
    cs.source_system,
    cs.source_entity
FROM combined_sales cs
WHERE NOT EXISTS (
    SELECT 1 
    FROM BL_3NF.CE_SALES existing
    WHERE existing.source_id     = cs.source_id
      AND existing.source_system = cs.source_system
      AND existing.source_entity = cs.source_entity
);

COMMIT;
