CREATE DATABASE Airline_Analytics;
GO

USE Airline_Analytics;
GO


-----------------------------------------------------CREATING TABLES---------------------------------------------------------

CREATE TABLE Airlines
(
    IATA_CODE VARCHAR(10) PRIMARY KEY,
    AIRLINE VARCHAR(150)
);


CREATE TABLE Airports
(
    IATA_CODE VARCHAR(10) PRIMARY KEY,
    AIRPORT VARCHAR(255),
    CITY VARCHAR(100),
    STATE VARCHAR(50),
    COUNTRY VARCHAR(50),
    LATITUDE DECIMAL(10,6),
    LONGITUDE DECIMAL(10,6)
);

CREATE TABLE Flights
(
    YEAR INT,
    MONTH INT,
    DAY INT,
    DAY_OF_WEEK INT,
    AIRLINE VARCHAR(10),
    FLIGHT_NUMBER VARCHAR(20),
    TAIL_NUMBER VARCHAR(20),
    ORIGIN_AIRPORT VARCHAR(10),
    DESTINATION_AIRPORT VARCHAR(10),
    SCHEDULED_DEPARTURE VARCHAR(10),
    DEPARTURE_TIME VARCHAR(10),
    DEPARTURE_DELAY FLOAT,
    TAXI_OUT FLOAT,
    WHEELS_OFF VARCHAR(10),
    SCHEDULED_TIME FLOAT,
    ELAPSED_TIME FLOAT,
    AIR_TIME FLOAT,
    DISTANCE FLOAT,
    WHEELS_ON VARCHAR(10),
    TAXI_IN FLOAT,
    SCHEDULED_ARRIVAL VARCHAR(10),
    ARRIVAL_TIME VARCHAR(10),
    ARRIVAL_DELAY FLOAT,
    DIVERTED BIT,
    CANCELLED BIT,
    CANCELLATION_REASON VARCHAR(5),
    AIR_SYSTEM_DELAY FLOAT,
    SECURITY_DELAY FLOAT,
    AIRLINE_DELAY FLOAT,
    LATE_AIRCRAFT_DELAY FLOAT,
    WEATHER_DELAY FLOAT
);

------------------------------------------------------------------------------------------------------------------------------------


SELECT
    COUNT(*) AS Total_Flights,
    COUNT(DISTINCT AIRLINE) AS Airlines,
    COUNT(DISTINCT ORIGIN_AIRPORT) AS Origin_Airports,
    COUNT(DISTINCT DESTINATION_AIRPORT) AS Destination_Airports
FROM Flights_Data;


SELECT TOP 5 *
FROM Airlines_Data;

SELECT TOP 5 *
FROM Airports_Data;

SELECT TOP 5 *
FROM Flights_Data;

----------------------------------------------------------------------------------------------------------------------------------------------------------


-- DATA QUALITY CHECK 

SELECT
    COUNT(*) AS TotalRows,
    COUNT(DEPARTURE_DELAY) AS DepartureDelay_NotNull,
    COUNT(ARRIVAL_DELAY) AS ArrivalDelay_NotNull,
    COUNT(CANCELLATION_REASON) AS CancellationReason_NotNull,
    COUNT(AIRLINE_DELAY) AS AirlineDelay_NotNull,
    COUNT(WEATHER_DELAY) AS WeatherDelay_NotNull,
    COUNT(SECURITY_DELAY) AS SecurityDelay_NotNull,
    COUNT(AIR_SYSTEM_DELAY) AS AirSystemDelay_NotNull,
    COUNT(LATE_AIRCRAFT_DELAY) AS LateAircraftDelay_NotNull
FROM flights_data;


---cancellation reason and the number of flights cancelled for that reason

select * from flights_data

SELECT
    CANCELLATION_REASON,
    COUNT(*) AS Flights
FROM flights_data
WHERE CANCELLATION_REASON IS NOT NULL
GROUP BY CANCELLATION_REASON;


---------------------------------------------------------creating proper date 

ALTER TABLE flights_data
ADD FLIGHT_DATE DATE;

UPDATE flights_data
SET FLIGHT_DATE =
DATEFROMPARTS(YEAR, MONTH, DAY);



---------------------------------------------------------creating cancellation 
ALTER TABLE flights_data
ADD CANCELLATION_REASON_DESC VARCHAR(50);

UPDATE flights_data
SET CANCELLATION_REASON_DESC =
CASE
    WHEN CANCELLATION_REASON = 'A' THEN 'Airline/Carrier'
    WHEN CANCELLATION_REASON = 'B' THEN 'Weather'
    WHEN CANCELLATION_REASON = 'C' THEN 'National Air System'
    WHEN CANCELLATION_REASON = 'D' THEN 'Security'
    ELSE NULL
END;

SELECT DISTINCT
CANCELLATION_REASON,
CANCELLATION_REASON_DESC
FROM flights_data;


SELECT
    CANCELLATION_REASON,
    COUNT(*) AS Cancelled_Flights,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER(),2
    ) AS Cancellation_pct
FROM flights_data
WHERE CANCELLATION_REASON IS NOT NULL
GROUP BY CANCELLATION_REASON;



---------------------------------------------------------------checking time format 
SELECT TOP 20
SCHEDULED_DEPARTURE,
DEPARTURE_TIME,
SCHEDULED_ARRIVAL,
ARRIVAL_TIME
FROM flights_data;

----------------------------------------------------------------DELAY ANALYSIS ( -ve shows early departures and arrival)
SELECT
    MIN(DEPARTURE_DELAY) AS Min_Departure_Delay,
    MAX(DEPARTURE_DELAY) AS Max_Departure_Delay,

    MIN(ARRIVAL_DELAY) AS Min_Arrival_Delay,
    MAX(ARRIVAL_DELAY) AS Max_Arrival_Delay
FROM flights_data;


----------------------------------SUMMARISING NULL'S

SELECT
    SUM(CASE WHEN DEPARTURE_DELAY IS NULL THEN 1 ELSE 0 END) AS Null_Departure_Delay,
    SUM(CASE WHEN ARRIVAL_DELAY IS NULL THEN 1 ELSE 0 END) AS Null_Arrival_Delay,
    SUM(CASE WHEN AIRLINE_DELAY IS NULL THEN 1 ELSE 0 END) AS Null_Airline_Delay,
    SUM(CASE WHEN WEATHER_DELAY IS NULL THEN 1 ELSE 0 END) AS Null_Weather_Delay
FROM flights_data;

SELECT
    COUNT(*) AS TotalRows,
    COUNT(DEPARTURE_DELAY) AS DepartureDelay_NotNull,
    COUNT(ARRIVAL_DELAY) AS ArrivalDelay_NotNull
FROM flights_data;
-----------------------------------------------------------------------------------------------------------------------------------------------

                                                     -- ARRIVAL/DEPARTURE IN (HOURS)

ALTER TABLE flights_data
ADD DEPARTURE_HOUR TINYINT;
`
UPDATE flights_data
SET DEPARTURE_HOUR =
CAST(LEFT(SCHEDULED_DEPARTURE,2) AS TINYINT);

ALTER TABLE flights_data
ADD ARRIVAL_HOUR TINYINT;

UPDATE flights_data
SET ARRIVAL_HOUR =
CAST(LEFT(SCHEDULED_ARRIVAL,2) AS TINYINT);

SELECT distinct 
SCHEDULED_DEPARTURE, DEPARTURE_HOUR, SCHEDULED_ARRIVAL, ARRIVAL_HOUR
FROM flights_data;

------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------CREATING TIME BUCKETS FOR ANALYSIS 

ALTER TABLE flights_data
ADD TIME_OF_DAY VARCHAR(20);

UPDATE flights_data
SET TIME_OF_DAY =
CASE
    WHEN DEPARTURE_HOUR BETWEEN 0 AND 5 THEN 'Night'
    WHEN DEPARTURE_HOUR BETWEEN 6 AND 11 THEN 'Morning'
    WHEN DEPARTURE_HOUR BETWEEN 12 AND 17 THEN 'Afternoon'
    ELSE 'Evening'
END;
------------------------------------------------------------------------------------------------------------------------------------------------------------------

