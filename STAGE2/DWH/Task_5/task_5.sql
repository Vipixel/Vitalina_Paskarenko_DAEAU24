-- Create a schema for offline_sales

CREATE SCHEMA IF NOT EXISTS sa_offline_sales;

CREATE EXTENSION IF NOT EXISTS file_fdw;

-- Create a server for file_fdw

CREATE SERVER IF NOT EXISTS sa_offline_sales_server FOREIGN DATA WRAPPER file_fdw;

-- Define the foreign table

CREATE FOREIGN TABLE IF NOT EXISTS sa_offline_sales.ext_offline_sales (
  t_id VARCHAR(3000),
  customer_id VARCHAR(3000),
  product_id VARCHAR(3000),
  product_name VARCHAR(3000),
  category VARCHAR(3000),
  quantity_sold VARCHAR(3000),
  unit_price VARCHAR(3000),
  transaction_date VARCHAR(3000),
  time VARCHAR(3000),
  store_id VARCHAR(3000),
  store_location VARCHAR(3000),
  state VARCHAR(3000),
  supplier_id VARCHAR(3000),
  supplier_lead VARCHAR(3000),
  customer_age VARCHAR(3000),
  customer_gender VARCHAR(3000),
  customer_income VARCHAR(3000),
  payment_method VARCHAR(3000)
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

SELECT * FROM sa_offline_sales.ext_offline_sales

-- Create a schema for online_sales

CREATE SCHEMA IF NOT EXISTS sa_online_sales;

-- Define the foreign table

CREATE FOREIGN TABLE IF NOT EXISTS sa_online_sales.ext_online_sales (
  transaction_id VARCHAR(3000),
  customer_id VARCHAR(3000),
  product_id VARCHAR(3000),
  product_name VARCHAR(3000),
  category VARCHAR(3000),
  quantity_sold VARCHAR(3000),
  unit_price VARCHAR(3000),
  day VARCHAR(3000),
  month VARCHAR(3000),
  year VARCHAR(3000),
  store VARCHAR(3000),
  store_location VARCHAR(3000),
  category_code VARCHAR(3000),
  supplier_id VARCHAR(3000),
  customer_level VARCHAR(3000),
  promotion_applied VARCHAR(3000)
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


-- create source tables

CREATE TABLE IF NOT EXISTS sa_offline_sales.src_offline_sales (
  t_id VARCHAR(3000),
  customer_id VARCHAR(3000),
  product_id VARCHAR(3000),
  product_name VARCHAR(3000),
  category VARCHAR(3000),
  quantity_sold VARCHAR(3000),
  unit_price VARCHAR(3000),
  transaction_date VARCHAR(3000),
  time VARCHAR(3000),
  store_id VARCHAR(3000),
  store_location VARCHAR(3000),
  state VARCHAR(3000),
  supplier_id VARCHAR(3000),
  supplier_lead VARCHAR(3000),
  customer_age VARCHAR(3000),
  customer_gender VARCHAR(3000),
  customer_income VARCHAR(3000),
  payment_method VARCHAR(3000)
);

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
SELECT
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
FROM sa_offline_sales.ext_offline_sales;

-- create source tables

CREATE TABLE IF NOT EXISTS sa_online_sales.src_online_sales (
  transaction_id VARCHAR(3000),
  customer_id VARCHAR(3000),
  product_id VARCHAR(3000),
  product_name VARCHAR(3000),
  category VARCHAR(3000),
  quantity_sold VARCHAR(3000),
  unit_price VARCHAR(3000),
  day VARCHAR(3000),
  month VARCHAR(3000),
  year VARCHAR(3000),
  store VARCHAR(3000),
  store_location VARCHAR(3000),
  category_code VARCHAR(3000),
  supplier_id VARCHAR(3000),
  customer_level VARCHAR(3000),
  promotion_applied VARCHAR(3000)
);

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
    category_code,
    supplier_id,
    customer_level,
    promotion_applied
)
SELECT
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
    category_code,
    supplier_id,
    customer_level,
    promotion_applied
FROM sa_online_sales.ext_online_sales;