-- Create BL_DM schema if not exists
CREATE SCHEMA IF NOT EXISTS BL_DM;

-- Create procedure to create dimension and fact tables
CREATE OR REPLACE PROCEDURE bl_dm.create_dim_and_fct_tables_procedure()
LANGUAGE plpgsql
AS $$
BEGIN
    ------------------------------------------------------------------------------
    -- DIM_CUSTOMER_SCD
    CREATE TABLE IF NOT EXISTS BL_DM.DIM_CUSTOMER_SCD (
        customer_surr_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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
    
    ------------------------------------------------------------------------------
    -- DIM_PRODUCT_SUPPLIER
    CREATE TABLE IF NOT EXISTS BL_DM.DIM_PRODUCT_SUPPLIER (
        product_surr_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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
    
    ------------------------------------------------------------------------------
    -- DIM_STORES
    CREATE TABLE IF NOT EXISTS BL_DM.DIM_STORES (
        store_surr_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        store_id        BIGINT,
        store_src_id    VARCHAR(100),
        store_location  VARCHAR(50),
        state           VARCHAR(2),
        insert_dt       DATE,
        update_dt       DATE
    );
    
    ------------------------------------------------------------------------------
    -- DIM_DATES
    CREATE TABLE IF NOT EXISTS BL_DM.DIM_DATES (
        date_dt      DATE PRIMARY KEY,
        day_of_week  INT,
        day_of_month INT,
        day_of_year  INT,
        week_of_year INT,
        month        INT,
        quarter      INT,
        year         INT
    );
    
    ------------------------------------------------------------------------------
    -- DIM_PROMOTION
    CREATE TABLE IF NOT EXISTS BL_DM.DIM_PROMOTION (
        promotion_surr_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        promotion_id       BIGINT,
        promotion_src_id   VARCHAR(100),
        promotion_applied  VARCHAR(50),
        insert_dt          DATE,
        update_dt          DATE
    );
    
    ------------------------------------------------------------------------------
    -- FCT_SALES_DD
    CREATE TABLE IF NOT EXISTS BL_DM.FCT_SALES_DD (
        transaction_id     BIGINT NOT NULL,
        transaction_src_id VARCHAR(100),
        customer_surr_id   BIGINT REFERENCES BL_DM.DIM_CUSTOMER_SCD(customer_surr_id),
        store_surr_id      BIGINT REFERENCES BL_DM.DIM_STORES(store_surr_id),
        transaction_date   DATE,
        product_surr_id    BIGINT REFERENCES BL_DM.DIM_PRODUCT_SUPPLIER(product_surr_id),
        time               TIME,
        promotion_surr_id  BIGINT REFERENCES BL_DM.DIM_PROMOTION(promotion_surr_id),
        quantity_sold      INT,
        total_cost         DECIMAL(15,2),
        source_entity      VARCHAR(100),
        source_system      VARCHAR(100)
    );
    
    RAISE NOTICE 'BL_DM tables created successfully';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating BL_DM tables: %', SQLERRM;
END;
$$;

-- Create procedure to insert default values
CREATE OR REPLACE PROCEDURE bl_dm.insert_default_values_procedure()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Default row for DIM_CUSTOMER_SCD
    INSERT INTO BL_DM.DIM_CUSTOMER_SCD (
        customer_id, customer_src_id, customer_name, customer_age, customer_level, 
        gender, customer_income, start_dt, end_dt, is_active, insert_dt, update_dt
    )
    SELECT -1, 'UNKNOWN', 'Unknown', -1, 'Unknown', 'U', -1, '1900-01-01', '1900-01-01', 'N', CURRENT_DATE, CURRENT_DATE
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_DM.DIM_CUSTOMER_SCD WHERE customer_id = -1
    );
    
    -- Default row for DIM_PRODUCT_SUPPLIER
    INSERT INTO BL_DM.DIM_PRODUCT_SUPPLIER (
        product_id, product_src_id, product_name, category_id, category_name, unit_price, 
        supplier_id, supplier_src_id, supplier_lead, insert_dt, update_dt
    )
    SELECT -1, 'UNKNOWN', 'Unknown Product', -1, 'Unknown Category', 0.00, -1, 'UNKNOWN', -1, CURRENT_DATE, CURRENT_DATE
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_DM.DIM_PRODUCT_SUPPLIER WHERE product_id = -1
    );
    
    -- Default row for DIM_STORES
    INSERT INTO BL_DM.DIM_STORES (
        store_id, store_src_id, store_location, state, insert_dt, update_dt
    )
    SELECT -1, 'UNKNOWN', 'Unknown Store', '??', CURRENT_DATE, CURRENT_DATE
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_DM.DIM_STORES WHERE store_id = -1
    );
    
    -- Default row for DIM_PROMOTION
    INSERT INTO BL_DM.DIM_PROMOTION (
        promotion_id, promotion_src_id, promotion_applied, insert_dt, update_dt
    )
    SELECT -1, 'UNKNOWN', 'Unknown Promo', CURRENT_DATE, CURRENT_DATE
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_DM.DIM_PROMOTION WHERE promotion_id = -1
    );
    
    RAISE NOTICE 'Default values inserted successfully';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inserting default values: %', SQLERRM;
END;
$$;

-- Call procedures
CALL bl_dm.create_dim_and_fct_tables_procedure();
CALL bl_dm.insert_default_values_procedure();