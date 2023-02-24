-- Q1. Airlines  
  
-- You must not change the next 2 lines or the table definition.  
SET SEARCH_PATH TO air_travel;  
DROP TABLE IF EXISTS q1 CASCADE;  
  
CREATE TABLE q1 (  
    pass_id INT,  
    name VARCHAR(100),  
    airlines INT  
);  
  
  
---- PASSENGER THAT HAVE TAKEN AT LEAST ONE FLIGHT ----  
DROP VIEW IF EXISTS pass_flight CASCADE;  
create view pass_flight as  
select  
    booking.pass_id,  
    booking.flight_id,  
    flight.airline  
from booking, flight, departure  
where booking.flight_id = flight.id  
and booking.flight_id = departure.flight_id;  
  
  
-- Your query that answers the question goes below the "insert into" line:  
INSERT INTO q1  
select  
    passenger.id,  
    concat(passenger.firstname, ' ', passenger.surname) as name,  
    (select count(distinct pass_flight.airline)  
    from pass_flight  
    where pass_flight.pass_id = passenger.id) as airlines  
from passenger  
group by passenger.id, name;  
