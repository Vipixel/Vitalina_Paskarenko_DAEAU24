-----task 1 

CREATE VIEW sales_revenue_by_category_qtr AS
SELECT c.name AS category_name,  SUM(p.amount) AS sales_revenue_qtr
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN inventory i ON fc.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
WHERE 
    EXTRACT(YEAR FROM p.payment_date) = 2017
    AND EXTRACT(QUARTER FROM p.payment_date) = 1
GROUP BY c.name
HAVING SUM(p.amount) > 0;
---Tried if this work

SELECT * 
FROM sales_revenue_by_category_qtr
WHERE category_name = 'Action';

----task 2

CREATE FUNCTION get_sales_revenue_by_category_qtr( input_year INT,input_quarter INT)
RETURNS TABLE (
    category_name TEXT,
    sales_revenue NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.name AS category_name,
        SUM(p.amount) AS sales_revenue
    FROM category c
    JOIN film_category fc ON c.category_id = fc.category_id
    JOIN inventory i ON fc.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
    WHERE 
        EXTRACT(YEAR FROM p.payment_date) = input_year
        AND EXTRACT(QUARTER FROM p.payment_date) = input_quarter
    GROUP BY c.name
    HAVING 
        SUM(p.amount) > 0;
END;
$$;
---Tried if this work
SELECT * 
FROM get_sales_revenue_by_category_qtr(2017, 2);
