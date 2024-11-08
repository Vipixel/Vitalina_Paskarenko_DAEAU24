-- All animation movies released between 2017 and 2019 with rate more than 1, alphabetical -- 
-- I  use a connection from the "film" table to the "category" table through the intermediate "film_category" table. Order by title --

SELECT title, description, release_year, rating
FROM film 
JOIN film_category ON film.film_id = film_category.film_id
JOIN category ON film_category.category_id = category.category_id
WHERE category.name = 'Animation'
	AND film.release_year BETWEEN 2017 AND 2019
  	AND film.rental_rate > 1
ORDER by film.title ASC;

-- The revenue earned by each rental store since March 2017

SELECT 
    address.address || COALESCE(' ' || address.address2, '') AS full_address,
    SUM(payment.amount) AS revenue
FROM store
JOIN address ON store.address_id = address.address_id
JOIN staff ON store.store_id = staff.store_id
JOIN rental ON staff.staff_id = rental.staff_id
JOIN payment ON rental.rental_id = payment.rental_id
WHERE payment.payment_date >= '2017-03-01'  -- Only include payments from March 2017 onwards
GROUP BY full_address  -- Group results by the combined address
ORDER BY revenue DESC;

--Top-5 actors by number of movies (released since 2015) 

SELECT actor.first_name, actor.last_name, COUNT(film.film_id) AS number_of_movies
FROM actor 
JOIN film_actor ON actor.actor_id = film_actor.actor_id --Joins category
JOIN film ON film_actor.film_id = film.film_id
WHERE film.release_year >= 2015
GROUP BY actor.actor_id, actor.first_name, actor.last_name
ORDER BY number_of_movies DESC
OFFSET 0 LIMIT 5;

----Number of Drama, Travel, Documentary per year

SELECT film.release_year,
       COUNT(CASE WHEN category.name = 'Drama' THEN 1 END) AS num_drama_movies, -- Counts Drama movies for each year
       COUNT(CASE WHEN category.name = 'Travel' THEN 1 END) AS num_travel_movies, -- Counts Travel movies for each year
       COUNT(CASE WHEN category.name = 'Documentary' THEN 1 END) AS num_doc_movies -- Counts Documentary movies for each year
FROM film
JOIN film_category ON film.film_id = film_category.film_id
JOIN category ON film_category.category_id = category.category_id 
WHERE category.name IN ('Drama', 'Travel', 'Documentary')
GROUP BY film.release_year -- Groups results by release year so I can count movies per year
ORDER BY film.release_year DESC;

--For each client, display a list of horrors that he had ever rented (in one column, separated by commas), and the amount of money that he paid for it

WITH horror_movies_cte AS (
    SELECT
        rental.customer_id,
        film.title,
        payment.amount
    FROM
        rental
    JOIN inventory ON rental.inventory_id = inventory.inventory_id
    JOIN film ON inventory.film_id = film.film_id
    JOIN film_category ON film.film_id = film_category.film_id
    JOIN category ON film_category.category_id = category.category_id
    JOIN payment ON rental.rental_id = payment.rental_id
    WHERE category.name = 'Horror'
)
SELECT
    customer.customer_id,
    CONCAT(customer.first_name, ' ', customer.last_name) AS customer_name,
    STRING_AGG(DISTINCT horror_movies_cte.title, ', ') AS horror_movies,
    SUM(horror_movies_cte.amount) AS total_paid
FROM
    customer
JOIN horror_movies_cte ON customer.customer_id = horror_movies_cte.customer_id
GROUP BY
    customer.customer_id, customer.first_name, customer.last_name
ORDER BY
    customer_name;

---------------------------------------------
---Part 2.1: total revenue per staff member for 2017
SELECT 
    recent_store.staff_id, 
    recent_store.first_name || ' ' || recent_store.last_name AS staff_name,  
    recent_store.store_id AS last_store,  
    total_revenue  
FROM (
    SELECT 
        staff.staff_id,
        staff.first_name,
        staff.last_name,
        store.store_id,
        SUM(payment.amount) AS total_revenue,  
        MAX(payment.payment_date) AS last_payment_date  
    FROM staff
    JOIN payment ON staff.staff_id = payment.staff_id  
    JOIN rental ON payment.rental_id = rental.rental_id  
    JOIN inventory ON rental.inventory_id = inventory.inventory_id  
    JOIN store ON inventory.store_id = store.store_id  
    WHERE EXTRACT(YEAR FROM payment.payment_date) = 2017  
    GROUP BY staff.staff_id, staff.first_name, staff.last_name, store.store_id
) AS recent_store
ORDER BY total_revenue DESC;

-- Find the top 5 most rented movies and determine the expected audience age based on ratings
SELECT 
    film.film_id,
    film.title,
    rental_data.rental_count,
    CASE 
        WHEN film.rating = 'G' THEN 'All ages' 
        WHEN film.rating = 'PG' THEN '10+'      
        WHEN film.rating = 'PG-13' THEN '13+'   
        WHEN film.rating = 'R' THEN '17+'       
        WHEN film.rating = 'NC-17' THEN '18+'   
        ELSE 'Unknown'  -- if rating is unknown, we call it 'Unknown'
    END AS expected_audience_age
FROM film
JOIN (
    -- Subquery to count the number of rentals for each movie
    SELECT 
        inventory.film_id,
        COUNT(rental.rental_id) AS rental_count
    FROM rental
    JOIN inventory ON rental.inventory_id = inventory.inventory_id
    GROUP BY inventory.film_id
) AS rental_data ON film.film_id = rental_data.film_id
ORDER BY rental_data.rental_count DESC
OFFSET 0 LIMIT 5;