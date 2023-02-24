-- Q4. Plane Capacity Histogram

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
	airline CHAR(2),
	tail_number CHAR(5),
	very_low INT,
	low INT,
	fair INT,
	normal INT,
	high INT
);
 
---- FIND NUMBER OF BOOKINGS FOR EVERY FLIGHT WITH A DEPARTURE ----
DROP VIEW IF EXISTS flights_count_dep CASCADE;
create view flights_count_dep as
select
	departure.flight_id,
	(select count(*) from booking
	where departure.flight_id = booking.flight_id)
	from departure;


---- FIND NUMBER OF BOOKINGS FOR EVERY FLIGHT ----
---- NULL IF THERE IS NO DEPARTURE ----
drop view if exists flights_count cascade;
create view flights_count as
select
	flight.id as flight_id,
	flight.plane as tail_number,
	(select flights_count_dep.count from flights_count_dep
	where flights_count_dep.flight_id = flight.id)
from flight;


---- FINAL QUERY ----
drop view if exists plane_count cascade;
create view plane_count as
select
	plane.airline,
	plane.tail_number,
	(select count(*) from flights_count
	where plane.tail_number = flights_count.tail_number
	and cast(flights_count.count as float) /
	cast((plane.capacity_economy+plane.capacity_business+plane.capacity_first) as float) < 0.2) as very_low,
	(select count(*) from flights_count
	where plane.tail_number = flights_count.tail_number
	and cast(flights_count.count as float) /
	cast((plane.capacity_economy+plane.capacity_business+plane.capacity_first) as float) between 0.2 and 0.399999) as low,
	(select count(*) from flights_count
	where plane.tail_number = flights_count.tail_number
	and cast(flights_count.count as float) /
	cast((plane.capacity_economy+plane.capacity_business+plane.capacity_first) as float) between 0.4 and 0.599999) as fair,
	(select count(*) from flights_count
	where plane.tail_number = flights_count.tail_number
	and cast(flights_count.count as float) /
	cast((plane.capacity_economy+plane.capacity_business+plane.capacity_first) as float) between 0.6 and 0.799999) as normal,
	(select count(*) from flights_count
	where plane.tail_number = flights_count.tail_number
	and cast(flights_count.count as float) /
	cast((plane.capacity_economy+plane.capacity_business+plane.capacity_first) as float) >= 0.8) as high
from plane;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4
select * from plane_count;
