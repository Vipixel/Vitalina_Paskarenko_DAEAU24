-- Create a physical database with a separate database and schema and give it an appropriate domain-related name.
CREATE DATABASE db_restate;
CREATE SCHEMA restate;

-- Created tables
CREATE TABLE IF NOT EXISTS restate.property_type (
    type_id SERIAL PRIMARY KEY,
    type_description VARCHAR(100) NOT NULL
);
CREATE TABLE IF NOT EXISTS restate.property_status (
    status_id SERIAL PRIMARY KEY,
    status_description VARCHAR(100) NOT NULL
);
CREATE TABLE IF NOT EXISTS restate.property (
    property_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    city_id INT,
    address VARCHAR(100) NOT NULL,
    type_id INT NOT NULL,
    property_details TEXT NOT NULL,
    status_id INT NOT NULL,
    price DECIMAL(10, 2),
    owner_id INT NOT NULL,
    FOREIGN KEY (type_id) REFERENCES restate.property_type (type_id),
    FOREIGN KEY (status_id) REFERENCES restate.property_status (status_id)
);
CREATE TABLE IF NOT EXISTS restate.city (
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    country VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS restate.client (
    client_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100),
    mail VARCHAR(50) NOT NULL,
    client_details VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS restate.transaction (
    transaction_id SERIAL PRIMARY KEY,
    client_offered DECIMAL(10, 2) NOT NULL,
    client_requested DECIMAL(10, 2) NOT NULL,
    transaction_date DATE,
    transaction_amount DECIMAL(10, 2) NOT NULL
);
CREATE TABLE IF NOT EXISTS restate.agent (
    agent_id SERIAL PRIMARY KEY,
    licence VARCHAR(50) NOT NULL,
    firstname VARCHAR(50) NOT NULL,
    lastname VARCHAR(50),
    phone_number VARCHAR(15) NOT NULL,
    commission_rate DECIMAL(5, 2) NOT NULL CHECK (commission_rate BETWEEN 0 AND 100)
);

CREATE TABLE IF NOT EXISTS restate.contract (
    contract_id SERIAL PRIMARY KEY,
    buyer_id INT NOT NULL,
    client_id INT NOT NULL,
    agent_id INT NOT NULL,
    contract_details TEXT,
    fee_amount DECIMAL(10, 2) NOT NULL CHECK (fee_amount >= 0),
    payment_amount DECIMAL(10, 2) NOT NULL CHECK (payment_amount >= 0),
    date_signed DATE NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    transaction_id INT,
    FOREIGN KEY (buyer_id) REFERENCES restate.client (client_id),
    FOREIGN KEY (client_id) REFERENCES restate.client (client_id),
    FOREIGN KEY (agent_id) REFERENCES restate.agent (agent_id),
    FOREIGN KEY (transaction_id) REFERENCES restate.transaction (transaction_id)
);

CREATE TABLE IF NOT EXISTS restate.financial_record (
    record_id SERIAL PRIMARY KEY,
    transaction_id INT NOT NULL,
    agent_id INT NOT NULL,
    commission_received DECIMAL(10, 2) NOT NULL,
    expenses DECIMAL(10, 2) NOT NULL,
    notes TEXT,
    FOREIGN KEY (transaction_id) REFERENCES restate.transaction (transaction_id),
    FOREIGN KEY (agent_id) REFERENCES restate.agent (agent_id)
);
-----many-to-many 

CREATE TABLE restate.contract_agent (
    contract_id INT NOT NULL,
    agent_id INT NOT NULL,
    PRIMARY KEY (contract_id, agent_id),
    FOREIGN KEY (contract_id) REFERENCES restate.contract (contract_id) ON DELETE CASCADE,
    FOREIGN KEY (agent_id) REFERENCES restate.agent (agent_id) ON DELETE CASCADE
);
------------------------------------------------------------------------
---linked city_id to property
ALTER TABLE restate.property
ADD CONSTRAINT fk_city_id FOREIGN KEY (city_id)
REFERENCES restate.city (city_id); 

--insered date greater than July 1, 2024
ALTER TABLE restate.transaction
ADD CONSTRAINT chk_transaction_date_after_2024
CHECK (transaction_date > '2024-07-01');

--fee_amount is non-negative
ALTER TABLE restate.contract
ADD CONSTRAINT chk_positive_fee_amount
CHECK (fee_amount >= 0);
---unique mail
ALTER TABLE restate.client
ADD CONSTRAINT chk_unique_mail
UNIQUE (mail);
---added that space is non-negative
ALTER TABLE restate.property
ADD CONSTRAINT chk_positive_property_space
CHECK (total_property_space > 0);

---added that price is non-negative
ALTER TABLE restate.property
ADD CONSTRAINT chk_positive_price
CHECK (price >= 0);

ALTER TABLE restate.property
ADD CONSTRAINT unique_property_name UNIQUE (name);

ALTER TABLE restate.city 
ADD CONSTRAINT unique_city_name UNIQUE (city_name);

ALTER TABLE restate.client 
ADD CONSTRAINT unique_client_mail UNIQUE (mail);

ALTER TABLE restate.agent
ADD CONSTRAINT unique_licence_licence UNIQUE (licence);

ALTER TABLE restate.financial_record
ADD CONSTRAINT unique_transaction_id UNIQUE (transaction_id);


-----TASK 4

INSERT INTO restate.city (city_name, state, country)
VALUES 
('Warsaw', 'Mazowieckie', 'Poland'),
('Kraków', 'Małopolskie', 'Poland'),
('Gdańsk', 'Pomorskie', 'Poland'),
('Wrocław', 'Dolnośląskie', 'Poland'),
('Poznań', 'Wielkopolskie', 'Poland'),
('Łódź', 'Łódzkie', 'Poland')
ON CONFLICT(city_name) DO NOTHING
RETURNING city_id, city_name;


INSERT INTO restate.property_type (type_description)
VALUES 
('Apartmet'),
('House'),        
('Townhouse'),
('Penthouse'), 
('Villa');


INSERT INTO restate.property_status (status_description)
VALUES 
('Available'),
('Sold'),
('Rented'),
('Under Construction');


INSERT INTO restate.client (name, contact_person, mail, client_details)
VALUES 
('James Bond', 'Iwona Niemirowska', 'james.bond@pl.com', 'Looking for an apartment in Warsaw.'),
('Maria Gershova', 'Peter Gershov', 'maria.ger@pl.com', 'Interested in penthouses on the outskirts of the city.'),
('Mark Pomer', 'Ewelina Grozna', 'markppp@gmail.com', 'Interested in investing in some properties.'),
('Alex Pizza', 'Michael Ciao', 'alex1976@gmail.com', 'Looking for Townhouse in Poznan.'),
('Marcin Grochowski', 'Joanna Dobra', 'marcinjoanna@pl.com', 'Interested in villas in Kraków.'),
('Katherine Pierog', 'Tom Jerry', 'katherinep@gmail.com', 'Planning to buy an apartment in Gdańsk.')
ON CONFLICT (mail) DO NOTHING;

INSERT INTO restate.agent (licence, firstname, lastname, phone_number, commission_rate)
VALUES 
('PL12345', 'Adam', 'Nowak', '123-456-789', 3.50),
('PL67890', 'Aleksanda', 'Paderewska', '987-654-321', 4.00),
('PL11223', 'Michal', 'Bagel', '456-789-123', 3.75),
('PL44556', 'Ella', 'Babecka', '789-123-456', 4.25),
('PL77889', 'Joanna', 'Wielka', '321-654-987', 5.00),
('PL99000', 'Tomek', 'Karol', '654-987-321', 4.50)
ON CONFLICT (licence) DO NOTHING;

INSERT INTO restate.property (name, city_id, address, type_id, property_details, status_id, price, owner_id)
SELECT * FROM (
    VALUES
--Apartment in Warsaw
    ('City Center Apartment', 
     (SELECT city_id FROM restate.city WHERE city_name = 'Warsaw' LIMIT 1),
     'Marszałkowska 15', 
     (SELECT type_id FROM restate.property_type WHERE type_description = 'Apartment' LIMIT 1),
     'A modern apartment located in the heart of Warsaw.', 
     (SELECT status_id FROM restate.property_status WHERE status_description = 'Available' LIMIT 1), 
     750000.00, 
     1),
---House in Kraków
    ('Suburban House', 
     (SELECT city_id FROM restate.city WHERE city_name = 'Kraków' LIMIT 1),
     'Wawel 3', 
     (SELECT type_id FROM restate.property_type WHERE type_description = 'House' LIMIT 1),
     'A spacious suburban house with a large garden.', 
     (SELECT status_id FROM restate.property_status WHERE status_description = 'Available' LIMIT 1), 
     1200000.00, 
     2),
----Townhouse in Poznań
    ('Luxury Townhouse', 
     (SELECT city_id FROM restate.city WHERE city_name = 'Poznań' LIMIT 1),
     'Old Town 11', 
     (SELECT type_id FROM restate.property_type WHERE type_description = 'Townhouse' LIMIT 1),
     'A luxurious townhouse in a prime location of Poznań.', 
     (SELECT status_id FROM restate.property_status WHERE status_description = 'Available' LIMIT 1), 
     950000.00, 
     3),
-----Penthouse in Gdańsk
    ('Ocean View Penthouse', 
     (SELECT city_id FROM restate.city WHERE city_name = 'Gdańsk' LIMIT 1),
     'Morska 12', 
     (SELECT type_id FROM restate.property_type WHERE type_description = 'Penthouse' LIMIT 1),
     'A stunning penthouse with a breathtaking ocean view.', 
     (SELECT status_id FROM restate.property_status WHERE status_description = 'Available' LIMIT 1), 
     2500000.00, 
     4),
----Villa in Wrocław
    ('Luxury Villa', 
     (SELECT city_id FROM restate.city WHERE city_name = 'Wrocław' LIMIT 1),
     'Krakowska 45', 
     (SELECT type_id FROM restate.property_type WHERE type_description = 'Villa' LIMIT 1),
     'A magnificent villa with modern amenities and a pool.', 
     (SELECT status_id FROM restate.property_status WHERE status_description = 'Available' LIMIT 1), 
     5000000.00, 
     5)
) AS new_data (name, city_id, address, type_id, property_details, status_id, price, owner_id)
WHERE NOT EXISTS (
    SELECT 1
    FROM restate.property p
    WHERE p.name = new_data.name
      AND p.address = new_data.address);

INSERT INTO restate.transaction (client_offered, client_requested, transaction_date, transaction_amount)
VALUES 
(
    (SELECT client_id FROM restate.client WHERE name = 'James Bond'), 
    (SELECT client_id FROM restate.client WHERE name = 'Maria Gershova'), 
    '2024-09-01', 
    800000.00),
(
    (SELECT client_id FROM restate.client WHERE name = 'Mark Pomer'), 
    (SELECT client_id FROM restate.client WHERE name = 'Alex Pizza'), 
    '2024-10-05', 
    400000.00),
(
    (SELECT client_id FROM restate.client WHERE name = 'Maria Gershova'), 
    (SELECT client_id FROM restate.client WHERE name = 'James Bond'), 
    '2024-11-15', 
    2200000.00),
(
    (SELECT client_id FROM restate.client WHERE name = 'Marcin Grochowski'), 
    (SELECT client_id FROM restate.client WHERE name = 'Katherine Pierog'), 
    '2024-12-01', 
    1200000.00);

INSERT INTO restate.financial_record (transaction_id, agent_id, commission_received, expenses, notes)
VALUES 
(
    (SELECT transaction_id FROM restate.transaction 
     WHERE client_offered = (SELECT client_id FROM restate.client WHERE name = 'James Bond') 
       AND client_requested = (SELECT client_id FROM restate.client WHERE name = 'Maria Gershova') 
       AND transaction_amount = 800000.00),
    (SELECT agent_id FROM restate.agent WHERE firstname = 'Adam' AND lastname = 'Nowak'),
    10000.00, 
    500.00, 
    'Commission for selling the apartment.'),
(
    (SELECT transaction_id FROM restate.transaction 
     WHERE client_offered = (SELECT client_id FROM restate.client WHERE name = 'Mark Pomer') 
       AND client_requested = (SELECT client_id FROM restate.client WHERE name = 'Alex Pizza') 
       AND transaction_amount = 400000.00),
    (SELECT agent_id FROM restate.agent WHERE firstname = 'Aleksanda' AND lastname = 'Paderewska'),
    15000.00, 
    700.00, 
    'Commission for selling the office.'),
(
    (SELECT transaction_id FROM restate.transaction 
     WHERE client_offered = (SELECT client_id FROM restate.client WHERE name = 'Maria Gershova') 
       AND client_requested = (SELECT client_id FROM restate.client WHERE name = 'James Bond') 
       AND transaction_amount = 2200000.00),
    (SELECT agent_id FROM restate.agent WHERE firstname = 'Michal' AND lastname = 'Bagel'),
    25000.00, 
    1000.00, 
    'Commission for purchasing the villa.');

SELECT * FROM restate.transaction;
---added new types
INSERT INTO restate.property_type (type_description)
VALUES 
('Studio'),
('Farmhouse');

INSERT INTO restate.property_status (status_description)
VALUES 
('Pending'),
('In Renovation');

-----added 2 property to have 6 row in table
INSERT INTO restate.property (name, city_id, address, type_id, property_details, status_id, price, owner_id)
SELECT * FROM (
    VALUES
    ('Modern Studio', 
     (SELECT city_id FROM restate.city WHERE city_name = 'Łódź' LIMIT 1),
     'Piotrkowska 50', 
     (SELECT type_id FROM restate.property_type WHERE type_description = 'Studio' LIMIT 1),
     'A compact, modern studio apartment in the heart of Łódź.', 
     (SELECT status_id FROM restate.property_status WHERE status_description = 'Available' LIMIT 1), 
     350000.00, 
     6)
) AS new_data (name, city_id, address, type_id, property_details, status_id, price, owner_id)
WHERE NOT EXISTS (
    SELECT 1
    FROM restate.property p
    WHERE p.name = new_data.name
      AND p.address = new_data.address);
-----added 2 transaction to have 6 row in table
INSERT INTO restate.transaction (client_offered, client_requested, transaction_date, transaction_amount)
VALUES 
(
    (SELECT client_id FROM restate.client WHERE name = 'Katherine Pierog'), 
    (SELECT client_id FROM restate.client WHERE name = 'James Bond'), 
    '2024-12-15', 
    3000000.00
),
(
    (SELECT client_id FROM restate.client WHERE name = 'Alex Pizza'), 
    (SELECT client_id FROM restate.client WHERE name = 'Maria Gershova'), 
    '2024-11-10', 
    1200000.00);

-----added 3 records to have 6 row in table
INSERT INTO restate.financial_record (transaction_id, agent_id, commission_received, expenses, notes)
VALUES 
(
    (SELECT transaction_id FROM restate.transaction 
     WHERE client_offered = (SELECT client_id FROM restate.client WHERE name = 'Katherine Pierog') 
       AND client_requested = (SELECT client_id FROM restate.client WHERE name = 'James Bond') 
       AND transaction_amount = 3000000.00),
    (SELECT agent_id FROM restate.agent WHERE firstname = 'Tomek' AND lastname = 'Karol'),
    45000.00, 
    1500.00, 
    'Commission for a luxury penthouse sale.'),
(
    (SELECT transaction_id FROM restate.transaction 
     WHERE client_offered = (SELECT client_id FROM restate.client WHERE name = 'Alex Pizza') 
       AND client_requested = (SELECT client_id FROM restate.client WHERE name = 'Maria Gershova') 
       AND transaction_amount = 1200000.00),
    (SELECT agent_id FROM restate.agent WHERE firstname = 'Joanna' AND lastname = 'Wielka'),
    20000.00, 
    800.00, 
    'Commission for a townhouse sale.'),
(
    (SELECT transaction_id FROM restate.transaction 
     WHERE client_offered = (SELECT client_id FROM restate.client WHERE name = 'James Bond') 
       AND client_requested = (SELECT client_id FROM restate.client WHERE name = 'Maria Gershova') 
       AND transaction_amount = 800000.00),
    (SELECT agent_id FROM restate.agent WHERE firstname = 'Adam' AND lastname = 'Nowak'),
    12000.00, 
    600.00, 
    'Commission for an apartment sale.');

ALTER TABLE restate.financial_record
DROP CONSTRAINT unique_transaction_id;

-----added DEFAULT 

ALTER TABLE restate.agent
ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE restate.property
ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Create a function that updates data in one of your tables. 
-- This function should take the following input arguments:
-- The primary key value of the row you want to update
-- The name of the column you want to update
-- The new value you want to set for the specified column

-----TASK 5.1

CREATE OR REPLACE FUNCTION fc_update_agent_name(
	agent_id INT,
    column_name TEXT,
	new_value TEXT)
RETURNS VOID
AS 
$$
BEGIN
    EXECUTE format  ('UPDATE restate.agent SET %I = $1 WHERE agent_id = $2',
    column_name)
    USING new_value, agent_id;
	RETURN "Update Successful";
END;
$$ LANGUAGE plpgsql;

-----TASK 5.2

CREATE OR REPLACE FUNCTION fc_add_new_transct(
    client_offered_id DECIMAL(10, 2),      
    client_requested_id DECIMAL(10, 2),    
    transaction_date DATE,       
    transaction_amount DECIMAL(10, 2) , 
	client_ofered_id INT, 
	client_requestetd_id INT)
RETURNS TEXT 
AS
$$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM restate.client WHERE client_id = client_offered_id) THEN
        RETURN 'Client offered ID not found';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM restate.client WHERE client_id = client_requested_id) THEN
        RETURN 'Client requested ID not found';
    END IF;
    INSERT INTO restate.transaction (
        client_offered, client_requested, transaction_date, transaction_amount)
    VALUES (
        client_offered_amount,
        client_requested_amount,
        transaction_date,
        transaction_amount);
    RETURN 'Transaction successfully added.';
END;
$$ LANGUAGE plpgsql;

-----TASK 6

CREATE OR REPLACE VIEW analytics_recent_quarter AS
SELECT
    TO_CHAR(t.transaction_date, 'YYYY-Q') AS quarter,                
    c.name AS client_offered_name,                                  
    c2.name AS client_requested_name,                                
    a.firstname || ' ' || a.lastname AS agent_name,                  
    t.transaction_amount,                                        
    fr.commission_received,                                       
    fr.expenses,                                                
    fr.commission_received - fr.expenses AS net_profit              
FROM restate.transaction t
JOIN restate.client c ON t.client_offered = c.client_id               
JOIN restate.client c2 ON t.client_requested = c2.client_id          
JOIN restate.financial_record fr ON t.transaction_id = fr.transaction_id 
JOIN restate.agent a ON fr.agent_id = a.agent_id      
WHERE
    EXTRACT(QUARTER FROM t.transaction_date) = EXTRACT(QUARTER FROM CURRENT_DATE)
    AND EXTRACT(YEAR FROM t.transaction_date) = EXTRACT(YEAR FROM CURRENT_DATE); 

-----TASK 7 manager role

CREATE USER manager1 WITH PASSWORD 'company2024';

DO 
$$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_catalog.pg_roles
        WHERE rolname = 'manager'
    ) THEN
        CREATE ROLE manager;
    END IF;
END 
$$;

GRANT manager TO manager1;

GRANT SELECT ON ALL TABLES IN SCHEMA restate TO manager; 

ALTER DEFAULT PRIVILEGES IN SCHEMA restate GRANT SELECT ON TABLES TO manager;
