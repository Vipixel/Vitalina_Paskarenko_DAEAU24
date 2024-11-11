-----creating tables 
CREATE TABLE training (
    training_id INT PRIMARY KEY, 
    training_name VARCHAR(100)NOT NULL, 
    training_date DATE NOT NULL, 
    location  VARCHAR(100),
    duration TIME
	);
CREATE TABLE equipment (
    equipment_id INT PRIMARY KEY,
    climber_id INT,
    e_description TEXT
);
-- - after I will add alter table for FOREIGN KEY (climber_id)  REFERENCES climber (climber_id)
CREATE TABLE climber (
    climber_id INT PRIMARY KEY, 
    name VARCHAR(100), 
    adress TEXT, 
    birth_date DATE,
	medical_notes TEXT,
	equipment_id INT,
	FOREIGN KEY (equipment_id)  REFERENCES equipment (equipment_id)
	);
CREATE TABLE climber_traning (
    climber_id INT,
	training_id INT,
	FOREIGN KEY (climber_id)  REFERENCES climber (climber_id),
	FOREIGN KEY (training_id)  REFERENCES training (training_id)
	);
-- CREATE TABLE medical_info (	
--     notes TEXT
-- 	); I decided not create table but put the 'note' into climber

CREATE TABLE weather(
    weather_id INT PRIMARY KEY, 
    temperature DECIMAL(4,2)NOT NULL, 
    humidity DECIMAL(4,2), 
    wind_speed  DECIMAL(5,2) NOT NULL,
    conditions VARCHAR(100)
	);
CREATE TABLE guide(
    guide_id INT PRIMARY KEY, 
    name VARCHAR(100),
	phone_number VARCHAR(15)
	);
CREATE TABLE route(
    route_id INT PRIMARY KEY, 
    name VARCHAR(100) NOT NULL,
	mountain_id INT,
	FOREIGN KEY (mountain_id)  REFERENCES mountain (mountain_id)
	);
CREATE TABLE area(
    area_id INT PRIMARY KEY, 
    name VARCHAR(100),
	area_info TEXT
	);
CREATE TABLE mountain(
    mountain_id INT PRIMARY KEY, 
    name VARCHAR(100),
	height DECIMAL(6,2) NOT NULL,
	area_id INT,
	FOREIGN KEY (area_id)  REFERENCES area (area_id)
	);
CREATE TABLE climb(
    climb_id INT PRIMARY KEY,
	route_id INT,
	guide_id INT,
	weather_id INT,
	end_date DATE,
	FOREIGN KEY (route_id)  REFERENCES route (route_id),
	FOREIGN KEY (guide_id)  REFERENCES guide (guide_id),
	FOREIGN KEY (weather_id)  REFERENCES weather (weather_id)
	);
CREATE TABLE climb_climber (
    climber_id INT,
	climb_id INT,
	FOREIGN KEY (climber_id)  REFERENCES climber (climber_id),
	FOREIGN KEY (climb_id)  REFERENCES climb (climb_id)
	);
ALTER TABLE equipment
   ADD CONSTRAINT fk_equipment_climber
   FOREIGN KEY (climber_id) REFERENCES climber (climber_id);