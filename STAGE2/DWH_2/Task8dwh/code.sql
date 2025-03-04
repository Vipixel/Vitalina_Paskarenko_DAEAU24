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
    v_sql TEXT;
    rows_affected INT := 0;
    rows_inserted INT := 0;
BEGIN
    FOR rec IN
        SELECT DISTINCT
            transaction_date::DATE AS date_dt,
            EXTRACT(DAY FROM transaction_date::DATE) AS day_of_month,
            EXTRACT(MONTH FROM transaction_date::DATE) AS month_num,
            EXTRACT(YEAR FROM transaction_date::DATE) AS year_num,
            EXTRACT(QUARTER FROM transaction_date::DATE) AS quarter_num,
            EXTRACT(WEEK FROM transaction_date::DATE) AS week_of_year,
            EXTRACT(DOW FROM transaction_date::DATE) AS day_of_week,
            EXTRACT(DOY FROM transaction_date::DATE) AS day_of_year
        FROM BL_3NF.CE_DATES
        WHERE EXTRACT(YEAR FROM transaction_date::DATE) BETWEEN 1900 AND 2100
    LOOP
        -- Build dynamic UPSERT query using ON CONFLICT (date_dt)
        v_sql := '
            INSERT INTO BL_DM.DIM_DATES AS tgt
                (date_dt, day_of_week, day_of_month, day_of_year, week_of_year, month, quarter, year)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            ON CONFLICT (date_dt) DO NOTHING
        ';

        EXECUTE v_sql
         USING rec.date_dt,
               rec.day_of_week,
               rec.day_of_month,
               rec.day_of_year,
               rec.week_of_year,
               rec.month_num,
               rec.quarter_num,
               rec.year_num;

        -- Track how many inserted. In plpgsql, we can grab ROW_COUNT right after the EXECUTE.
        GET DIAGNOSTICS rows_inserted = ROW_COUNT;
        rows_affected := rows_affected + rows_inserted;
    END LOOP;

    -- Log the total new rows
    PERFORM BL_CL.log_procedure_action('load_dm_dates', rows_affected, 'Dates loaded successfully into DM');
EXCEPTION
    WHEN OTHERS THEN
        PERFORM BL_CL.log_procedure_action('load_dm_dates', rows_affected, 'Error loading dates: ' || SQLERRM);
END;
$$;
------ Load DM_DATES
CALL BL_CL.load_dm_dates();
SELECT * FROM BL_DM.DIM_DATES LIMIT 100;

------
CREATE OR REPLACE PROCEDURE BL_CL.load_dim_customer_scd()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    rows_affected INT := 0;
    
    existing_rec RECORD;
    v_select TEXT;
    v_update TEXT;
    v_insert TEXT;
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
        ------Check for an active record
        v_select := '
            SELECT customer_surr_id,
                   customer_age,
                   customer_level,
                   gender,
                   customer_income,
                   start_dt,
                   end_dt
              FROM BL_DM.DIM_CUSTOMER_SCD
             WHERE customer_id = $1
               AND is_active = ''Y''
             LIMIT 1
        ';
        
        EXECUTE v_select USING rec.customer_id INTO existing_rec;

        IF existing_rec.customer_surr_id IS NULL THEN
            v_insert := '
                INSERT INTO BL_DM.DIM_CUSTOMER_SCD (
                    customer_id,
                    customer_age,
                    customer_level,
                    gender,
                    customer_income,
                    start_dt,
                    end_dt,
                    is_active,
                    insert_dt,
                    update_dt
                )
                VALUES (
                    $1, $2, $3, $4, $5,
                    NOW(),
                    ''9999-12-31'',
                    ''Y'',
                    NOW(),
                    NOW()
                )
            ';
            EXECUTE v_insert
             USING rec.customer_id,
                   rec.customer_age,
                   rec.customer_level,
                   rec.gender,
                   rec.customer_income;
            
            GET DIAGNOSTICS rows_affected = ROW_COUNT; 
            
        ELSE
            IF (  existing_rec.customer_age       <> rec.customer_age
               OR existing_rec.customer_level     <> rec.customer_level
               OR existing_rec.gender            <> rec.gender
               OR existing_rec.customer_income   <> rec.customer_income
               )
            THEN
                v_update := '
                    UPDATE BL_DM.DIM_CUSTOMER_SCD
                       SET end_dt   = NOW(),
                           is_active = ''N'',
                           update_dt = NOW()
                     WHERE customer_surr_id = $1
                ';
                EXECUTE v_update USING existing_rec.customer_surr_id;
                
                ----- Insert the changed record with open end_dt
                v_insert := '
                    INSERT INTO BL_DM.DIM_CUSTOMER_SCD (
                        customer_id,
                        customer_age,
                        customer_level,
                        gender,
                        customer_income,
                        start_dt,
                        end_dt,
                        is_active,
                        insert_dt,
                        update_dt
                    )
                    VALUES (
                        $1, $2, $3, $4, $5,
                        NOW(),
                        ''9999-12-31'',
                        ''Y'',
                        NOW(),
                        NOW()
                    )
                ';
                EXECUTE v_insert
                 USING rec.customer_id,
                       rec.customer_age,
                       rec.customer_level,
                       rec.gender,
                       rec.customer_income;
                
                GET DIAGNOSTICS rows_affected = ROW_COUNT;
            END IF;
        END IF;
    END LOOP;

   ---- Log the procedure execution
    PERFORM BL_CL.log_procedure_action('load_dim_customer_scd', rows_affected, 'Customers loaded/updated in SCD');
END;
$$;
--------
ALTER TABLE BL_DM.dim_customer_scd 
ADD COLUMN effective_dt DATE NOT NULL DEFAULT CURRENT_DATE;

-------- Load DIM_CUSTOMERS_SCD
CALL BL_CL.load_dim_customer_scd();
SELECT * FROM BL_DM.DIM_CUSTOMER_SCD LIMIT 10;
------
------
CREATE OR REPLACE PROCEDURE BL_CL.load_dim_stores()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    v_sql TEXT;
    rows_affected INT := 0;
    affected INT := 0;
BEGIN
    FOR rec IN
        SELECT
            store_id,
            store_location,
            state
        FROM BL_3NF.CE_STORES
    LOOP
        v_sql := '
            INSERT INTO BL_DM.DIM_STORES AS ds
                (store_id, store_location, state, insert_dt, update_dt)
            VALUES (
                $1, $2, $3,
                NOW(),
                NOW()
            )
            ON CONFLICT (store_id)
            DO UPDATE
               SET store_location = EXCLUDED.store_location,
                   state          = EXCLUDED.state,
                   update_dt      = NOW()
               WHERE ds.store_location <> EXCLUDED.store_location
                  OR ds.state          <> EXCLUDED.state
        ';

        EXECUTE v_sql USING rec.store_id,
                            rec.store_location,
                            rec.state;
        -- Count how many rows changed (INSERT/UPDATE)
        GET DIAGNOSTICS affected = ROW_COUNT;
        rows_affected := rows_affected + affected;
    END LOOP;

    -- Log the procedure execution
    PERFORM BL_CL.log_procedure_action('load_dim_stores', rows_affected, 'Stores loaded/updated successfully');
END;
$$;
---added alter tables
ALTER TABLE BL_DM.DIM_STORES 
ALTER COLUMN state TYPE VARCHAR(50);

ALTER TABLE BL_DM.DIM_STORES 
ADD CONSTRAINT dim_stores_store_id_uk UNIQUE (store_id);

-------- Load DM_STORES
CALL BL_CL.load_dim_stores();
SELECT * FROM BL_DM.DIM_STORES LIMIT 10;

------------
------------
CREATE OR REPLACE PROCEDURE BL_CL.load_dim_promotion()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    v_sql TEXT;
    rows_affected INT := 0;
    affected INT := 0;
BEGIN
    FOR rec IN
        SELECT
            promotion_id,
            promotion_applied
        FROM BL_3NF.CE_PROMOTION
    LOOP
        v_sql := '
            INSERT INTO BL_DM.DIM_PROMOTION AS dp
                (promotion_surr_id, promotion_id, promotion_applied, insert_dt, update_dt)
            VALUES (
                nextval(''BL_DM.promotion_surr_id_seq''),
                $1, $2,
                NOW(),
                NOW()
            )
            ON CONFLICT (promotion_id)
            DO UPDATE
               SET promotion_applied = EXCLUDED.promotion_applied,
                   update_dt         = NOW()
               WHERE dp.promotion_applied <> EXCLUDED.promotion_applied
        ';

        EXECUTE v_sql USING rec.promotion_id, rec.promotion_applied;

        GET DIAGNOSTICS affected = ROW_COUNT;
        rows_affected := rows_affected + affected;
    END LOOP;

    PERFORM BL_CL.log_procedure_action('load_dim_promotion', rows_affected, 'Promotions loaded/updated successfully');
END;
$$;
----
ALTER TABLE BL_DM.DIM_PROMOTION 
ADD CONSTRAINT dim_promotion_promotion_id_uk UNIQUE (promotion_id);

------ Load DM_PROMOTION
CALL BL_CL.load_dim_promotion();
SELECT * FROM BL_DM.DIM_PROMOTION LIMIT 10;
--------

CREATE OR REPLACE PROCEDURE BL_CL.load_fct_sales_dd()
LANGUAGE plpgsql
AS $$
DECLARE
    rows_inserted INT := 0;
BEGIN
    INSERT INTO BL_DM.FCT_SALES_DD
        ( transaction_id,
         customer_surr_id,
         store_surr_id,
         product_surr_id,
         promotion_surr_id,
         quantity_sold,
         total_cost,
         time,
         source_entity,
         source_system
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

ALTER TABLE BL_DM.FCT_SALES_DD 
ALTER COLUMN date_dt DROP NOT NULL;


-- Load FCT_SALES_DD
CALL BL_CL.load_fct_sales_dd();
SELECT * FROM BL_DM.FCT_SALES_DD ;