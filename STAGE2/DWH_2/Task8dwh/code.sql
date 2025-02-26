CREATE SEQUENCE IF NOT EXISTS BL_DM.customer_surr_id_seq;
CREATE SEQUENCE IF NOT EXISTS BL_DM.product_surr_id_seq;
CREATE SEQUENCE IF NOT EXISTS BL_DM.promotion_surr_id_seq;
CREATE SEQUENCE IF NOT EXISTS BL_DM.store_surr_id_seq;
CREATE SEQUENCE IF NOT EXISTS BL_DM.transaction_id_seq;

-- here i check index if they exist and making sure they do exsit

-- Creating procedures to load data into DIM and FCT tables

CREATE OR REPLACE PROCEDURE BL_CL.load_dm_dates()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    rows_affected INT := 0;
BEGIN
    FOR rec IN
        SELECT DISTINCT
            transaction_date::DATE AS date_dt,
            EXTRACT(DAY FROM transaction_date::DATE) AS day_of_month,
            EXTRACT(MONTH FROM transaction_date::DATE) AS month,
            EXTRACT(YEAR FROM transaction_date::DATE) AS year,
            EXTRACT(QUARTER FROM transaction_date::DATE) AS quarter,
            EXTRACT(WEEK FROM transaction_date::DATE) AS week_of_year,
            EXTRACT(DOW FROM transaction_date::DATE) AS day_of_week,
            EXTRACT(DOY FROM transaction_date::DATE) AS day_of_year
        FROM BL_3NF.CE_DATES
        WHERE EXTRACT(YEAR FROM transaction_date::DATE) BETWEEN 1900 AND 2100
    LOOP
        IF NOT EXISTS (SELECT 1 FROM BL_DM.DM_DATES WHERE date_dt = rec.date_dt) THEN
            INSERT INTO BL_DM.DM_DATES (
                date_dt, day_of_week, day_of_month, day_of_year, week_of_year, month, quarter, year
            )
            VALUES (
                rec.date_dt,
                rec.day_of_week,
                rec.day_of_month,
                rec.day_of_year,
                rec.week_of_year,
                rec.month,
                rec.quarter,
                rec.year
            );
            rows_affected := rows_affected + 1;
        END IF;
    END LOOP;

    PERFORM BL_CL.log_procedure_action('load_dm_dates', rows_affected, 'Dates loaded successfully into DM');
EXCEPTION
    WHEN OTHERS THEN
        PERFORM BL_CL.log_procedure_action('load_dm_dates', rows_affected, 'Error loading dates: ' || SQLERRM);
END;
$$;
-----------

CREATE OR REPLACE PROCEDURE BL_CL.load_dim_customer_scd()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    rows_affected INT := 0;
BEGIN
    FOR rec IN
        SELECT
            customer_id,
            customer_age,
            customer_level,
            gender,
            customer_income
        FROM BL_3NF.CE_CUSTOMER_SCD
    LOOP
        BEGIN
            -- Check if the record already exists and is active
            IF EXISTS (
                SELECT 1 
                FROM BL_DM.DIM_CUSTOMER_SCD 
                WHERE customer_id = rec.customer_id 
                  AND is_active = 'Y'
            ) THEN
                -- Update record 
                UPDATE BL_DM.DIM_CUSTOMER_SCD
                SET 
                    is_active = 'N',
                    end_dt = CURRENT_DATE - INTERVAL '1 day',  -- Set end_dt to the previous day
                    update_dt = CURRENT_TIMESTAMP
                WHERE 
                    customer_id = rec.customer_id 
                    AND is_active = 'Y';

                -- Insert the new record as active
                INSERT INTO BL_DM.DIM_CUSTOMER_SCD (
                    customer_surr_id, customer_id, customer_age, customer_level,
                    gender, customer_income, start_dt, end_dt, is_active, insert_dt, update_dt
                )
                VALUES (
                    nextval('BL_DM.customer_surr_id_seq'),
                    rec.customer_id,
                    rec.customer_age,
                    rec.customer_level,
                    rec.gender,
                    rec.customer_income,
                    CURRENT_DATE - INTERVAL '1 day',  -- Set start_dt to 1 day before today
                    CURRENT_DATE + INTERVAL '1 year',  -- Set end_dt to 1 year from today
                    'Y',                              -- Set is_active to 'Y' for the new record
                    CURRENT_DATE,                     -- Set insert_dt to today's date
                    CURRENT_TIMESTAMP                 -- Set update_dt to the current timestamp
                );
            ELSE
                -- Insert the new record as active (no existing active record found)
                INSERT INTO BL_DM.DIM_CUSTOMER_SCD (
                    customer_surr_id, customer_id, customer_age, customer_level,
                    gender, customer_income, start_dt, end_dt, is_active, insert_dt, update_dt
                )
                VALUES (
                    nextval('BL_DM.customer_surr_id_seq'),
                    rec.customer_id,
                    rec.customer_age,
                    rec.customer_level,
                    rec.gender,
                    rec.customer_income,
                    CURRENT_DATE - INTERVAL '1 day',  -- Set start_dt to 1 day before today
                    CURRENT_DATE + INTERVAL '1 year',  -- Set end_dt to 1 year from today
                    'Y',                              -- Set is_active to 'Y' for the new record
                    CURRENT_DATE,                     -- Set insert_dt to today's date
                    CURRENT_TIMESTAMP                 -- Set update_dt to the current timestamp
                );
            END IF;

            rows_affected := rows_affected + 1;
        EXCEPTION
            WHEN OTHERS THEN
                PERFORM BL_CL.log_procedure_action('load_dim_customer_scd', rows_affected, 'Error loading customer: ' || rec.customer_id || ' - ' || SQLERRM);
        END;
    END LOOP;

    PERFORM BL_CL.log_procedure_action('load_dim_customer_scd', rows_affected, 'Customers loaded successfully into DM');
END;
$$;
-----------------
CREATE OR REPLACE PROCEDURE BL_CL.load_dim_stores()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    rows_affected INT := 0;
BEGIN
    FOR rec IN
        SELECT
            store_id,
            store_location,
            state
        FROM BL_3NF.CE_STORES
    LOOP
        BEGIN
            -- Check if the record already exists
            IF EXISTS (
                SELECT 1 
                FROM BL_DM.DIM_STORES 
                WHERE store_id = rec.store_id
            ) THEN
                -- Update the existing record
                UPDATE BL_DM.DIM_STORES
                SET 
                    store_location = rec.store_location,
                    state = rec.state,
                    store_scr_id = rec.store_id::VARCHAR,  -- Use store_id as store_scr_id
                    update_dt = CURRENT_TIMESTAMP
                WHERE 
                    store_id = rec.store_id;
            ELSE
                -- Insert the new record
                INSERT INTO BL_DM.DIM_STORES (
                    store_surr_id, store_id, store_location, state, store_scr_id, insert_dt, update_dt
                )
                VALUES (
                    nextval('BL_DM.store_surr_id_seq'),
                    rec.store_id,
                    rec.store_location,
                    rec.state,
                    rec.store_id::VARCHAR,  -- Use store_id as store_scr_id
                    CURRENT_DATE,          -- Set insert_dt to today date
                    CURRENT_TIMESTAMP       -- Set update_dt to the current timestamp
                );
            END IF;

            rows_affected := rows_affected + 1;
        EXCEPTION
            WHEN OTHERS THEN
                PERFORM BL_CL.log_procedure_action('load_dim_stores', rows_affected, 'Error loading store: ' || rec.store_id || ' - ' || SQLERRM);
        END;
    END LOOP;

    PERFORM BL_CL.log_procedure_action('load_dim_stores', rows_affected, 'Stores loaded successfully into DM');
END;
$$;
-------------------------

CREATE OR REPLACE PROCEDURE BL_CL.load_dim_promotion()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    rows_affected INT := 0;
BEGIN
    FOR rec IN
        SELECT
            promotion_id,
            promotion_applied
        FROM BL_3NF.CE_PROMOTION
    LOOP
        BEGIN
            -- Check if the record already exists
            IF NOT EXISTS (
                SELECT 1 
                FROM BL_DM.DIM_PROMOTION 
                WHERE promotion_id = rec.promotion_id
            ) THEN
                -- Insert the new record 
                INSERT INTO BL_DM.DIM_PROMOTION (
                    promotion_surr_id, promotion_id, promotion_applied, insert_dt
                )
                VALUES (
                    nextval('BL_DM.promotion_surr_id_seq'),
                    rec.promotion_id,
                    rec.promotion_applied,
                    CURRENT_DATE,  -- Set insert_dt to today date
					CURRENT_DATE
                );

                rows_affected := rows_affected + 1;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                PERFORM BL_CL.log_procedure_action('load_dim_promotion', rows_affected, 'Error loading promotion: ' || rec.promotion_id || ' - ' || SQLERRM);
        END;
    END LOOP;

    PERFORM BL_CL.log_procedure_action('load_dim_promotion', rows_affected, 'Promotions loaded successfully into DM');
END;
$$;

-------------

CREATE OR REPLACE PROCEDURE BL_CL.load_dim_product_supplier()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    rows_affected INT := 0;
BEGIN
    FOR rec IN
        SELECT
            p.product_id,
            p.product_name,
            p.category_id,
            p.unit_price,
            s.supplier_id
        FROM BL_3NF.CE_PRODUCTS p
        JOIN BL_3NF.CE_SUPPLIERS s ON p.source_id = s.source_id  -- Join on source_id
    LOOP
        BEGIN
            -- Check if the record already exists
            IF EXISTS (
                SELECT 1 
                FROM BL_DM.DIM_PRODUCT_SUPPLIER 
                WHERE product_id = rec.product_id
            ) THEN
                -- Update the existing record with new values 
                UPDATE BL_DM.DIM_PRODUCT_SUPPLIER
                SET 
                    product_name = rec.product_name,
                    category_id = rec.category_id,
                    unit_price = rec.unit_price,
                    supplier_id = rec.supplier_id,
                    update_dt = CURRENT_TIMESTAMP
                WHERE 
                    product_id = rec.product_id;
            ELSE
                -- Insert the new record
                INSERT INTO BL_DM.DIM_PRODUCT_SUPPLIER (
                    product_surr_id, product_id, product_name, category_id, unit_price,
                    supplier_id, insert_dt, update_dt
                )
                VALUES (
                    nextval('BL_DM.product_surr_id_seq'),
                    rec.product_id,
                    rec.product_name,
                    rec.category_id,
                    rec.unit_price,
                    rec.supplier_id,
                    CURRENT_DATE,          -- Set insert_dt to today date
                    CURRENT_TIMESTAMP       -- Set update_dt to the current timestamp
                );
            END IF;

            rows_affected := rows_affected + 1;
        EXCEPTION
            WHEN OTHERS THEN
                PERFORM BL_CL.log_procedure_action('load_dim_product_supplier', rows_affected, 'Error loading product: ' || rec.product_id || ' - ' || SQLERRM);
        END;
    END LOOP;

    PERFORM BL_CL.log_procedure_action('load_dim_product_supplier', rows_affected, 'Products and suppliers loaded successfully into DM');
END;
$$;

--------------
CREATE OR REPLACE PROCEDURE BL_CL.load_fct_sales_dd()
LANGUAGE plpgsql
AS $$
DECLARE
    rows_inserted INT := 0;
BEGIN
    INSERT INTO BL_DM.FCT_SALES_DD
        ( transaction_id
        , customer_surr_id
        , store_surr_id
        , product_surr_id
        , promotion_surr_id
        , quantity_sold
        , total_cost
        , time
        , source_entity
        , source_system
        )
    SELECT
        s.t_id                AS transaction_id,
        c.customer_surr_id    AS customer_surr_id,
        st.store_surr_id      AS store_surr_id,
        p.product_surr_id     AS product_surr_id,
        pr.promotion_surr_id  AS promotion_surr_id,
        s.quantity_sold,
        (s.quantity_sold * p.unit_price) AS total_cost,
        s.time::TIME          AS time, 
        s.source_entity,
        s.source_system
    FROM BL_3NF.CE_SALES s
         LEFT JOIN BL_DM.DIM_CUSTOMER_SCD c 
            ON s.customer_id = c.customer_id
         LEFT JOIN BL_DM.DIM_STORES st
            ON s.store_id = st.store_id
         LEFT JOIN BL_DM.DIM_PRODUCT_SUPPLIER p
            ON s.product_id = p.product_id
         LEFT JOIN BL_DM.DIM_PROMOTION pr
            ON s.promotion_id = pr.promotion_id
    WHERE s.t_id IS NOT NULL
      AND NOT EXISTS (
          SELECT 1
            FROM BL_DM.FCT_SALES_DD f
           WHERE f.transaction_id = s.t_id
      );

    -- Get the number of rows inserted to understand
    GET DIAGNOSTICS rows_inserted = ROW_COUNT;

    RAISE NOTICE 'Finished load_fct_sales_dd(); total rows inserted = %', rows_inserted;
END;
$$;

-- Load DM_DATES
CALL BL_CL.load_dm_dates();
SELECT * FROM BL_DM.DIM_DATES LIMIT 100;

-- Load DIM_CUSTOMERS_SCD
CALL BL_CL.load_dim_customer_scd();
SELECT * FROM BL_DM.DIM_CUSTOMER_SCD LIMIT 10;

-- Load DM_PROMOTION
CALL BL_CL.load_dim_promotion();
SELECT * FROM BL_DM.DIM_PROMOTION LIMIT 10;

-- Load DM_STORES
CALL BL_CL.load_dim_stores();
SELECT * FROM BL_DM.DIM_STORES LIMIT 10;

-- Load DM_PRODUCT_SUPPLIER
CALL BL_CL.load_dim_product_supplier();
SELECT * FROM BL_DM.DIM_PRODUCT_SUPPLIER LIMIT 10;

-- Load FCT_SALES_DD
CALL BL_CL.load_fct_sales_dd();
SELECT * FROM BL_DM.FCT_SALES_DD ;
