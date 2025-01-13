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

CREATE USER rentaluser_1 WITH PASSWORD 'rentalpassword';

GRANT CONNECT ON DATABASE dvdrental TO rentaluser_1;

GRANT SELECT ON TABLE customer TO rental;

DO 
$$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_catalog.pg_roles
        WHERE rolname = 'rental_r'
    ) THEN
        CREATE ROLE rental_r;
    END IF;
END 
$$;

GRANT INSERT, UPDATE ON TABLE rental TO rental;

GRANT rental_r TO rentaluser_1;

INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id) 
VALUES ('2024-05-24', 5, 2, '2024-07-05', 1)
RETURNING rental_id;

UPDATE rental 
SET return_date = '2024-12-10' 
WHERE rental_id = 32324;

REVOKE INSERT ON TABLE rental FROM rental;

SELECT DISTINCT c.customer_id, c.first_name, c.last_name
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
JOIN rental r ON c.customer_id = r.customer_id
WHERE p.payment_id IS NOT NULL AND r.rental_id IS NOT NULL;
-- Create a personalized role for any customer already existing in the dvd_rental database. 

CREATE OR REPLACE FUNCTION create_customer_role(first_name TEXT, last_name TEXT)
RETURNS void 
AS 
$$
DECLARE
    rental_r TEXT;
BEGIN
    rental_r := 'client_' || LOWER(first_name) || '_' || LOWER(last_name);
    IF NOT EXISTS (
        SELECT FROM pg_catalog.pg_roles WHERE rolname = rental_r
    ) THEN
        EXECUTE FORMAT('CREATE USER %I WITH PASSWORD %L', rental_r, 'default_password');
        EXECUTE FORMAT('GRANT SELECT ON payment, rental, customer TO %I', rental_r);
    END IF;
END;
$$ 
LANGUAGE plpgsql;

SELECT create_customer_role(LOWER('SARAH'), LOWER('LEWIS'));

SELECT rolname
FROM pg_catalog.pg_roles
WHERE rolname = 'client_sarah_lewis';

SELECT table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'client_sarah_lewis';

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


