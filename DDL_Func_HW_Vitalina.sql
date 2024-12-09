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
    countries TEXT[]
)
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
    JOIN rental r ON s.store_id = r.staff_id 
    JOIN film f ON r.rental_id = f.film_id
    JOIN language l ON f.language_id = l.language_id
    WHERE LOWER(c.country) = ANY(ARRAY(SELECT LOWER(cname) FROM UNNEST(countries) AS cname))
    GROUP BY c.country, f.title, f.rating, l.name, f.length, f.release_year
    ORDER BY c.country, COUNT(r.rental_id) DESC
	FETCH FIRST 1 ROW ONLY;
END;
$$;
-----to check if it is work
SELECT *
FROM most_popular_films_by_countries(ARRAY ['australia', 'brazil', 'UNITED States']);

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

----insered new language
INSERT INTO language (name) VALUES ('Klingon');
----
CREATE OR REPLACE FUNCTION new_movie(
    movie_title TEXT,
    release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT,
    language_name TEXT DEFAULT 'Klingon')
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    new_film_id INT;
    lang_id INT; 
BEGIN
-----Ensure the language exists in the language table
    SELECT l.language_id INTO lang_id
    FROM language l
    WHERE l.name = language_name;
----created to generate a new unique film ID
    SELECT COALESCE(MAX(f.film_id), 0) + 1 INTO new_film_id FROM film f;

----Insert the new movie into the film table
    INSERT INTO film (
        film_id,
        title,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        replacement_cost,
        last_update
    ) VALUES (
        new_film_id,
        movie_title,
        release_year,
        lang_id, 
        3,            
        4.99,        
        19.99,         
        CURRENT_TIMESTAMP  
    );
END;
$$;

-----tested if it is work
SELECT new_movie('Star 2 Trek Adventures');

SELECT * 
FROM film
WHERE title IN ('Star 2 Trek Adventures');

--------task 6

-- What operations do the following functions perform:
-- film_in_stock --beter to use function films_in_stock_by_title
---film_not_in_stock --- shows if this film in stock, most useful for shops 
-- inventory_in_stock - boolean(true/false) if 'requested_id' in stock so it is write - 'true' if not - 'false' 
-- get_customer_balance - shows customer balance in effective date
-- inventory_held_by_custome -shows details about inventory item held by customer 
-- rewards_report - must show the minimum number purchases, minimum dollas spent generated report
-- last_day - the last date when data was inserded in the raport

-- Why does ‘rewards_report’ function return 0 rows? Correct and recreate the function, so that it's able to return rows properly.
CREATE OR REPLACE FUNCTION rewards_report(
    min_monthly_purchases INTEGER,
    min_dollar_amount_purchased NUMERIC)
RETURNS TABLE (
    customer_id INT,
    first_name VARCHAR,
    last_name VARCHAR,
    total_amount NUMERIC,
    purchase_count INT)
LANGUAGE plpgsql
AS 
$$
DECLARE
    last_month_start DATE;
    last_month_end DATE;
BEGIN
    -- Validate input parameters
    IF min_monthly_purchases <= 0 THEN
        RAISE EXCEPTION 'Minimum monthly purchases parameter must be > 0';
    END IF;
    IF min_dollar_amount_purchased <= 0 THEN
        RAISE EXCEPTION 'Minimum monthly dollar amount purchased parameter must be > $0.00';
    END IF;

    -- Calculate the start and end of the last month
    last_month_start := DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month');
    last_month_end := LAST_DAY(last_month_start);
    -- Query customers meeting reward criteria
    RETURN QUERY
    SELECT 
        c.customer_id,
        c.first_name::VARCHAR,  -- Explicit cast to VARCHAR
        c.last_name::VARCHAR,   -- Explicit cast to VARCHAR
        SUM(p.amount) AS total_amount,
        COUNT(p.payment_id)::INT AS purchase_count
    FROM customer c
    JOIN payment p ON c.customer_id = p.customer_id
    WHERE DATE(p.payment_date) BETWEEN last_month_start AND last_month_end -----I think this gap is to little to have some raport, maybe insted I offered to use 3 months
    GROUP BY c.customer_id, c.first_name, c.last_name
    HAVING 
        SUM(p.amount) > min_dollar_amount_purchased
        AND COUNT(p.payment_id) > min_monthly_purchases;	
END;
$$;

---tested if this function work
SELECT * FROM rewards_report(1, 4.00);

-- Is there any function that can potentially be removed from the dvd_rental codebase? If so, which one and why?
I think this function film_in_stock it is not so useful to use, better films_in_stock_by_title and more simply to use

--- The ‘get_customer_balance’ function describes the business requirements for calculating the client balance. 
--Unfortunately, not all of them are implemented in this function. Try to change function using the requirements from the comments

DECLARE
    v_rentfees DECIMAL(5,2); --#FEES PAID TO RENT THE VIDEOS INITIALLY
    v_overfees INTEGER;      --#LATE FEES FOR PRIOR RENTALS
    v_payments DECIMAL(5,2); --#SUM OF PAYMENTS MADE PREVIOUSLY
BEGIN
    SELECT COALESCE(SUM(film.rental_rate),0) INTO v_rentfees
    FROM film, inventory, rental
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;

    SELECT COALESCE(SUM(CASE
						    WHEN (rental.return_date - rental.rental_date) > (film.rental_duration * 2 * '1 day'::interval) ---added extra condition 
                           THEN film.replacement_cost 
                           WHEN (rental.return_date - rental.rental_date) > (film.rental_duration * '1 day'::interval)
                           THEN EXTRACT(epoch FROM ((rental.return_date - rental.rental_date) - (film.rental_duration * '1 day'::interval)))::INTEGER / 86400 -- * 1 dollar
                           ELSE 0
                        END),0) 
    INTO v_overfees
    FROM rental, inventory, film
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;
	  
    SELECT COALESCE(SUM(payment.amount),0) INTO v_payments
    FROM payment
    WHERE payment.payment_date <= p_effective_date
    AND payment.customer_id = p_customer_id;

    RETURN v_rentfees + v_overfees - v_payments;
END

-- * How do ‘group_concat’ and ‘_group_concat’ functions work? (database creation script might help) Where are they used?
---I dont have ‘group_concat’ only ‘_group_concat’ -- $1 references the first parameter passed to the function, $2 would refer to the second and so on
-- so  WHEN $2 IS NULL THEN $1, if  second value is null it will return first value

-- * What does ‘last_updated’ function do? Where is it used?
-- it was hard to find, so it is a trigger function what used when some event happening like in this case 'update' column automatically writte a current date in the table

-- BEGIN
--     NEW.last_update = CURRENT_TIMESTAMP;
--     RETURN NEW;
-- END 

-- * What is tmpSQL variable for in ‘rewards_report’ function? Can this function be recreated without EXECUTE statement and dynamic SQL? Why?
 ---in this function  is  used to store a dynamic SQL query. Yes, this function can be recreated without EXECUTE and dynamic 
 -- Static queries are more simpler, safer,and less likely to have errors.We need dynamic SQL when the query structure changes  and we can t solve the problem with regular sql 
