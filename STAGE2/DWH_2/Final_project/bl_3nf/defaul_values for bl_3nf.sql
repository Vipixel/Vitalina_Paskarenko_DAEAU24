-- Create procedure for sequences
CREATE OR REPLACE PROCEDURE BL_3NF.create_sequences_for_3nf_tables_procedure()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Create sequences for tables
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.category_id_seq;
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.supplier_id_seq;
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.product_id_seq;
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.customer_id_seq;
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.store_id_seq;
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.promotion_id_seq;
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.transaction_id_seq;

    RAISE NOTICE '3NF sequences are created';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '3NF sequences are not created: %', SQLERRM;
END;
$$;

-- Call the procedure to create sequences
CALL BL_3NF.create_sequences_for_3nf_tables_procedure();

-- Create procedure for inserting default rows
CREATE OR REPLACE PROCEDURE BL_3NF.insert_default_rows_procedure()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Insert default rows for CE_SUPPLIERS
    INSERT INTO BL_3NF.CE_SUPPLIERS (supplier_id, source_id, source_entity, source_system)
    SELECT -1, '-1', 'MANUAL', 'MANUAL'
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_3NF.CE_SUPPLIERS WHERE supplier_id = -1
    );

    -- Insert default rows for CE_CUSTOMER_SCD
    INSERT INTO BL_3NF.CE_CUSTOMER_SCD (customer_id, customer_age, customer_level, gender, customer_income, source_id, source_entity, source_system)
    SELECT -1, -1, 'n.a.', 'n.a.', -1, '-1', 'MANUAL', 'MANUAL'
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_3NF.CE_CUSTOMER_SCD WHERE customer_id = -1
    );

    -- Insert default rows for CE_STORES
    INSERT INTO BL_3NF.CE_STORES (store_id, store_location, state, source_id, source_entity, source_system)
    SELECT -1, 'n.a.', 'n.a.', '-1', 'MANUAL', 'MANUAL'
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_3NF.CE_STORES WHERE store_id = -1
    );

    -- Insert default rows for CE_CATEGORIES
    INSERT INTO BL_3NF.CE_CATEGORIES (category_id, category_name, source_id, source_entity, source_system)
    SELECT -1, 'n.a.', '-1', 'MANUAL', 'MANUAL'
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_3NF.CE_CATEGORIES WHERE category_id = -1
    );

    -- Insert default rows for CE_PRODUCTS
    INSERT INTO BL_3NF.CE_PRODUCTS (product_id, product_name, category_id, unit_price, source_id, source_entity, source_system)
    SELECT -1, 'n.a.', -1, 0, '-1', 'MANUAL', 'MANUAL'
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_3NF.CE_PRODUCTS WHERE product_id = -1
    );

    -- Insert default rows for CE_PROMOTION
    INSERT INTO BL_3NF.CE_PROMOTION (promotion_id, promotion_applied, source_id, source_entity, source_system)
    SELECT -1, 'n.a.', '-1', 'MANUAL', 'MANUAL'
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_3NF.CE_PROMOTION WHERE promotion_id = -1
    );

    -- Insert default rows for CE_DATES
    INSERT INTO BL_3NF.CE_DATES (transaction_date, source_id, source_entity, source_system)
    SELECT '1900-01-01'::DATE, 'MANUAL', 'MANUAL', 'MANUAL'
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_3NF.CE_DATES WHERE transaction_date = '1900-01-01'
        AND source_id = 'MANUAL' AND source_entity = 'MANUAL' AND source_system = 'MANUAL'
    );

    -- Insert default rows for CE_SALES
    INSERT INTO BL_3NF.CE_SALES (t_id, customer_id, store_id, product_id, time, promotion_id, unit_price, quantity_sold, source_id, source_entity, source_system)
    SELECT -1, -1, -1, -1, '00:00:00'::TIME, -1, 0.00, 0, '-1', 'MANUAL', 'MANUAL'
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_3NF.CE_SALES WHERE t_id = -1
    );

    RAISE NOTICE 'Default rows inserted into BL_3NF tables';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error occurred while inserting default rows: %', SQLERRM;
END;
$$;

-- Call the procedure to insert default rows
CALL BL_3NF.insert_default_rows_procedure();