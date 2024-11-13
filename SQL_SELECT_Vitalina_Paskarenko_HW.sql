-- All animation movies released between 2017 and 2019 with rate more than 1, alphabetical -- 
-- I  use a connection from the "film" table to the "category" table through the intermediate "film_category" table. Order by title --

SELECT *
FROM film 
JOIN film_category ON film.film_id = film_category.film_id
JOIN category ON film_category.category_id = category.category_id
WHERE category.name = 'Animation'
	AND film.release_year BETWEEN 2017 AND 2019
  	AND film.rental_rate > 1
ORDER by film.title ASC;


--Top-5 actors by number of movies (released since 2015) 

SELECT 
    LOWER(actor.first_name) AS first_name, 
    LOWER(actor.last_name) AS last_name,
    COUNT(film.film_id) AS number_of_movies
FROM public.actor
JOIN public.film_actor ON actor.actor_id = film_actor.actor_id
JOIN public.film ON film_actor.film_id = film.film_id
WHERE film.release_year >= 2015
GROUP BY actor.actor_id, actor.first_name, actor.last_name
ORDER BY number_of_movies DESC
OFFSET 0 LIMIT 5;

----Number of Drama, Travel, Documentary per year

SELECT film.release_year,
       COUNT(CASE WHEN LOWER(category.name) = 'drama' THEN 1 END) AS num_drama_movies, -- Counts Drama movies for each year
       COUNT(CASE WHEN LOWER(category.name) = 'travel' THEN 1 END) AS num_travel_movies, -- Counts Travel movies for each year
       COUNT(CASE WHEN LOWER(category.name) = 'documentary' THEN 1 END) AS num_doc_movies -- Counts Documentary movies for each year
FROM film
JOIN film_category ON film.film_id = film_category.film_id
JOIN category ON film_category.category_id = category.category_id 
WHERE category.name IN ('Drama', 'Travel', 'Documentary')
GROUP BY film.release_year -- Groups results by release year so I can count movies per year
ORDER BY film.release_year DESC;

--For each client, display a list of horrors that he had ever rented (in one column, separated by commas), and the amount of money that he paid for it

SELECT customer.customer_id,
       CONCAT(customer.first_name, ' ', customer.last_name) AS customer_name,
       array_to_string(array_agg(film.title), ', ') AS horror_movies, -- made a research to find this function
       SUM(payment.amount) AS total_paid
FROM customer
JOIN rental ON customer.customer_id = rental.customer_id ---could you suggest how I can optimase this? or what a differnt way to solve this query?
JOIN inventory ON rental.inventory_id = inventory.inventory_id
JOIN film ON inventory.film_id = film.film_id
JOIN film_category ON film.film_id = film_category.film_id
JOIN category ON film_category.category_id = category.category_id
JOIN payment ON rental.rental_id = payment.rental_id
WHERE category.name = 'Horror'
GROUP BY customer.customer_id, customer.first_name, customer.last_name
ORDER BY customer_name;
---------------------------------------------
---Part 2.1: Solve the following problems using SQL
-- total revenue per staff member for 2017
SELECT 
    staff.staff_id, 
    staff.first_name || ' ' || staff.last_name AS staff_name,  
    recent_store.store_id AS last_store,  
    total_revenue  
FROM (
    -- Calculate total revenue per employee and find the last store worked in 2017
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
    GROUP BY staff.staff_id, staff.first_name, staff.last_name, store.store_id  -- group by employee and store
) AS recent_store  -- end of sbquery, provides data on revenue and the last store per employee
ORDER BY total_revenue DESC  ---- select only the top 3 employees with the highest revenue
LIMIT 3;

-- Find the top 5 most rented movies and determine the expected audience age based on ratings
SELECT 
    film.film_id,  
    film.title,  
    rental_count,  -- number of times the movie was rented
    CASE 
        WHEN film.rating = 'G' THEN 'All ages' 
        WHEN film.rating = 'PG' THEN '10+'      
        WHEN film.rating = 'PG-13' THEN '13+'   
        WHEN film.rating = 'R' THEN '17+'       
        WHEN film.rating = 'NC-17' THEN '18+'   
        ELSE 'Unknown'                          -- if ratiing is unknown, we call it as 'Unknown'
    END AS expected_audience_age  -- we give an audience age range based on the rating
FROM (
    -- Subquery to count the number of rentals for each movie
    SELECT 
        film.film_id,
        film.title,
        film.rating,
        COUNT(rental.rental_id) AS rental_count  -- count how many times each movie was rented
    FROM film
    JOIN inventory ON film.film_id = inventory.film_id 
    JOIN rental ON inventory.inventory_id = rental.inventory_id  
    GROUP BY film.film_id, film.title, film.rating  -- 
) AS movie_rental_counts  -- end of the subquery naming it "movie_rental_counts"
ORDER BY rental_count DESC  
LIMIT 5;  