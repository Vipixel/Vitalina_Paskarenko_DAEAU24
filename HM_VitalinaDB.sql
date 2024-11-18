-- Create a physical database with a separate database and schema and give it an appropriate domain-related name. 
CREATE DATABASE climb_db;
CREATE SCHEMA climb_a;
-----creating tables 

CREATE TABLE IF NOT EXISTS climb_a.training (
    training_id SERIAL PRIMARY KEY, 
    training_name VARCHAR(100) NOT NULL, 
    training_date DATE NOT NULL, 
    location VARCHAR(100), 
    duration INTERVAL
);
CREATE TABLE IF NOT EXISTS  climb_a.equipment (
    equipment_id SERIAL PRIMARY KEY,
    e_description TEXT
);
CREATE TABLE IF NOT EXISTS climb_a.climber (
    climber_id SERIAL PRIMARY KEY, 
    name VARCHAR(100), 
    adress TEXT, 
    birth_date DATE,
	medical_notes TEXT,
	equipment_id INT,
	FOREIGN KEY (equipment_id)  REFERENCES climb_a.equipment (equipment_id)
	);
CREATE TABLE IF NOT EXISTS climb_a.climber_traning (
    climber_id INT,
	training_id INT,
	FOREIGN KEY (climber_id)  REFERENCES climb_a.climber (climber_id),
	FOREIGN KEY (training_id)  REFERENCES climb_a.training (training_id)
	);
CREATE TABLE IF NOT EXISTS climb_a.weather(
    weather_id SERIAL PRIMARY KEY, 
    temperature DECIMAL(4,2)NOT NULL, 
    humidity DECIMAL(4,2), 
    wind_speed  DECIMAL(5,2) NOT NULL,
    conditions VARCHAR(100)
	);
CREATE TABLE IF NOT EXISTS climb_a.guide(
    guide_id SERIAL PRIMARY KEY, 
    name VARCHAR(100),
	phone_number VARCHAR(15)
	);

CREATE TABLE IF NOT EXISTS climb_a.area(
    area_id SERIAL PRIMARY KEY, 
    name VARCHAR(100),
	area_info TEXT
	);
CREATE TABLE IF NOT EXISTS climb_a.mountain(
    mountain_id SERIAL PRIMARY KEY, 
    name VARCHAR(100),
	height DECIMAL(6,2) NOT NULL,
	area_id INT,
	FOREIGN KEY (area_id)  REFERENCES climb_a.area (area_id)
	);
CREATE TABLE IF NOT EXISTS climb_a.route(
    route_id SERIAL PRIMARY KEY, 
    name VARCHAR(100) NOT NULL,
	mountain_id INT,
	FOREIGN KEY (mountain_id)  REFERENCES climb_a.mountain (mountain_id)
	);
CREATE TABLE IF NOT EXISTS climb_a.climb(
    climb_id SERIAL PRIMARY KEY,
	route_id INT,
	guide_id INT,
	weather_id INT,
	end_date DATE,
	FOREIGN KEY (route_id)  REFERENCES climb_a.route (route_id),
	FOREIGN KEY (guide_id)  REFERENCES climb_a.guide (guide_id),
	FOREIGN KEY (weather_id)  REFERENCES climb_a.weather (weather_id)
	);
CREATE TABLE IF NOT EXISTS climb_a.climb_climber (
    climber_id INT,
	climb_id INT,
	FOREIGN KEY (climber_id)  REFERENCES climb_a.climber (climber_id),
	FOREIGN KEY (climb_id)  REFERENCES climb_a.climb (climb_id)
	);

---Altering table to add constraints for climb_a.training
ALTER TABLE climb_a.training
    ADD CONSTRAINT training_date CHECK (training_date > '2000-01-01'),
    ALTER COLUMN training_name SET NOT NULL;

---Altering table to add constraints for climb_a.equipment
ALTER TABLE climb_a.equipment
    ALTER COLUMN e_description SET NOT NULL;
	
----Altering table to add constraints for climb_a.climber
ALTER TABLE climb_a.climber
    ADD CONSTRAINT chk_birth_date CHECK (birth_date > '2006-01-01'),
    ADD COLUMN gender CHAR(1) CHECK (gender IN ('M', 'F', 'O')),
    ALTER COLUMN name SET NOT NULL;
---Altering table to add constraints for climb_a.weather
ALTER TABLE climb_a.weather
    ADD CONSTRAINT humidity_range CHECK (humidity >= 0 AND humidity <= 100),
    ADD CONSTRAINT wind_speed_non_negative CHECK (wind_speed >= 0);
-----Altering table to add constraints for climb_a.guide
ALTER TABLE climb_a.guide
    ALTER COLUMN name SET NOT NULL,
    ADD CONSTRAINT uq_phone_number UNIQUE (phone_number);
-----Changing the type of duration because TIME is not what I need for this table
ALTER TABLE climb_a.training
    ALTER COLUMN duration TYPE INTERVAL;

INSERT INTO climb_a.training (training_name, training_date, location, duration)
VALUES 
    ('Climbing Basics', '2024-03-15', 'TatraCamp',INTERVAL '2 hours'),
    ('Advanced Climbing', '2024-04-05', 'Training Base',INTERVAL '3 hours');

INSERT INTO climb_a.equipment (e_description)
VALUES 
    ('Climbing rope set'),
    ('Safety harness');
	
----Changing type of birth date 
ALTER TABLE climb_a.climber
    DROP CONSTRAINT IF EXISTS chk_birth_date,
    ADD CONSTRAINT chk_birth_date CHECK (birth_date <= CURRENT_DATE - INTERVAL '18 years');
-----
INSERT INTO climb_a.climber ( name, adress, birth_date, medical_notes,gender)
VALUES 
    ('Dagmara Rzeszanska', 'Franciszkanska 4', '1990-06-15', 'No issues','F'),
    ('Marek Mroz', 'Pokorna 1533', '1995-10-20', 'Knee injury','M');

select* from climb_a.climber_traning;
INSERT INTO climb_a.climber_traning (climber_id, training_id)
VALUES 
    (1, 102),
    (2, 101);
INSERT INTO climb_a.weather (temperature, humidity, wind_speed, conditions)
VALUES 
    (15.5, 60.0, 5.5, 'Sunny'),
    (10.0, 75.0, 8.0, 'Cloudy');

INSERT INTO climb_a.guide (name, phone_number)
VALUES 
    ('Magda Pierog', '653241989'),
    ('Marek Bradz', '538823759');
	
INSERT INTO climb_a.area (name, area_info)
VALUES 
    ('Morskie Oko', 'Moderate difficulty'),
    ('Sarnia Skala', 'Challenging routes');

INSERT INTO climb_a.mountain ( name, height, area_id)
VALUES 
    ('Rysy', 2499.0, 01),
    ('Giewont', 1894.0, 02);

INSERT INTO climb_a.route ( name)
VALUES 
    ('Tatra '),
    ('Droga pod Reglami');

INSERT INTO climb_a.climb (climb_id,route_id, guide_id, weather_id, end_date)
VALUES 
    (1,1, 1, 1, '2024-03-19'),
    (2,2, 2, 2, '2024-03-26');

------Add a not null 'record_ts' field to each table 
ALTER TABLE climb_a.training
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE climb_a.equipment
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE climb_a.climber
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE climb_a.climber_training
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE climb_a.weather
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE climb_a.guide
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE climb_a.area
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE climb_a.mountain
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE climb_a.route
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE climb_a.climb
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;