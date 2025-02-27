-- Drop the table if it already exists to start

DROP TABLE IF EXISTS BL_DM.FCT_SALES_DD CASCADE;

-- Created the logging table in the BL_CL schema
CREATE TABLE IF NOT EXISTS BL_CL.procedure_logs (
    id SERIAL PRIMARY KEY,
    procedure_name TEXT,
    rows_affected INT,
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    message TEXT
);
----creating table

CREATE TABLE IF NOT EXISTS BL_3NF.src_sales (
    t_id             BIGINT,
    customer_id      BIGINT,
    store_id         BIGINT,
    product_id       BIGINT,
    promotion_id     BIGINT,
    quantity_sold    INT,
    transaction_date DATE,
    time             TIME,
    source_entity    TEXT,
    source_system    TEXT
);
---------

CREATE OR REPLACE PROCEDURE BL_3NF.load_3nf_fact_table_incrementally()
LANGUAGE plpgsql
AS $$
DECLARE
    rows_affected INT := 0;
BEGIN
    ---insert new records into the table incrementally
    INSERT INTO BL_3NF.CE_SALES (
         t_id, customer_id, store_id, product_id, promotion_id,
         quantity_sold, transaction_date, time, source_entity, source_system
    )
    SELECT DISTINCT
        s.t_id,
        s.customer_id,
        s.store_id,
        s.product_id,
        s.promotion_id,
        s.quantity_sold,
        s.transaction_date,
        s.time,
        s.source_entity,
        s.source_system
    FROM BL_3NF.src_sales s
    WHERE NOT EXISTS (
        SELECT 1
        FROM BL_3NF.CE_SALES c
        WHERE c.t_id = s.t_id  
    );

    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    PERFORM BL_CL.log_procedure_action(
        'load_3nf_fact_table_incrementally',
        rows_affected,
        'Sales loaded into 3NF (CE_SALES). Rows inserted: ' || rows_affected
    );

    RAISE NOTICE '3NF incremental load complete. Rows inserted: %', rows_affected;
END;
$$;

--------- Define the logging function in the BL_CL schema:
CREATE OR REPLACE FUNCTION BL_CL.log_procedure_action(
    p_procedure_name TEXT,
    p_rows_affected  INT,
    p_message        TEXT
)
RETURNS VOID AS
$$
BEGIN
    INSERT INTO BL_CL.procedure_logs (
        procedure_name, rows_affected, message
    )
    VALUES (p_procedure_name, p_rows_affected, p_message);
END;
$$
LANGUAGE plpgsql;

-------- Create the main fact table as partitioned

CREATE TABLE IF NOT EXISTS BL_DM.FCT_SALES_DD (
    transaction_id   BIGINT,
    customer_surr_id INT REFERENCES BL_DM.DIM_CUSTOMER_SCD(customer_surr_id),
    store_surr_id    INT REFERENCES BL_DM.DIM_STORES(store_surr_id),
    product_surr_id  INT REFERENCES BL_DM.DIM_PRODUCT_SUPPLIER(product_surr_id),
    promotion_surr_id INT REFERENCES BL_DM.DIM_PROMOTION(promotion_surr_id),
    quantity_sold    INT,
    total_cost       NUMERIC,
    time             TIME,
    source_entity    TEXT,
    source_system    TEXT,
    transaction_date DATE,
    ta_insert_dt     TIMESTAMP,
    ta_update_dt     TIMESTAMP,
    PRIMARY KEY (transaction_id, transaction_date)
) PARTITION BY RANGE (transaction_date);

-- Create static partitions for 2023, 2024, 2025:

CREATE TABLE IF NOT EXISTS BL_DM.FCT_SALES_DD_2023 PARTITION OF BL_DM.FCT_SALES_DD
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE IF NOT EXISTS BL_DM.FCT_SALES_DD_2024 PARTITION OF BL_DM.FCT_SALES_DD
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE IF NOT EXISTS BL_DM.FCT_SALES_DD_2025 PARTITION OF BL_DM.FCT_SALES_DD
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
	
----Procedure for load Sales

CREATE OR REPLACE PROCEDURE BL_DM.load_fct_sales_dd()
LANGUAGE plpgsql
AS $$
DECLARE
    rows_inserted INT := 0;
BEGIN
    INSERT INTO BL_DM.FCT_SALES_DD (
         transaction_id,
         customer_surr_id,
         store_surr_id,
         product_surr_id,
         promotion_surr_id,
         quantity_sold,
         total_cost,
         time,
         source_entity,
         source_system,
         transaction_date
    )
    SELECT
        s.t_id AS transaction_id,
        c.customer_surr_id,
        st.store_surr_id,
        p.product_surr_id,
        pr.promotion_surr_id,
        s.quantity_sold,
        s.quantity_sold::NUMERIC AS total_cost, 
        s.time,
        s.source_entity,
        s.source_system,
        s.transaction_date
    FROM BL_3NF.CE_SALES s
         LEFT JOIN BL_DM.DIM_CUSTOMER_SCD c
                ON s.customer_id = c.customer_id AND c.is_active = 'Y'
         LEFT JOIN BL_DM.DIM_STORES st
                ON s.store_id = st.store_id
         LEFT JOIN BL_DM.DIM_PRODUCT_SUPPLIER p
                ON s.product_id = p.product_id
         LEFT JOIN BL_DM.DIM_PROMOTION pr
                ON s.promotion_id = pr.promotion_id
    WHERE s.transaction_date IS NOT NULL 
	ON CONFLICT (transaction_id, transaction_date) DO NOTHING;
    GET DIAGNOSTICS rows_inserted = ROW_COUNT;
	----- Log the action
    PERFORM BL_CL.log_procedure_action(
        'load_fct_sales_dd',
        rows_inserted,
        'Fact table loaded successfully. Rows inserted: ' || rows_inserted
    );
    RAISE NOTICE 'Finished load_fct_sales_dd(); total rows inserted = %', rows_inserted;
END;
$$;

SELECT s.t_id, COUNT(*) 
FROM BL_3NF.src_sales s
GROUP BY s.t_id
HAVING COUNT(*) > 1;


----Load 3nF
CALL BL_3NF.load_3nf_fact_table_incrementally();

----Load DM
CALL BL_DM.load_fct_sales_dd();

-----Example of querying the fact table
SELECT *
FROM BL_3NF.CE_SALES
LIMIT 50;
  
----Checking logs
SELECT *
FROM BL_CL.procedure_logs
ORDER BY log_timestamp DESC;

----Verify that all business keys from the source table are loaded into the destination table
SELECT t_id
FROM BL_3NF.CE_SALES
EXCEPT
SELECT transaction_id
FROM BL_DM.FCT_SALES_DD;

---Count the number of records in the source table for the last 3 months based on the maximum date in the table
SELECT *
FROM BL_3NF.CE_SALES
WHERE transaction_date BETWEEN (SELECT MAX(transaction_date) FROM BL_3NF.CE_SALES) - INTERVAL '3 months'
AND (SELECT MAX(transaction_date) FROM BL_3NF.CE_SALES);

----Get the minimum and maximum event_dt from the source table to understand the date range of the data
SELECT MIN(transaction_date) , MAX(transaction_date)
FROM BL_3NF.CE_SALES

----Count the number of records in the source table for the year 2024
SELECT COUNT(*) 
FROM BL_3NF.CE_SALES
WHERE transaction_date BETWEEN '2024-01-01' AND '2024-12-30';