-- Creating  schema

CREATE SCHEMA IF NOT EXISTS BL_CL;

-- Creating a centralized logging table in BL_CL schema

CREATE TABLE IF NOT EXISTS BL_CL.procedure_logs (
    log_id SERIAL PRIMARY KEY,
    log_timestamp TIMESTAMPTZ DEFAULT NOW(),
    procedure_name TEXT,
    rows_affected INT,
    log_message TEXT,
    error_message TEXT
);

-- Creating a logging function in BL_CL schema

CREATE OR REPLACE FUNCTION BL_CL.log_procedure_action(
    proc_name TEXT, 
    rows INT, 
    message TEXT, 
    error_message TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    INSERT INTO BL_CL.procedure_logs (procedure_name, rows_affected, log_message, error_message)
    VALUES (proc_name, rows, message, error_message);
END;
$$ LANGUAGE plpgsql;

-- Creating a stored procedure for logging events
CREATE OR REPLACE PROCEDURE BL_CL.insert_log(
    p_proc_name TEXT,
    p_rows_affected INT,
    p_log_message TEXT,
    p_error_message TEXT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO BL_CL.procedure_logs (procedure_name, rows_affected, log_message, error_message)
    VALUES (p_proc_name, p_rows_affected, p_log_message, p_error_message);
END;
$$;


-- Creating role if it does not exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'BL_CL') THEN
        CREATE ROLE BL_CL LOGIN PASSWORD '123password';
    END IF;
END $$;


-- Grant privileges to BL_CL for data cleansing
GRANT ALL PRIVILEGES ON SCHEMA BL_3NF TO BL_CL;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA BL_3NF TO BL_CL;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA BL_3NF TO BL_CL;



-- Procedure for loading categories
CREATE OR REPLACE PROCEDURE BL_CL.load_categories()
LANGUAGE plpgsql AS $$
DECLARE
    rows_affected INT := 0;
BEGIN
    INSERT INTO BL_3NF.CE_CATEGORIES (
        category_id, category_name, source_id, source_entity, source_system
    )
    SELECT DISTINCT
        nextval('BL_3NF.category_id_seq'),
        category_name,
        source_id,
        source_entity,
        source_system
    FROM (
        SELECT DISTINCT
            off.category AS category_name,
            off.category AS source_id,
            'sa_offline_sales' AS source_system,
            'src_offline_sales' AS source_entity
        FROM sa_offline_sales.src_offline_sales off
        
        UNION ALL
        
        SELECT DISTINCT
            onl.category AS category_name,
            onl.category AS source_id,
            'sa_online_sales' AS source_system,
            'src_online_sales' AS source_entity
        FROM sa_online_sales.src_online_sales onl
    ) AS combined
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_3NF.CE_CATEGORIES existing
        WHERE existing.source_id = combined.source_id
          AND existing.source_system = combined.source_system
          AND existing.source_entity = combined.source_entity
    );
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    CALL BL_CL.insert_log('load_categories', rows_affected, 'Categories loaded successfully');
EXCEPTION
    WHEN OTHERS THEN
        CALL BL_CL.insert_log('load_categories', 0, 'Error occurred during categories load', SQLERRM);
        RAISE;
END;
$$;
-- Procedure for loading customer

CREATE OR REPLACE FUNCTION BL_CL.load_entity_data(
    entity_type TEXT
) RETURNS TABLE (
    processed_rows BIGINT,
    status TEXT,
    error_msg TEXT
) AS $$
DECLARE
    rows_affected INT := 0;
    error_message TEXT;
    rec RECORD;
BEGIN
    CASE entity_type
        WHEN 'customers' THEN
            -- Merge customers from offline and online sources using customer_id
            FOR rec IN 
                SELECT DISTINCT
                    COALESCE(off.customer_id::TEXT, onl.customer_id::TEXT) AS source_id,
                    COALESCE(off.customer_age::INTEGER, 0) AS customer_age,  
                    COALESCE(onl.customer_level, 'Unknown') AS customer_level,  
                    COALESCE(off.customer_gender, 'Unknown') AS gender,  
                    COALESCE(off.customer_income::NUMERIC, 0) AS customer_income,  
                    -- Assign source_system manually (since it doesn't exist in the tables)
                    CASE 
                        WHEN off.customer_id IS NOT NULL THEN 'sa_offline_sales'
                        ELSE 'sa_online_sales'
                    END AS source_system,
                    -- Assign source_entity manually
                    CASE 
                        WHEN off.customer_id IS NOT NULL THEN 'src_offline_sales'
                        ELSE 'src_online_sales'
                    END AS source_entity
                FROM sa_offline_sales.src_offline_sales off
                FULL OUTER JOIN sa_online_sales.src_online_sales onl
                ON off.customer_id::TEXT = onl.customer_id::TEXT
            LOOP
                RAISE NOTICE 'Processing merged customer: source_id = %, customer_age = %, customer_level = %, gender = %, customer_income = %',
                    rec.source_id, rec.customer_age, rec.customer_level, rec.gender, rec.customer_income;
					
                -- Check if the customer already exists
                IF EXISTS (
                    SELECT 1 FROM BL_3NF.CE_CUSTOMER_SCD ex
                    WHERE ex.source_id = rec.source_id
                    AND ex.source_system = rec.source_system
                    AND ex.is_active = TRUE
                ) THEN
                    -- Check if any fields have changed
                    IF EXISTS (
                        SELECT 1 FROM BL_3NF.CE_CUSTOMER_SCD ex
                        WHERE ex.source_id = rec.source_id
                        AND ex.source_system = rec.source_system
                        AND ex.is_active = TRUE
                        AND (
                            ex.customer_age <> rec.customer_age OR
                            ex.customer_level <> rec.customer_level OR
                            ex.gender <> rec.gender OR
                            ex.customer_income <> rec.customer_income
                        )
                    ) THEN
                        -- Update: Deactivate old record and insert a new version
                        UPDATE BL_3NF.CE_CUSTOMER_SCD
                        SET is_active = FALSE,
                            end_date = CURRENT_DATE - INTERVAL '1 day'
                        WHERE source_id = rec.source_id
                        AND source_system = rec.source_system
                        AND is_active = TRUE;
                        RAISE NOTICE 'Deactivated old record for source_id = %', rec.source_id;

                        INSERT INTO BL_3NF.CE_CUSTOMER_SCD (
                            customer_id, customer_age, customer_level, gender,
                            customer_income, source_id, source_entity, source_system,
                            start_date, end_date, is_active
                        )
                        VALUES (
                            nextval('BL_3NF.customer_id_seq'),  
                            rec.customer_age, rec.customer_level, rec.gender,
                            rec.customer_income, rec.source_id, rec.source_entity, rec.source_system,
                            CURRENT_DATE, '9999-12-31', TRUE
                        );
                        RAISE NOTICE 'Updated customer: source_id = %', rec.source_id;
                    ELSE
                        -- No changes detected, skip insert
                        RAISE NOTICE 'Skipping existing customer (no changes): source_id = %', rec.source_id;
                    END IF;
                ELSE
                    -- Insert new customer
                    INSERT INTO BL_3NF.CE_CUSTOMER_SCD (
                        customer_id, customer_age, customer_level, gender,
                        customer_income, source_id, source_entity, source_system,
                        start_date, end_date, is_active
                    )
                    VALUES (
                        nextval('BL_3NF.customer_id_seq'),  
                        rec.customer_age, rec.customer_level, rec.gender,
                        rec.customer_income, rec.source_id, rec.source_entity, rec.source_system,
                        CURRENT_DATE, '9999-12-31', TRUE
                    );
                    RAISE NOTICE 'Inserted new customer: source_id = %', rec.source_id;
                END IF;
            END LOOP;

        ELSE
            RAISE EXCEPTION 'Unknown entity_type: %', entity_type;
    END CASE;

    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    processed_rows := rows_affected;
    status := 'Success';
    error_msg := NULL;

    PERFORM BL_CL.log_procedure_action(
        'load_' || entity_type,
        rows_affected,
        entity_type || ' loaded successfully'
    );

    RETURN NEXT;

EXCEPTION
    WHEN OTHERS THEN
        error_message := SQLERRM;
        processed_rows := 0;
        status := 'Error';
        error_msg := error_message;

        PERFORM BL_CL.log_procedure_action(
            'load_' || entity_type,
            0,
            'Error loading ' || entity_type,
            error_message
        );
        RETURN NEXT;
END;
$$ LANGUAGE plpgsql;
---------run function to load
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT * FROM BL_CL.load_entity_data('customers') LOOP
        RAISE NOTICE 'Processed % rows, Status: %, Error: %', 
            r.processed_rows, r.status, r.error_msg;
    END LOOP;
END $$;

SELECT * FROM BL_CL.load_entity_data('customers');

-----------create alter table for customer

ALTER TABLE BL_3NF.CE_CUSTOMER_SCD
ADD COLUMN IF NOT EXISTS start_date DATE DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS end_date DATE DEFAULT '9999-12-31',
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
ALTER COLUMN customer_income TYPE NUMERIC USING customer_income::NUMERIC;


----------check the results

SELECT * FROM BL_3NF.CE_CUSTOMER_SCD ;

--------- Procedure for loading products

CREATE OR REPLACE PROCEDURE BL_CL.load_products()
LANGUAGE plpgsql AS $$
DECLARE
    rows_affected INT := 0;
    error_message TEXT; 
BEGIN
    INSERT INTO BL_3NF.CE_PRODUCTS (
        product_id, product_name, category_id, unit_price, source_id, source_entity, source_system
    )
    SELECT DISTINCT
        nextval('BL_3NF.product_id_seq'),
        cp.product_name,
        (SELECT category_id FROM BL_3NF.CE_CATEGORIES cat
         WHERE cat.source_id = cp.category_name
           AND cat.source_system = cp.source_system
           AND cat.source_entity = cp.source_entity
         ORDER BY category_id ASC LIMIT 1) AS category_id,
        cp.unit_price::NUMERIC(10,2),
        cp.source_id,
        cp.source_entity,
        cp.source_system
    FROM (
        SELECT DISTINCT
            off.product_id AS source_id,
            off.product_name AS product_name,
            off.category AS category_name,
            off.unit_price::NUMERIC(10,2) AS unit_price,
            'sa_offline_sales' AS source_system,
            'src_offline_sales' AS source_entity
        FROM sa_offline_sales.src_offline_sales off
        
        UNION ALL
        
        SELECT DISTINCT
            onl.product_id AS source_id,
            onl.product_name AS product_name,
            onl.category AS category_name,
            onl.unit_price::NUMERIC(10,2) AS unit_price,
            'sa_online_sales' AS source_system,
            'src_online_sales' AS source_entity
        FROM sa_online_sales.src_online_sales onl
    ) AS cp
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_3NF.CE_PRODUCTS existing
        WHERE existing.source_id = cp.source_id
          AND existing.source_system = cp.source_system
          AND existing.source_entity = cp.source_entity
    );
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
        PERFORM BL_CL.log_procedure_action('load_products', rows_affected, 'Products loaded successfully');

EXCEPTION
    WHEN OTHERS THEN
        error_message := SQLERRM; 
        PERFORM BL_CL.log_procedure_action('load_products', 0, 'Error occurred during product load: ' || error_message);
        RAISE;
END;
$$;


-- Procedure for loading stores

CREATE OR REPLACE PROCEDURE BL_CL.load_stores()
LANGUAGE plpgsql AS $$
DECLARE
    rows_affected INT := 0;
    error_message TEXT; 
BEGIN
    INSERT INTO BL_3NF.CE_STORES (
        store_id, store_location, state, source_id, source_entity, source_system
    )
    SELECT DISTINCT
        nextval('BL_3NF.store_id_seq'),
        cs.store_location,
        COALESCE(cs.state, 'ONLINE') AS state,
        cs.source_id,
        cs.source_entity,
        cs.source_system
    FROM (
        SELECT DISTINCT
            off.store_id AS source_id,
            off.store_location AS store_location,
            off.state AS state,
            'sa_offline_sales' AS source_system,
            'src_offline_sales' AS source_entity
        FROM sa_offline_sales.src_offline_sales off
        
        UNION ALL
        
        SELECT DISTINCT
            onl.store AS source_id,
            onl.store_location AS store_location,
            NULL AS state,
            'sa_online_sales' AS source_system,
            'src_online_sales' AS source_entity
        FROM sa_online_sales.src_online_sales onl
    ) AS cs
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_3NF.CE_STORES existing
        WHERE existing.source_id = cs.source_id
          AND existing.source_system = cs.source_system
          AND existing.source_entity = cs.source_entity
    );
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;

    PERFORM BL_CL.log_procedure_action('load_stores', rows_affected, 'Stores loaded successfully');

EXCEPTION
    WHEN OTHERS THEN
        error_message := SQLERRM;
        PERFORM BL_CL.log_procedure_action('load_stores', 0, 'Error occurred during store load: ' || error_message);
        RAISE;
END;
$$;

-- Procedure for loading dates

CREATE OR REPLACE PROCEDURE BL_CL.load_dates()
LANGUAGE plpgsql AS $$
DECLARE
    rows_affected INT := 0;
    error_message TEXT; 
BEGIN
    INSERT INTO BL_3NF.CE_DATES (
        transaction_date, source_id, source_entity, source_system
    )
    SELECT DISTINCT
        cd.transaction_date,
        cd.source_id,
        cd.source_entity,
        cd.source_system
    FROM (
        SELECT DISTINCT
            c.transaction_date::DATE AS transaction_date,
            c.transaction_date::TEXT AS source_id,
            'sa_offline_sales' AS source_system,
            'src_offline_sales' AS source_entity
        FROM sa_offline_sales.src_offline_sales c
    ) AS cd
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_3NF.CE_DATES d
        WHERE d.source_id = cd.source_id
          AND d.source_system = cd.source_system
          AND d.source_entity = cd.source_entity
    );
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    PERFORM BL_CL.log_procedure_action('load_dates', rows_affected, 'Dates loaded successfully');
EXCEPTION
    WHEN OTHERS THEN
        error_message := SQLERRM;  
        PERFORM BL_CL.log_procedure_action('load_dates', 0, 'Error occurred during date load: ' || error_message);
        RAISE;
END;
$$;


-- Procedure for loading suppliers

CREATE OR REPLACE PROCEDURE BL_CL.load_suppliers()
LANGUAGE plpgsql AS $$
DECLARE
    rows_affected INT := 0;
    error_message TEXT; 
BEGIN
    INSERT INTO BL_3NF.CE_SUPPLIERS (
        supplier_id, source_id, source_entity, source_system
    )
    SELECT DISTINCT
        nextval('BL_3NF.supplier_id_seq'),
        cs.source_id,
        cs.source_entity,
        cs.source_system
    FROM (
        SELECT DISTINCT
            off.supplier_id AS source_id,
            'sa_offline_sales' AS source_system,
            'src_offline_sales' AS source_entity
        FROM sa_offline_sales.src_offline_sales off
        
        UNION ALL
        
        SELECT DISTINCT
            onl.supplier_id AS source_id,
            'sa_online_sales' AS source_system,
            'src_online_sales' AS source_entity
        FROM sa_online_sales.src_online_sales onl
    ) AS cs
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_3NF.CE_SUPPLIERS existing
        WHERE existing.source_id = cs.source_id
          AND existing.source_system = cs.source_system
          AND existing.source_entity = cs.source_entity
    );
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    
    PERFORM BL_CL.log_procedure_action('load_suppliers', rows_affected, 'Suppliers loaded successfully');

EXCEPTION
    WHEN OTHERS THEN
        error_message := SQLERRM; 
        PERFORM BL_CL.log_procedure_action('load_suppliers', 0, 'Error occurred during supplier load: ' || error_message);
        RAISE;
END;
$$;

-- Procedure for loading sales

CREATE OR REPLACE PROCEDURE BL_CL.load_sales()
LANGUAGE plpgsql AS $$
DECLARE
    rows_affected INT := 0;
    error_message TEXT; 
BEGIN
    INSERT INTO BL_3NF.CE_SALES (
        t_id, time, customer_id, store_id, product_id, promotion_id, 
        unit_price,transaction_date, quantity_sold, source_id, source_system, source_entity
    )
    SELECT
        nextval('BL_3NF.transaction_id_seq') AS t_id,
        cs.time_of_day,
        cs.dim_customer_id,
        cs.dim_store_id,
        cs.dim_product_id,
        cs.dim_promotion_id,
        cs.unit_price,
		cs.transaction_date::DATE,
        cs.quantity_sold,
        cs.source_id,
        cs.source_system,
        cs.source_entity
    FROM (
        SELECT
            off.t_id AS source_id,
            off.time::TIME AS time_of_day,
            off.quantity_sold::INTEGER AS quantity_sold,
            off.unit_price::NUMERIC(10,2) AS unit_price,
			off.transaction_date::DATE AS transaction_date,
            'sa_offline_sales' AS source_system,
            'src_offline_sales' AS source_entity,
            cust.customer_id AS dim_customer_id,
            st.store_id AS dim_store_id,
            prod.product_id AS dim_product_id,
            NULL AS dim_promotion_id
        FROM sa_offline_sales.src_offline_sales off
        LEFT JOIN BL_3NF.CE_CUSTOMER_SCD cust
               ON cust.source_id = off.customer_id
              AND cust.source_system = 'sa_offline_sales'
              AND cust.source_entity = 'src_offline_sales'
        LEFT JOIN BL_3NF.CE_STORES st
               ON st.source_id = off.store_id
              AND st.source_system = 'sa_offline_sales'
              AND st.source_entity = 'src_offline_sales'
        LEFT JOIN BL_3NF.CE_PRODUCTS prod
               ON prod.source_id = off.product_id
              AND prod.source_system = 'sa_offline_sales'
              AND prod.source_entity = 'src_offline_sales'
        
        UNION ALL
        
        SELECT
            onl.transaction_id AS source_id,
            '00:00:00'::TIME AS time_of_day,
            onl.quantity_sold::INTEGER AS quantity_sold,
            onl.unit_price::NUMERIC(10,2) AS unit_price,
			NULL::DATE AS transaction_date,
			'sa_online_sales' AS source_system,
            'src_online_sales' AS source_entity,
            cust.customer_id AS dim_customer_id,
            st.store_id AS dim_store_id,
            prod.product_id AS dim_product_id,
            promo.promotion_id AS dim_promotion_id
        FROM sa_online_sales.src_online_sales onl
        LEFT JOIN BL_3NF.CE_CUSTOMER_SCD cust
               ON cust.source_id = onl.customer_id
              AND cust.source_system = 'sa_online_sales'
              AND cust.source_entity = 'src_online_sales'
        LEFT JOIN BL_3NF.CE_STORES st
               ON st.source_id = onl.store
              AND st.source_system = 'sa_online_sales'
              AND st.source_entity = 'src_online_sales'
        LEFT JOIN BL_3NF.CE_PRODUCTS prod
               ON prod.source_id = onl.product_id
              AND prod.source_system = 'sa_online_sales'
              AND prod.source_entity = 'src_online_sales'
        LEFT JOIN BL_3NF.CE_PROMOTION promo
               ON promo.source_id = onl.promotion_applied
              AND promo.source_system = 'sa_online_sales'
              AND promo.source_entity = 'src_online_sales'
    ) AS cs
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_3NF.CE_SALES existing
        WHERE existing.source_id = cs.source_id
          AND existing.source_system = cs.source_system
          AND existing.source_entity = cs.source_entity
    );
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
        PERFORM BL_CL.log_procedure_action('load_sales', rows_affected, 'Sales loaded successfully');

EXCEPTION
    WHEN OTHERS THEN
        error_message := SQLERRM; 
        PERFORM BL_CL.log_procedure_action('load_sales', 0, 'Error occurred during sales load: ' || error_message);
        RAISE;
END;
$$;


-- Call the procedures
CALL BL_CL.load_categories();
SELECT * FROM BL_3NF.CE_CATEGORIES LIMIT 10;

CALL BL_CL.load_products();
SELECT * FROM BL_3NF.CE_PRODUCTS LIMIT 10;
------
ALTER TABLE BL_3NF.CE_STORES ALTER COLUMN state TYPE VARCHAR(100);
------
CALL BL_CL.load_stores();
SELECT * FROM BL_3NF.CE_STORES LIMIT 10;

CALL BL_CL.load_dates();
SELECT * FROM BL_3NF.CE_DATES LIMIT 10;

CALL BL_CL.load_suppliers();
SELECT * FROM BL_3NF.CE_SUPPLIERS LIMIT 10;

CALL BL_CL.load_sales();
SELECT * FROM BL_3NF.CE_SALES LIMIT 100;


-- Check procedure logs
SELECT * FROM BL_CL.procedure_logs;