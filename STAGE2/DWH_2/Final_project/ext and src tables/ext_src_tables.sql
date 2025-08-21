-- Create schemas for offline and online sales
CREATE SCHEMA IF NOT EXISTS sa_offline_sales;
CREATE SCHEMA IF NOT EXISTS sa_online_sales;

CREATE EXTENSION IF NOT EXISTS file_fdw SCHEMA sa_offline_sales;
CREATE EXTENSION IF NOT EXISTS file_fdw SCHEMA sa_online_sales;


CREATE SERVER IF NOT EXISTS sa_offline_sales_server FOREIGN DATA WRAPPER file_fdw;

CREATE SERVER IF NOT EXISTS sa_online_sales_server FOREIGN DATA WRAPPER file_fdw;


-- Define the foreign table for offline sales
CREATE FOREIGN TABLE IF NOT EXISTS sa_offline_sales.ext_offline_sales (
  t_id VARCHAR(2550),
  customer_id VARCHAR(2550),
  product_id VARCHAR(2550),
  product_name VARCHAR(2550),
  category VARCHAR(255),
  quantity_sold VARCHAR(2550),
  unit_price VARCHAR(2550),
  transaction_date VARCHAR(2550),
  time VARCHAR(2550),
  store_id VARCHAR(2550),
  store_location VARCHAR(2550),
  state VARCHAR(2500),
  supplier_id VARCHAR(2550),
  supplier_lead VARCHAR(2550),
  customer_age VARCHAR(2550),
  customer_gender VARCHAR(2550),
  customer_income VARCHAR(2550),
  payment_method VARCHAR(2550)
)
SERVER sa_offline_sales_server
OPTIONS (
    filename '/Users/pixel/Desktop/EPAM_STAGE2/offline_s.csv',
    format 'csv',
    header 'true',
    delimiter ',',
    quote '"',
    null 'NULL',
    encoding 'UTF8'
);

-- Define the foreign table for online sales
CREATE FOREIGN TABLE IF NOT EXISTS sa_online_sales.ext_online_sales (
  transaction_id VARCHAR(2550),
  customer_id VARCHAR(2550),
  product_id VARCHAR(2550),
  product_name VARCHAR(2550),
  category VARCHAR(2550),
  quantity_sold VARCHAR(2550),
  unit_price VARCHAR(2550),
  day VARCHAR(2550),
  month VARCHAR(2550),
  year VARCHAR(2550),
  store VARCHAR(2550),
  store_location VARCHAR(2550),
  supplier_id VARCHAR(2550),
  customer_level VARCHAR(2550),
  promotion_applied VARCHAR(2550)
)
SERVER sa_online_sales_server
OPTIONS (
    filename '/Users/pixel/Desktop/EPAM_STAGE2/Online_sale.csv',
    format 'csv',
    header 'true',
    delimiter ',',
    quote '"',
    null 'NULL',
    encoding 'UTF8'
);

-- Create source table for offline sales
CREATE TABLE IF NOT EXISTS sa_offline_sales.src_offline_sales (
  t_id VARCHAR(2550),
  customer_id VARCHAR(2550),
  product_id VARCHAR(2550),
  product_name VARCHAR(2550),
  category VARCHAR(2550),
  quantity_sold VARCHAR(2550),
  unit_price VARCHAR(2550),
  transaction_date VARCHAR(2550),
  time VARCHAR(2550),
  store_id VARCHAR(2550),
  store_location VARCHAR(2550),
  state VARCHAR(2550),
  supplier_id VARCHAR(2550),
  supplier_lead VARCHAR(2550),
  customer_age VARCHAR(2550),
  customer_gender VARCHAR(2550),
  customer_income VARCHAR(2550),
  payment_method VARCHAR(2550)
);

-- Create source table for online sales
CREATE TABLE IF NOT EXISTS sa_online_sales.src_online_sales (
  transaction_id VARCHAR(2550),
  customer_id VARCHAR(255),
  product_id VARCHAR(255),
  product_name VARCHAR(255),
  category VARCHAR(255),
  quantity_sold VARCHAR(2550),
  unit_price VARCHAR(2550),
  day VARCHAR(2550),
  month VARCHAR(2550),
  year VARCHAR(2550),
  store VARCHAR(2550),
  store_location VARCHAR(2550),
  supplier_id VARCHAR(2550),
  customer_level VARCHAR(2550),
  promotion_applied VARCHAR(2550)
);

-- Create Logging Table
CREATE TABLE IF NOT EXISTS public.logging (
    log_id SERIAL PRIMARY KEY,
    log_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    procedure_name VARCHAR(255),
    rows_affected INT,
    message TEXT
);

-- Log operation procedure
CREATE OR REPLACE PROCEDURE public.log_operation(
    procedure_name VARCHAR(255),
    rows_affected INT,
    message TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.logging (
        log_datetime, 
        procedure_name, 
        rows_affected, 
        message
    )
    VALUES (
        CLOCK_TIMESTAMP(),
        procedure_name,
        rows_affected,
        message
    );
END;
$$;


-- Procedure to load data into src_offline_sales
CREATE OR REPLACE PROCEDURE sa_offline_sales.insert_data_into_src_offline_sales()
LANGUAGE plpgsql
AS $$
DECLARE
    rows_affected INT := 0;
BEGIN
    -- Insert data into the source offline sales table
    INSERT INTO sa_offline_sales.src_offline_sales (
        t_id,
        customer_id,
        product_id,
        product_name,
        category,
        quantity_sold,
        unit_price,
        transaction_date,
        time,
        store_id,
        store_location,
        state,
        supplier_id,
        supplier_lead,
        customer_age,
        customer_gender,
        customer_income,
        payment_method
    )
    SELECT DISTINCT
        e.t_id,
        e.customer_id,
        e.product_id,
        e.product_name,
        e.category,
        e.quantity_sold,
        e.unit_price,
        e.transaction_date,
        e.time,
        e.store_id,
        e.store_location,
        e.state,
        e.supplier_id,
        e.supplier_lead,
        e.customer_age,
        e.customer_gender,
        e.customer_income,
        e.payment_method
    FROM sa_offline_sales.ext_offline_sales e;
END;
$$;

-- Procedure to load data into src_online_sales

CREATE OR REPLACE PROCEDURE sa_online_sales.insert_data_into_src_online_sales()
LANGUAGE plpgsql
AS $$
DECLARE
    rows_affected INT := 0;
BEGIN
    -- Insert data into the source online sales table
    INSERT INTO sa_online_sales.src_online_sales (
        transaction_id,
        customer_id,
        product_id,
        product_name,
        category,
        quantity_sold,
        unit_price,
        day,
        month,
        year,
        store,
        store_location,
        supplier_id,
        customer_level,
        promotion_applied
    )
    SELECT DISTINCT
        e.transaction_id,
        e.customer_id,
        e.product_id,
        e.product_name,
        e.category,
        e.quantity_sold,
        e.unit_price,
        e.day,
        e.month,
        e.year,
        e.store,
        e.store_location,
        e.supplier_id,
        e.customer_level,
        e.promotion_applied
    FROM sa_online_sales.ext_online_sales e;
END;
$$;

-- Execute data load procedures
CALL sa_offline_sales.insert_data_into_src_offline_sales();
CALL sa_online_sales.insert_data_into_src_online_sales();

-- Verify Data Insertion
SELECT * FROM sa_offline_sales.ext_offline_sales LIMIT 50;
SELECT * FROM sa_online_sales.ext_online_sales LIMIT 50;