-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS BL_3NF;

-- Create procedure to create tables
CREATE OR REPLACE PROCEDURE bl_3nf.create_bl_3nf_and_tables_procedure()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Create Categories table
    CREATE TABLE IF NOT EXISTS BL_3NF.CE_CATEGORIES (
        category_id BIGINT PRIMARY KEY,
        category_name VARCHAR(15) NOT NULL,
        source_id VARCHAR(100) NOT NULL,
        source_entity VARCHAR(100) NOT NULL,
        source_system VARCHAR(100) NOT NULL
    );

    -- Create Suppliers table
    CREATE TABLE IF NOT EXISTS BL_3NF.CE_SUPPLIERS (
        supplier_id BIGINT PRIMARY KEY,
        source_id VARCHAR(100) NOT NULL,
        source_entity VARCHAR(100) NOT NULL,
        source_system VARCHAR(100) NOT NULL
    );

    -- Create Products table
    CREATE TABLE IF NOT EXISTS BL_3NF.CE_PRODUCTS (
        product_id BIGINT PRIMARY KEY,
        product_name VARCHAR(15) NOT NULL,
        category_id BIGINT REFERENCES BL_3NF.CE_CATEGORIES(category_id),
        unit_price INT NOT NULL,
        source_id VARCHAR(100) NOT NULL,
        source_entity VARCHAR(100) NOT NULL,
        source_system VARCHAR(100) NOT NULL
    );

    -- Create Customer SCD table
    CREATE TABLE IF NOT EXISTS BL_3NF.CE_CUSTOMER_SCD (
        customer_id BIGINT PRIMARY KEY,
        customer_age INT,
        customer_level VARCHAR(15),
        gender VARCHAR(10),
        customer_income INT,
        source_id VARCHAR(100) NOT NULL,
        source_entity VARCHAR(100) NOT NULL,
        source_system VARCHAR(100) NOT NULL
    );

    -- Create Stores table
    CREATE TABLE IF NOT EXISTS BL_3NF.CE_STORES (
        store_id BIGINT PRIMARY KEY,
        store_location VARCHAR(15) NOT NULL,
        state VARCHAR(5) NOT NULL,
        source_id VARCHAR(100) NOT NULL,
        source_entity VARCHAR(100) NOT NULL,
        source_system VARCHAR(100) NOT NULL
    );

    -- Create Dates table
    CREATE TABLE IF NOT EXISTS BL_3NF.CE_DATES (
        transaction_date DATE NOT NULL,
        source_id VARCHAR(100) NOT NULL,
        source_entity VARCHAR(100) NOT NULL,
        source_system VARCHAR(100) NOT NULL,
        PRIMARY KEY (transaction_date, source_id, source_entity, source_system)
    );

    -- Create Promotion table
    CREATE TABLE IF NOT EXISTS BL_3NF.CE_PROMOTION (
        promotion_id BIGINT PRIMARY KEY,
        promotion_applied VARCHAR(10),
        source_id VARCHAR(100) NOT NULL,
        source_entity VARCHAR(100) NOT NULL,
        source_system VARCHAR(100) NOT NULL
    );
    -- Create Sales table
    CREATE TABLE IF NOT EXISTS BL_3NF.CE_SALES (
        t_id BIGINT PRIMARY KEY,
        customer_id BIGINT REFERENCES BL_3NF.CE_CUSTOMER_SCD(customer_id),
        store_id BIGINT REFERENCES BL_3NF.CE_STORES(store_id),
        product_id BIGINT REFERENCES BL_3NF.CE_PRODUCTS(product_id),
        time TIME NOT NULL,
        promotion_id BIGINT REFERENCES BL_3NF.CE_PROMOTION(promotion_id),
        unit_price DECIMAL(10,2) NOT NULL,
        transaction_date DATE,
        quantity_sold INT NOT NULL,
        source_id VARCHAR(100) NOT NULL,
        source_entity VARCHAR(100) NOT NULL,
        source_system VARCHAR(100) NOT NULL
    );
    -- Raise success notice
    RAISE NOTICE 'BL_3NF tables are created';
EXCEPTION
    WHEN OTHERS THEN
        -- Raise exception to propagate the error
        RAISE NOTICE 'BL_3NF tables are not created: %', SQLERRM;
END;
$$;

-- Call the procedure to create the tables
CALL pbl_3nf.create_bl_3nf_and_tables_procedure();
