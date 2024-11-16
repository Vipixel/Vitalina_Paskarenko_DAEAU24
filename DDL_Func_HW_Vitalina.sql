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
------Task 3
CREATE OR REPLACE FUNCTION most_popular_films_by_countries(
    countries TEXT[])
RETURNS TABLE (
    country TEXT,
    film TEXT,
    rating TEXT,
    language TEXT,
    length INT,
    release_year INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.country AS country,
        f.title AS film,
        f.rating::TEXT AS rating,
        l.name::TEXT AS language,
        f.length::INT AS length,  
        f.release_year::INT AS release_year  
    FROM country c
    JOIN city ct ON c.country_id = ct.country_id
    JOIN address a ON a.city_id = ct.city_id
    JOIN store s ON a.address_id = s.address_id
    JOIN inventory i ON s.store_id = i.store_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
    JOIN film f ON f.film_id = i.film_id
    JOIN language l ON f.language_id = l.language_id
    WHERE c.country = ANY(countries)
    GROUP BY c.country, f.title, f.rating, l.name, f.length, f.release_year
    ORDER BY c.country, COUNT(r.rental_id) DESC;
END;
$$;

----checked if this function work
SELECT * 
FROM most_popular_films_by_countries(ARRAY['Australia', 'Brazil', 'United States']);

-----Task 4

CREATE OR REPLACE FUNCTION films_in_stock_by_title(
    title_f TEXT)
RETURNS TABLE (
    row_num BIGINT,
    title VARCHAR,
    language VARCHAR,
    customer VARCHAR,
    rental_date TIMESTAMP WITH TIME ZONE)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        row_number() OVER (ORDER BY f.title) AS row_num,
        f.title::VARCHAR AS title,
        l.name::VARCHAR AS language,
        CONCAT(c.first_name, ' ', c.last_name)::VARCHAR AS customer,
        r.rental_date
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
    JOIN customer c ON r.customer_id = c.customer_id
    JOIN language l ON f.language_id = l.language_id
    WHERE f.title ILIKE title_f 
      AND i.inventory_id NOT IN (
          SELECT inventory_id 
          FROM rental 
          WHERE return_date IS NULL);

    -- If no movies are found will show a notice
    IF NOT FOUND THEN
        RAISE NOTICE 'No movies matching the title "%".', title_f;
    END IF;
END;
$$;

----checked if this function work
SELECT * FROM films_in_stock_by_title('%love%');