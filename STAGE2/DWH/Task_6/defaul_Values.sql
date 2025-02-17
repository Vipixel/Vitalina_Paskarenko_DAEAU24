
INSERT INTO BL_3NF.CE_SUPPLIERS (supplier_id, source_id, source_entity, source_system)
SELECT supplier_id, source_id, source_entity, source_system
FROM 
(VALUES (-1, '-1', 'MANUAL', 'MANUAL')) 
AS default_row(supplier_id, source_id, source_entity, source_system)
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_SUPPLIERS WHERE BL_3NF.CE_SUPPLIERS.supplier_id = default_row.supplier_id
);
COMMIT;


INSERT INTO BL_3NF.CE_CUSTOMER_SCD (customer_id, customer_age, customer_level, gender, customer_income,  source_id, source_entity, source_system)
SELECT customer_id, customer_age, customer_level, gender, customer_income, source_id, source_entity, source_system
FROM 
(VALUES (-1, -1, 'n.a.', 'n.a.', -1, '-1', 'MANUAL', 'MANUAL')) 
AS default_row(customer_id, customer_age, customer_level, gender, customer_income, source_id, source_entity, source_system)
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_CUSTOMER_SCD WHERE BL_3NF.CE_CUSTOMER_SCD.customer_id = default_row.customer_id
);
COMMIT;

INSERT INTO BL_3NF.CE_STORES (store_id, store_location, state, source_id, source_entity, source_system)
SELECT store_id, store_location, state, source_id, source_entity, source_system
FROM 
(VALUES (-1, 'n.a.', 'n.a.', '-1', 'MANUAL', 'MANUAL')) 
AS default_row(store_id, store_location, state, source_id, source_entity, source_system)
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_STORES WHERE BL_3NF.CE_STORES.store_id = default_row.store_id
);
COMMIT;

INSERT INTO BL_3NF.CE_CATEGORIES (category_id, category_name, source_id, source_entity, source_system)
SELECT category_id, category_name, source_id, source_entity, source_system
FROM 
(VALUES (-1, 'n.a.', '-1', 'MANUAL', 'MANUAL')) 
AS default_row(category_id, category_name, source_id, source_entity, source_system)
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_CATEGORIES WHERE BL_3NF.CE_CATEGORIES.category_id = default_row.category_id
);
COMMIT;

INSERT INTO BL_3NF.CE_PRODUCTS (product_id, product_name, category_id, unit_price, source_id, source_entity, source_system)
SELECT product_id, product_name, category_id, unit_price, source_id, source_entity, source_system
FROM 
(VALUES (-1, 'n.a.', -1, 0, '-1', 'MANUAL', 'MANUAL')) 
AS default_row(product_id, product_name, category_id, unit_price, source_id, source_entity, source_system)
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_PRODUCTS WHERE BL_3NF.CE_PRODUCTS.product_id = default_row.product_id
);
COMMIT;

INSERT INTO BL_3NF.CE_PROMOTION (promotion_id, promotion_applied, source_id, source_entity, source_system)
SELECT promotion_id, promotion_applied, source_id, source_entity, source_system
FROM 
(VALUES (-1, 'n.a.', 0.00, '-1', 'MANUAL', 'MANUAL')) 
AS default_row(promotion_id, promotion_applied,source_id, source_entity, source_system)
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_PROMOTION WHERE BL_3NF.CE_PROMOTION.promotion_id = default_row.promotion_id
);
COMMIT;

INSERT INTO BL_3NF.CE_DATES ( transaction_date, source_id, source_entity, source_system)
SELECT transaction_date, source_id, source_entity, source_system
FROM 
(VALUES ('1900-01-01'::DATE, 1900, 1, 1, '-1', 'MANUAL', 'MANUAL'))
AS default_row( transaction_date, source_id, source_entity, source_system)
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_DATES WHERE BL_3NF.CE_DATES.date_id = default_row.date_id
);
COMMIT;

INSERT INTO BL_3NF.CE_SALES_DD (t_id, customer_id, store_id,  product_id, time, promotion_id, unit_price, quantity_sold, source_id, source_entity, source_system)
SELECT t_id, customer_id, store_id, product_id, time, promotion_id, unit_price, quantity_sold, source_id, source_entity, source_system
FROM
(VALUES (-1, -1, -1, -1, '00:00:00'::TIME, -1, 0.00, 0, '-1', 'MANUAL', 'MANUAL')) 
AS default_row(t_id, customer_id, store_id,  product_id, time, promotion_id, unit_price, quantity_sold, source_id, source_entity, source_system)
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_SALES_DD WHERE BL_3NF.CE_SALES_DD.t_id = default_row.t_id
);
COMMIT;
