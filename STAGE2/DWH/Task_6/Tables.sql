CREATE SCHEMA IF NOT EXISTS BL_3NF;

-- Creating Tables

CREATE TABLE IF NOT EXISTS BL_3NF.CE_CATEGORIES (
    category_id BIGINT PRIMARY KEY,
    category_name VARCHAR(15) NOT NULL,
    source_id VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    source_system VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_SUPPLIERS (
    supplier_id BIGINT PRIMARY KEY,
    source_id VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    source_system VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_PRODUCTS (
    product_id BIGINT PRIMARY KEY,
    product_name VARCHAR(15) NOT NULL,
    category_id INT REFERENCES BL_3NF.CE_CATEGORIES(category_id),
    unit_price INT NOT NULL,
    source_id VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    source_system VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_ADDRESSES (
    address_id BIGINT PRIMARY KEY,
    state VARCHAR(5) NOT NULL,
    street VARCHAR(20),
    postal_n VARCHAR(8),
    source_id VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    source_system VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_CUSTOMER_SCD (
    customer_id BIGINT PRIMARY KEY,
    customer_name VARCHAR(15) NOT NULL,
    customer_age INT,
    customer_level VARCHAR(15),
    gender VARCHAR(10),
    customer_income INT,
    address_id INT REFERENCES BL_3NF.CE_ADDRESSES(address_id),
    source_id VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    source_system VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_STORES (
    store_id BIGINT PRIMARY KEY,
    store_location VARCHAR(15) NOT NULL,
    state VARCHAR(5) NOT NULL,
    source_id VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    source_system VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_DATES (
    date_id BIGINT PRIMARY KEY,
    transaction_date DATE NOT NULL,
    source_id VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    source_system VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_PROMOTION (
    promotion_id BIGINT PRIMARY KEY,
    promotion_applied VARCHAR(10),
    source_id VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    source_system VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS BL_3NF.CE_SALES_DD (
    transaction_id BIGINT PRIMARY KEY,
    customer_id INT REFERENCES BL_3NF.CE_CUSTOMER_SCD(customer_id),
    store_id INT REFERENCES BL_3NF.CE_STORES(store_id),
    date_id INT REFERENCES BL_3NF.CE_DATES(date_id),
    product_id INT REFERENCES BL_3NF.CE_PRODUCTS(product_id),
    time TIME NOT NULL,
    promotion_id INT REFERENCES BL_3NF.CE_PROMOTION(promotion_id),
    unit_price DECIMAL(10,2) NOT NULL,
    quantity_sold INT NOT NULL,
    source_id VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    source_system VARCHAR(100) NOT NULL
);