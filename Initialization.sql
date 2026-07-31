CREATE DATABASE Airport_Operations_DB;

USE Airport_Operations_DB;

CREATE TABLE stg_airports (
    Airport_ID INT,
    Airport_Name VARCHAR(255),
    City VARCHAR(100),
    Country VARCHAR(100),
    IATA CHAR(3),
    ICAO CHAR(4),
    Latitude DECIMAL(10,6),
    Longitude DECIMAL(10,6),
    Altitude INT,
    Timezone DECIMAL(4,2),
    DST CHAR(1),
    Timezone_DB VARCHAR(100),
    Airport_Type VARCHAR(50),
    Source VARCHAR(50)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/airports.csv'
INTO TABLE stg_airports
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(
Airport_ID,
Airport_Name,
City,
Country,
IATA,
ICAO,
Latitude,
Longitude,
Altitude,
Timezone,
DST,
Timezone_DB,
Airport_Type,
Source
);

SELECT COUNT(*)
FROM stg_airports;

SELECT *
FROM stg_airports
LIMIT 10;

CREATE TABLE stg_airlines (
    Airline_ID INT,
    Airline_Name VARCHAR(255),
    Alias VARCHAR(255),
    IATA CHAR(3),
    ICAO CHAR(4),
    Callsign VARCHAR(100),
    Country VARCHAR(100),
    Active CHAR(1)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/airlines.csv'
INTO TABLE stg_airlines
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(
Airline_ID,
Airline_Name,
Alias,
IATA,
ICAO,
Callsign,
Country,
Active
);

SELECT COUNT(*)
FROM stg_airlines;

CREATE TABLE stg_aircraft (
    Aircraft_Name VARCHAR(255),
    IATA_Code CHAR(3),
    ICAO_Code CHAR(4)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/planes.csv'
INTO TABLE stg_aircraft
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(
Aircraft_Name,
IATA_Code,
ICAO_Code
);

SELECT COUNT(*) FROM stg_aircraft;

CREATE TABLE stg_routes (
    Airline VARCHAR(10),
    Airline_ID INT,
    Source_Airport VARCHAR(10),
    Source_Airport_ID INT,
    Destination_Airport VARCHAR(10),
    Destination_Airport_ID INT,
    Codeshare VARCHAR(5),
    Stops INT,
    Equipment VARCHAR(50)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/routes.csv'
INTO TABLE stg_routes
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(
Airline,
Airline_ID,
Source_Airport,
Source_Airport_ID,
Destination_Airport,
Destination_Airport_ID,
Codeshare,
Stops,
Equipment
);

SELECT COUNT(*) FROM stg_routes;

SELECT Airport_ID, COUNT(*) AS cnt
FROM stg_airports
GROUP BY Airport_ID
HAVING COUNT(*) > 1;


SELECT COUNT(*)
FROM stg_airports
WHERE Airport_ID IS NULL;


SELECT IATA, COUNT(*)
FROM stg_airports
WHERE IATA <> '\N'
GROUP BY IATA
HAVING COUNT(*) > 1;


SELECT COUNT(*)
FROM stg_airports
WHERE IATA = '\N'
   OR IATA = '';


SELECT *
FROM stg_airports
WHERE Latitude NOT BETWEEN -90 AND 90
   OR Longitude NOT BETWEEN -180 AND 180;
   
SELECT
    COUNT(*) AS null_iata
FROM stg_airports
WHERE IATA IS NULL;

CREATE TABLE dim_airport (
    airport_key INT AUTO_INCREMENT PRIMARY KEY,
    airport_id INT NOT NULL UNIQUE,
    airport_name VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    country VARCHAR(100),
    iata CHAR(3),
    icao CHAR(4),
    latitude DECIMAL(11,8),
    longitude DECIMAL(11,8),
    timezone_db VARCHAR(100),
    airport_type VARCHAR(50)
);

INSERT INTO dim_airport (
    airport_id,
    airport_name,
    city,
    country,
    iata,
    icao,
    latitude,
    longitude,
    timezone_db,
    airport_type
)
SELECT
    Airport_ID,
    Airport_Name,
    City,
    Country,
    NULLIF(IATA, '\N'),
    NULLIF(ICAO, '\N'),
    Latitude,
    Longitude,
    Timezone_DB,
    Airport_Type
FROM stg_airports;

SELECT COUNT(*)
FROM dim_airport;

SELECT *
FROM dim_airport
LIMIT 10;

CREATE TABLE dim_airline (
    airline_key INT AUTO_INCREMENT PRIMARY KEY,
    airline_id INT NOT NULL UNIQUE,
    airline_name VARCHAR(255) NOT NULL,
    alias VARCHAR(255),
    iata CHAR(3),
    icao CHAR(4),
    callsign VARCHAR(100),
    country VARCHAR(100),
    active CHAR(1)
);

INSERT INTO dim_airline (
    airline_id,
    airline_name,
    alias,
    iata,
    icao,
    callsign,
    country,
    active
)
SELECT
    Airline_ID,
    Airline_Name,
    NULLIF(Alias,'\\N'),
    NULLIF(IATA,'\\N'),
    NULLIF(ICAO,'\\N'),
    NULLIF(Callsign,'\\N'),
    Country,
    Active
FROM stg_airlines;

SELECT COUNT(*)
FROM dim_airline;

SELECT *
FROM dim_airline
LIMIT 10;


CREATE TABLE dim_aircraft (
    aircraft_key INT AUTO_INCREMENT PRIMARY KEY,
    aircraft_name VARCHAR(255) NOT NULL,
    iata_code CHAR(3),
    icao_code CHAR(4)
);

INSERT INTO dim_aircraft (
    aircraft_name,
    iata_code,
    icao_code
)
SELECT
    Aircraft_Name,
    NULLIF(IATA_Code,'\\N'),
    NULLIF(ICAO_Code,'\\N')
FROM stg_aircraft;

SELECT COUNT(*)
FROM dim_aircraft;

SELECT *
FROM dim_aircraft
LIMIT 10;

CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    flight_date DATE NOT NULL UNIQUE,
    year SMALLINT,
    quarter TINYINT,
    month TINYINT,
    month_name VARCHAR(20),
    day_of_month TINYINT,
    day_name VARCHAR(20),
    day_of_week TINYINT,
    is_weekend BOOLEAN
);

SELECT VERSION();

INSERT INTO dim_date (
    date_key,
    flight_date,
    year,
    quarter,
    month,
    month_name,
    day_of_month,
    day_name,
    day_of_week,
    is_weekend
)
WITH RECURSIVE dates AS (
    SELECT DATE('2024-01-01') AS dt
    UNION ALL
    SELECT DATE_ADD(dt, INTERVAL 1 DAY)
    FROM dates
    WHERE dt < '2024-01-31'
)
SELECT
    DATE_FORMAT(dt, '%Y%m%d') + 0,
    dt,
    YEAR(dt),
    QUARTER(dt),
    MONTH(dt),
    MONTHNAME(dt),
    DAY(dt),
    DAYNAME(dt),
    DAYOFWEEK(dt),
    CASE
        WHEN DAYOFWEEK(dt) IN (1,7) THEN TRUE
        ELSE FALSE
    END
FROM dates;

SELECT *
FROM dim_date
LIMIT 10;


CREATE TABLE fact_flights (
    flight_key INT AUTO_INCREMENT PRIMARY KEY,

    date_key INT NOT NULL,

    reporting_airline VARCHAR(10),
    airline_iata CHAR(3),
    flight_number INT,
    tail_number VARCHAR(20),

    origin_airport_id INT,
    origin CHAR(3),

    dest_airport_id INT,
    dest CHAR(3),

    crs_dep_time INT,
    dep_time INT,

    crs_arr_time INT,
    arr_time INT,

    dep_delay DECIMAL(6,2),
    dep_delay_minutes DECIMAL(6,2),
    dep_del15 TINYINT,

    arr_delay DECIMAL(6,2),
    arr_delay_minutes DECIMAL(6,2),
    arr_del15 TINYINT,

    taxi_out DECIMAL(6,2),
    taxi_in DECIMAL(6,2),

    wheels_off INT,
    wheels_on INT,

    crs_elapsed_time DECIMAL(6,2),
    actual_elapsed_time DECIMAL(6,2),
    air_time DECIMAL(6,2),

    distance DECIMAL(8,2),

    carrier_delay DECIMAL(6,2),
    weather_delay DECIMAL(6,2),
    nas_delay DECIMAL(6,2),
    security_delay DECIMAL(6,2),
    late_aircraft_delay DECIMAL(6,2),

    cancelled TINYINT,
    cancellation_code CHAR(1),
    diverted TINYINT,

    CONSTRAINT fk_fact_date
        FOREIGN KEY (date_key)
        REFERENCES dim_date(date_key)
);

DESCRIBE fact_flights;

SHOW PROCESSLIST;

SELECT COUNT(*)
FROM fact_flights;

DESCRIBE dim_airline;
DESCRIBE dim_aircraft;
DESCRIBE dim_airport;
DESCRIBE fact_flights;

ALTER TABLE fact_flights
ADD COLUMN airline_key INT,
ADD COLUMN origin_airport_key INT,
ADD COLUMN destination_airport_key INT;

SELECT *
FROM dim_airport
WHERE airport_id = 12953;

SELECT airport_id
FROM dim_airport
LIMIT 10;

SELECT iata, airport_name
FROM dim_airport
WHERE iata IN ('ATL', 'LAX', 'ORD', 'JFK', 'DFW');

SELECT *
FROM dim_airport
WHERE iata = 'XWA';

INSERT INTO dim_airport
(
    airport_id,
    airport_name,
    city,
    country,
    iata,
    icao,
    latitude,
    longitude,
    timezone_db,
    airport_type
)
VALUES
(
    999999,
    'Williston Basin International Airport',
    'Williston',
    'United States',
    'XWA',
    'KXWA',
    48.2584,
    -103.7510,
    'America/Chicago',
    'Airport'
);

SELECT COUNT(*)
FROM dim_airport
WHERE iata IS NULL
   OR TRIM(iata) = '';
   
SELECT COUNT(*)
FROM fact_flights;

SELECT SUM(distance)
FROM fact_flights;

SELECT SUM(air_time)
FROM fact_flights;

SELECT AVG(air_time)
FROM fact_flights;

SELECT AVG(distance)
FROM fact_flights;