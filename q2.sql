-- Q2. Refunds!

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2 (
    airline CHAR(2),
    name VARCHAR(50),
    year CHAR(4),
    seat_class seat_class,
    refund REAL
);


---- COMPLETED DOMESTIC FLIGHTS ----
DROP VIEW IF EXISTS DmsFlights CASCADE;
CREATE VIEW DmsFlights AS
SELECT 'Domestic' AS type, Flight.id AS flight_id, Flight.airline,
       Flight.outbound, Flight.inbound,
       Flight.s_dep AS scheduled_departure,
       Departure.datetime AS actual_departure,
       Flight.s_arv AS scheduled_arrival,
       Arrival.datetime AS actual_arrival
FROM Flight, Departure, Arrival
WHERE Flight.id = Departure.flight_id AND
      Departure.flight_id = Arrival.flight_id AND
      (inbound, outbound) IN (SELECT A1.code AS inbound, A2.code outbound
                              FROM Airport A1, Airport A2
                              WHERE A1.code != A2.code AND
                                    A1.country = A2.country);


---- COMPLETED INTERNATIONAL FLIGHTS ----
DROP VIEW IF EXISTS IntlFlights CASCADE;
CREATE VIEW IntlFlights AS
SELECT 'International' AS type, Flight.id AS flight_id, Flight.airline,
       Flight.outbound, Flight.inbound,
       Flight.s_dep AS scheduled_departure,
       Departure.datetime AS actual_departure,
       Flight.s_arv AS scheduled_arrival,
       Arrival.datetime AS actual_arrival
FROM Flight, Departure, Arrival
WHERE Flight.id = Departure.flight_id AND
      Departure.flight_id = Arrival.flight_id AND
      (inbound, outbound) IN (SELECT A1.code AS inbound, A2.code outbound
                              FROM Airport A1, Airport A2
                              WHERE A1.code != A2.code AND
                                    A1.country != A2.country);


---- INTERNATIONAL FLIGHTS: DELAYED HOURS INCLUDING ON TIME FLIGHTS ----
DROP VIEW IF EXISTS IntlDelays CASCADE;
CREATE VIEW IntlDelays AS
SELECT EXTRACT(YEAR FROM scheduled_departure) AS year, flight_id, airline,
       (actual_departure - scheduled_departure) AS departure_delay,
       (actual_arrival - scheduled_arrival) AS arrival_delay
FROM IntlFlights;


---- INTERNATIONAL FLIGHTS: REFUND ELIGIBILITY ----
DROP VIEW IF EXISTS IntlRefundInfo CASCADE;
CREATE VIEW IntlRefundInfo AS
SELECT *,
CASE WHEN arrival_delay > (departure_delay / 2) AND
          '12:00:00' > departure_delay AND departure_delay >= '08:00:00'
      THEN 0.35
     WHEN arrival_delay > (departure_delay / 2) AND
          departure_delay >= '12:00:00'
      THEN 0.50
     ELSE 0.00
END AS refund_pct
FROM IntlDelays;


---- INTERNATIONAL FLIGHTS: REFUNDED MONEY FOR EACH PASSENGER ----
DROP VIEW IF EXISTS IntlRefunds CASCADE;
CREATE VIEW IntlRefunds AS
SELECT year, Booking.id AS booking_id, Booking.pass_id, Booking.flight_id,
       price, seat_class, IntlRefundInfo.airline, IntlRefundInfo.refund_pct,
       (price * refund_pct) AS refund_money
FROM Booking, IntlRefundInfo
WHERE Booking.flight_id = IntlRefundInfo.flight_id;


---- DOMESTIC FLIGHTS: DELAYED HOURS INCLUDING ON-TIME FLIGHTS ----
DROP VIEW IF EXISTS DmsDelays CASCADE;
CREATE VIEW DmsDelays AS
SELECT EXTRACT(YEAR FROM scheduled_departure) AS year, flight_id, airline,
       (actual_departure - scheduled_departure) AS departure_delay,
       (actual_arrival - scheduled_arrival) AS arrival_delay
FROM DmsFlights;


---- DOMESTIC FLIGHTS: REFUND ELIGIBILITY ----
DROP VIEW IF EXISTS DmsRefundInfo CASCADE;
CREATE VIEW DmsRefundInfo AS
SELECT *,
CASE WHEN arrival_delay > (departure_delay / 2) AND
          '10:00:00' > departure_delay AND departure_delay >= '05:00:00'
      THEN 0.35
     WHEN arrival_delay > (departure_delay / 2) AND
          departure_delay >= '10:00:00'
      THEN 0.50
     ELSE 0.00
END AS refund_pct
FROM DmsDelays;


---- DOMESTIC FLIGHTS: REFUNDED MONEY FOR EACH PASSENGER ----
DROP VIEW IF EXISTS DmsRefunds CASCADE;
CREATE VIEW DmsRefunds AS
SELECT year, Booking.id AS booking_id, Booking.pass_id, Booking.flight_id,
       price, seat_class, DmsRefundInfo.airline, DmsRefundInfo.refund_pct,
       (price * refund_pct) AS refund_money
FROM Booking, DmsRefundInfo
WHERE Booking.flight_id = DmsRefundInfo.flight_id;


---- UNION OF INTERNATIONAL AND DOMESTIC FLIGHTS ----
DROP VIEW IF EXISTS AirlineRefunds CASCADE;
CREATE VIEW AirlineRefunds AS
(SELECT year, airline, seat_class, refund_money FROM DmsRefunds)
UNION
(SELECT year, airline, seat_class, refund_money FROM IntlRefunds);


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2
SELECT airline, Airline.name AS name, year,
       seat_class, sum(refund_money) AS refund
FROM AirlineRefunds, Airline
WHERE AirlineRefunds.airline = Airline.code
GROUP BY(airline, name, year, seat_class);
