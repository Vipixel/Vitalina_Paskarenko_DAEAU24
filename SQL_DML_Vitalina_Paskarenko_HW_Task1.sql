---- Added 3 movies
-- Insert "Pretty Woman"
INSERT INTO film (title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update, special_features)
SELECT 'Pretty Woman',
       'A rich entrepreneur hires Vivian, a prostitute, to accompany him to social events. Trouble ensues when he falls in love with her, and they try to bridge the gap between their worlds.',
       1990, 
       1, 
       null, 
       9, 
       4.99, 
       90, 
       50.00, 
       'PG', 
       CURRENT_DATE, 
       ARRAY['romantic comedy']
WHERE NOT EXISTS (
    SELECT 1 
    FROM film 
    WHERE title = 'Pretty Woman'
)
RETURNING film_id, title;

-- Insert "Avatar"
INSERT INTO film (title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update, special_features)
SELECT 'Avatar',
       'A paraplegic Marine dispatched to the moon Pandora on a unique mission becomes torn between following his orders and protecting the world he feels is his home.',
       2009, 
       1, 
       null, 
       7, 
       5.99, 
       162, 
       70.00, 
       'PG-13', 
       CURRENT_DATE, 
       ARRAY['sci-fi', 'adventure']
WHERE NOT EXISTS (
    SELECT 1 
    FROM film 
    WHERE title = 'Avatar'
)
RETURNING film_id, title;

-- Insert "Time"
INSERT INTO film (title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update, special_features)
SELECT 'Time',
       'A powerful exploration of the impact of time on life, love, and choices, following a couple over decades as they face challenges and grow.',
       2020, 
       1, 
       null, 
       6, 
       3.99, 
       81, 
       60.00, 
       'PG', 
       CURRENT_DATE, 
       ARRAY['documentary']
WHERE NOT EXISTS (
    SELECT 1 
    FROM film 
    WHERE title = 'Time'
)
RETURNING film_id, title;

---- Update rental rates and durations according to the specified requirements
UPDATE film
SET rental_rate = 4.99, rental_duration = 1
WHERE film_id=1001
RETURNING film_id, rental_rate, rental_duration;

UPDATE film
SET rental_rate = 9.99, rental_duration = 2
WHERE film_id=1002
RETURNING film_id, rental_rate, rental_duration;

UPDATE film
SET rental_rate = 19.99, rental_duration = 3
WHERE film_id=1003
RETURNING film_id, rental_rate, rental_duration;

-----Added actors for movies
-- Using `WHERE NOT EXISTS` to prevent duplicates

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Julia', 'Roberts', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Julia' AND last_name = 'Roberts'
)
RETURNING actor_id;

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Richard', 'Gere', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Richard' AND last_name = 'Gere'
)
RETURNING actor_id;

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Sam', 'Worthington', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Sam' AND last_name = 'Worthington'
)
RETURNING actor_id;

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Zoe', 'Saldana', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Zoe' AND last_name = 'Saldana'
)
RETURNING actor_id;

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Fox', 'Rich', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Fox' AND last_name = 'Rich'
)
RETURNING actor_id;

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Jim', 'Broadbent', CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM actor WHERE first_name = 'Jim' AND last_name = 'Broadbent'
)
RETURNING actor_id;

------Link actors to films in the `film_actor` table

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT actor_id, film_id, CURRENT_DATE
FROM actor, film
WHERE (first_name = 'Julia' AND last_name = 'Roberts') 
  AND title = 'Pretty Woman';

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT actor_id, film_id, CURRENT_DATE
FROM actor, film
WHERE (first_name = 'Richard' AND last_name = 'Gere') 
  AND title = 'Pretty Woman';

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT actor_id, film_id, CURRENT_DATE
FROM actor, film
WHERE (first_name = 'Sam' AND last_name = 'Worthington') 
  AND title = 'Avatar';

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT actor_id, film_id, CURRENT_DATE
FROM actor, film
WHERE (first_name = 'Zoe' AND last_name = 'Saldana') 
  AND title = 'Avatar';

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT actor_id, film_id, CURRENT_DATE
FROM actor, film
WHERE (first_name = 'Fox' AND last_name = 'Rich') 
  AND title = 'Time';

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT actor_id, film_id, CURRENT_DATE
FROM actor, film
WHERE (first_name = 'Jim' AND last_name = 'Broadbent') 
  AND title = 'Time';

-------Added my favorite movies to any a store inventory
------added film_id 1001,1002,1003

INSERT INTO inventory (film_id, store_id, last_update)
SELECT 1001, 1, CURRENT_DATE
FROM film
WHERE title = 'Pretty Woman';

INSERT INTO inventory (film_id, store_id, last_update)
SELECT 1002, 2, CURRENT_DATE
FROM film
WHERE title = 'Avatar';

INSERT INTO inventory (film_id, store_id, last_update)
SELECT 1003, 1, CURRENT_DATE
FROM film
WHERE title = 'Time';

-- Find a customer with at least 43 rental and 43 payment records,
SELECT c.customer_id
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id
HAVING COUNT(DISTINCT r.rental_id) >= 43 AND COUNT(DISTINCT p.payment_id) >= 43
LIMIT 1;

-----updated information about customer_id 1 
UPDATE customer
SET first_name = 'Vitalina',
    last_name = 'Paskarenko',
    email = 'polandmondol@gmail.com',
    address_id = (SELECT address_id FROM address LIMIT 1)
WHERE customer_id = 1;

-----Removed records about customer_id 1 from tables(rental, payment)
DELETE FROM payment
WHERE customer_id = 1;

DELETE FROM rental
WHERE customer_id = 1;


-- I needed to add a record in the rental table because without a rental_id, I can't create a payment for the movie 'Pretty Woman'

INSERT INTO rental ( rental_date,inventory_id, customer_id,return_date, staff_id, last_update)
SELECT '2017-05-15','4582', 1,'2017-05-23', 1, CURRENT_DATE;

-----Make payment for 'Pretty Woman'
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 1, 1, 32298, 4.99, '2017-05-23';

-- added a record for the movie 'Avatar'

INSERT INTO rental ( rental_date,inventory_id, customer_id,return_date, staff_id, last_update)
SELECT '2017-05-05','4584', 1,'2017-05-19', 2, CURRENT_DATE;

---Make payment for movie'Avatar'
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 1, 2, 32304, 9.99, '2017-05-19';

-- added a record for the movie 'Time'

INSERT INTO rental ( rental_date,inventory_id, customer_id,return_date, staff_id, last_update)
SELECT '2017-05-01','4590', 1,'2017-05-30', 1, CURRENT_DATE;

---Make payment for movie 'Time'
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 1, 2, 32306, 19.99, '2017-05-30';