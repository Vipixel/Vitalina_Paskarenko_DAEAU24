-- -- Task 1.
-- Checked if SSL encryption is enforced for connections
-- -- SHOW ssl;
-- -- SSL is not enabled, meaning connections are not encrypted, which could lead to security risks.
-- checked specific role with privilege
-- SELECT grantee, privilege_type, table_schema, table_name
-- FROM information_schema.role_table_grants;
-- -- Password 
-- -- I use password to enter in database.

-- Task 2.

CREATE ROLE rentaluser WITH LOGIN PASSWORD 'rentalpassword';
GRANT SELECT ON TABLE customer TO rentaluser;

CREATE ROLE rental;

GRANT rental TO rentaluser;

GRANT INSERT, UPDATE ON TABLE rental TO rental;

INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id) 
VALUES ('2024-05-24', 5, 2, '2024-07-05', 1)
RETURNING rental_id;

UPDATE rental 
SET return_date = '2024-12-10' 
WHERE rental_id = 32324;

REVOKE INSERT ON TABLE rental FROM rental;

-- Create a personalized role for any customer already existing in the dvd_rental database. The name of the role name must be client_{first_name}_{last_name} (omit curly brackets).
-- The customer's payment and rental history must not be empty. 

SELECT DISTINCT c.customer_id, c.first_name, c.last_name
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
JOIN rental r ON c.customer_id = r.customer_id
WHERE p.payment_id IS NOT NULL AND r.rental_id IS NOT NULL;


DO $$
DECLARE
    cust RECORD;
    role_name TEXT;
BEGIN
    FOR cust IN (
        SELECT DISTINCT first_name, last_name
        FROM customer
        JOIN payment USING (customer_id)
        JOIN rental USING (customer_id)
    )
    LOOP
        role_name := 'client_' || LOWER(cust.first_name) || '_' || LOWER(cust.last_name);
        EXECUTE 'CREATE ROLE ' || role_name || ' WITH LOGIN PASSWORD ''default_password''';
        EXECUTE 'GRANT SELECT ON payment, rental, customer TO ' || role_name;
    END LOOP;
END $$;

SELECT table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'client_john_doe';

ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

CREATE POLICY rental_customer_policy
ON rental
USING (customer_id = current_setting('app.customer_id')::INTEGER);

CREATE POLICY payment_customer_policy
ON payment
USING (customer_id = current_setting('app.customer_id')::INTEGER);


-- How can one restrict access to certain columns of a database table?
-- Using this:
-- GRANT SELECT (column_name) ON table_name TO role_name;

-- What is the difference between user identification and user authentication?
-- User Identification - Identifies who the user is (login, username,user_id)
-- User Authentication - Verifies the user identity by checking credentials (password, phone number, code what we recive if we log in from diferent devise) 

-- What are the recommended authentication protocols for PostgreSQL?
-- SSL- must be on
-- Strong password 
-- Certificate Authentication

-- What is proxy authentication in PostgreSQL and what is it for? 
-- Why does it make role-based access control easier to implement?
-- Proxy Authentication - Lets one role act as another using  without needing separate logins.
-- SET ROLE user_role_name;


