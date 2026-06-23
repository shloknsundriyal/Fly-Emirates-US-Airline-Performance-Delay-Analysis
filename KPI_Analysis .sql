
USE Airline_Analytics;
GO

-- CREATING A UNIVERSAL SINGLE VIEW FOR OUR ANALYSIS USING JOINS 

CREATE VIEW Airline_analysis AS
SELECT

    f.FLIGHT_DATE,
    f.YEAR,
    f.MONTH,
    f.DAY,
    f.DAY_OF_WEEK,
    f.AIRLINE,
    a.AIRLINE AS AIRLINE_NAME,
    f.FLIGHT_NUMBER,
    f.ORIGIN_AIRPORT,
    o.AIRPORT AS ORIGIN_AIRPORT_NAME,
    o.CITY AS ORIGIN_CITY,
    o.STATE AS ORIGIN_STATE,
    f.DESTINATION_AIRPORT,
    d.AIRPORT AS DESTINATION_AIRPORT_NAME,
    d.CITY AS DESTINATION_CITY,
    d.STATE AS DESTINATION_STATE,
    f.DISTANCE,
    f.DEPARTURE_HOUR,
    f.ARRIVAL_HOUR,
    f.TIME_OF_DAY,
    f.DEPARTURE_DELAY,
    f.ARRIVAL_DELAY,
    f.CANCELLED,
    f.CANCELLATION_REASON_DESC,
    f.DIVERTED,
    f.AIR_SYSTEM_DELAY,
    f.SECURITY_DELAY,
    f.AIRLINE_DELAY,
    f.LATE_AIRCRAFT_DELAY,
    f.WEATHER_DELAY

FROM flights_data f
LEFT JOIN airlines_data a ON f.AIRLINE = a.IATA_CODE
LEFT JOIN airports_data o ON f.ORIGIN_AIRPORT = o.IATA_CODE
LEFT JOIN airports_data d ON f.DESTINATION_AIRPORT = d.IATA_CODE;


SELECT TOP 10 *
FROM Airline_analysis;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 1) FLIGHT VOLUME KPI
SELECT
    COUNT(*) AS Total_Flights
FROM Airline_analysis;


-- 2) TOTAL CANCELLATIONS
SELECT
    COUNT(*) AS Cancelled_Flights
FROM Airline_analysis
WHERE CANCELLED = 1;


-- 3) CANCELLATIONS BY REASON
SELECT
    CANCELLATION_REASON_DESC,
    COUNT(*) AS Cancelled_Flights,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER(),2
    ) AS Pct
FROM Airline_analysis
WHERE CANCELLED = 1
GROUP BY CANCELLATION_REASON_DESC
ORDER BY Cancelled_Flights DESC;



-- 4) CANCELLATION RATE
SELECT
    ROUND(
        SUM(CASE WHEN CANCELLED = 1 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    ) AS Cancellation_Rate_Percent
FROM Airline_analysis;



-- 5) DIVERTED FLIGHTS
SELECT
    COUNT(*) AS Diverted_Flights
FROM Airline_analysis
WHERE DIVERTED = 1;


-- 6) DIVERSION RATE
SELECT
    ROUND(
        SUM(CASE WHEN DIVERTED = 1 THEN 1 ELSE 0 END)
        *100.0 /
        COUNT(*),
        2
    ) AS Diversion_Rate
FROM Airline_analysis;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 7) ARRIVAL DELAY

SELECT
    AVG(ARRIVAL_DELAY) AS Avg_Arrival_Delay,
    MIN(ARRIVAL_DELAY) AS Min_Arrival_Delay,
    MAX(ARRIVAL_DELAY) AS Max_Arrival_Delay
FROM Airline_analysis
WHERE ARRIVAL_DELAY IS NOT NULL;


-- 8) DEPARTURE DELAY
SELECT
    AVG(DEPARTURE_DELAY) AS Avg_Departure_Delay,
    MIN(DEPARTURE_DELAY) AS Min_Departure_Delay,
    MAX(DEPARTURE_DELAY) AS Max_Departure_Delay
FROM Airline_analysis
WHERE DEPARTURE_DELAY IS NOT NULL;


-- 9) MEDIAN DELAY
SELECT DISTINCT
PERCENTILE_CONT(0.5)
WITHIN GROUP (ORDER BY DEPARTURE_DELAY)
OVER() AS Median_Departure_Delay
FROM Airline_analysis
WHERE DEPARTURE_DELAY IS NOT NULL;
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 10) DELAY TYPE CONTRIBUTION PCT

SELECT 
    Delay_Type,
    Delay_Minutes,
    ROUND(Delay_Minutes * 100.0 / Total, 2) AS Contribution_Percent
FROM (
    SELECT 'Airline Delay' AS Delay_Type, SUM(AIRLINE_DELAY) AS Delay_Minutes FROM Airline_analysis
    UNION ALL
    SELECT 'Weather Delay', SUM(WEATHER_DELAY) FROM Airline_analysis
    UNION ALL
    SELECT 'NAS Delay', SUM(AIR_SYSTEM_DELAY) FROM Airline_analysis
    UNION ALL
    SELECT 'Late Aircraft Delay', SUM(LATE_AIRCRAFT_DELAY) FROM Airline_analysis
    UNION ALL
    SELECT 'Security Delay', SUM(SECURITY_DELAY) FROM Airline_analysis
) d
CROSS JOIN (
    SELECT SUM(AIRLINE_DELAY + WEATHER_DELAY + AIR_SYSTEM_DELAY + LATE_AIRCRAFT_DELAY + SECURITY_DELAY) AS Total
    FROM Airline_analysis
) t
ORDER BY Delay_Minutes DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 11) ON TIME PRFORMANCE RATE              ( taking Delay <= 15 Minutes and sevber delay > 1hour (60min) )
SELECT
  ROUND(
    SUM(
         CASE
             WHEN ARRIVAL_DELAY <= 15
             THEN 1
             ELSE 0
         END
        )* 100.0 / COUNT(ARRIVAL_DELAY), 2
    ) AS OTP_Rate
FROM Airline_analysis
WHERE CANCELLED = 0;


-- 12) DELAYD FLIGHT RATW
SELECT
  ROUND(
    SUM(
         CASE
           WHEN ARRIVAL_DELAY > 15
           THEN 1
           ELSE 0
            END
     ) *100.0 / COUNT(ARRIVAL_DELAY), 2
    ) AS Delayed_Flight_Rate
FROM Airline_analysis
WHERE CANCELLED = 0;    


-- 13) SEVERE DELAY RATE (assumption >1 Hour)

SELECT
      SUM(
          CASE
              WHEN ARRIVAL_DELAY > 60 THEN 1
              ELSE 0
          END) * 100.0 / COUNT(ARRIVAL_DELAY) AS Severe_Delay_Rate
FROM Airline_analysis
WHERE CANCELLED = 0;



-- 14) AIRLINE RELIABILITY
SELECT
    AIRLINE_NAME,
    AVG(ARRIVAL_DELAY) AS Avg_Arrival_Delay,
    SUM(CASE WHEN CANCELLED=1 THEN 1 ELSE 0 END) *100.0/COUNT(*) AS Cancellation_Rate,

SUM(
    CASE
      WHEN ARRIVAL_DELAY <=15 THEN 1
      ELSE 0
    END) *100.0 / COUNT(ARRIVAL_DELAY) AS OTP_Rate

FROM Airline_analysis
GROUP BY AIRLINE_NAME
ORDER BY OTP_Rate DESC;


-- 15) MOST DELAYED

SELECT TOP 20 
ORIGIN_AIRPORT + ' --- ' + DESTINATION_AIRPORT AS Route,
COUNT(*) AS Flights,
AVG(ARRIVAL_DELAY) AS Avg_Arrival_Delay
FROM Airline_analysis
GROUP BY ORIGIN_AIRPORT,DESTINATION_AIRPORT
HAVING COUNT(*) > 100
ORDER BY Avg_Arrival_Delay DESC;


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- BY AIRLINE 
SELECT
    AIRLINE_NAME,
    COUNT(*) AS Flights,
    AVG(ARRIVAL_DELAY) AS Avg_Arrival_Dely,
    AVG(DEPARTURE_DELAY) AS Avg_Departure_Delay,
    SUM(CASE WHEN ARRIVAL_DELAY <= 15 THEN 1 ELSE 0 END) * 100.0 / COUNT(ARRIVAL_DELAY) AS OTP_PCT
FROM Airline_analysis
GROUP BY AIRLINE_NAME
ORDER BY OTP_Rate DESC;

-- BY MONTH 
SELECT
    MONTH,
    COUNT(*) AS Flights,
    AVG(ARRIVAL_DELAY) AS Avg_Arr_Delay,
    AVG(DEPARTURE_DELAY) AS Avg_Dep_Delay
FROM Airline_analysis
GROUP BY MONTH
ORDER BY MONTH;

-- BY DAY 
SELECT
    TIME_OF_DAY,
    COUNT(*) AS Flights,
    AVG(ARRIVAL_DELAY) AS Avg_Arr_Deay,
    AVG(DEPARTURE_DELAY) AS Avg_Dep_Delay
FROM Airline_analysis
GROUP BY TIME_OF_DAY
ORDER BY Flights DESC;


-- BY AIRPORTS
SELECT TOP 20
    ORIGIN_AIRPORT_NAME,
    COUNT(*) AS Flights,
    AVG(ARRIVAL_DELAY) AS Avg_Arr_Delay,
    AVG(DEPARTURE_DELAY) AS Avg_Dep_Delay
FROM Airline_analysis
GROUP BY ORIGIN_AIRPORT_NAME
ORDER BY Avg_Dep_Delay DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT @@SERVERNAME AS ServerName;