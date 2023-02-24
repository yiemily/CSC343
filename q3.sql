-- Q3. North and South Connections

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    outbound VARCHAR(30),
    inbound VARCHAR(30),
    direct INT,
    one_con INT,
    two_con INT,
    earliest timestamp
);


---- CREATE TEMP VIEW TO FACILITATE PROCESS ----
DROP VIEW IF EXISTS temp CASCADE;
create view temp as
select
	flight.outbound as outbound_code,
	flight.inbound as inbound_code,
	flight.s_dep,
	flight.s_arv,
	airport.city as outbound,
	airport.country as outbound_country
from flight join airport
on flight.outbound = airport.code;


---- DIRECT FLIGHTS ----
drop view if exists direct_flights cascade;
create view direct_flights as
select
	temp.outbound_code,
	temp.inbound_code,
	temp.s_dep,
	temp.s_arv,
	temp.outbound,
	temp.outbound_country,
	airport.city as inbound,
	airport.country as inbound_country
from
	temp join airport
	on temp.inbound_code = airport.code
where
	temp.s_dep between '2022-04-30' and '2022-04-30 23:59:59'
	and temp.s_arv between '2022-04-30' and '2022-04-30 23:59:59';


---- ONE-CONNECTION FLIGHTS ----
drop view if exists one_con_flights cascade;
create view one_con_flights as
select
	f1.outbound_code as outbound_code,
	f1.inbound_code as con_code,
	f2.inbound_code as inbound_code,
	f1.s_dep as dep,
	f1.s_arv as con_arv,
	f2.s_dep as con_dep,
	f2.s_arv as arv,
	f1.outbound as outbound,
	f1.outbound_country as outbound_country,
	f1.inbound as con,
	f1.inbound_country as con_country,
	f2.inbound as inbound,
	f2.inbound_country as inbound_country
from
	direct_flights f1 join direct_flights f2
	on f1.inbound_code = f2.outbound_code
where
	f2.s_dep-f1.s_arv >= '00:30:00'
	and f1.s_dep between '2022-04-30' and '2022-04-30 23:59:59'
	and f2.s_arv between '2022-04-30' and '2022-04-30 23:59:59';


---- TWO-CONNECTION FLIGHTS ----
drop view if exists two_con_flights cascade;
create view two_con_flights as
select
	f1.outbound_code as outbound_code,
	f1.con_code as con1_code,
	f1.inbound_code as con2_code,
	f2.inbound_code as inbound_code,
	f1.dep as dep,
	f1.con_arv as con1_arv,
	f1.con_dep as con1_dep,
	f1.arv as con2_arv,
	f2.s_dep as con2_dep,
	f2.s_arv as arv,
	f1.outbound as outbound,
	f1.outbound_country as outbound_country,
	f1.con as con1,
	f1.con_country as con1_country,
	f1.inbound as con2,
	f1.inbound_country as con2_country,
	f2.inbound as inbound,
	f2.inbound_country as inbound_country
from
	one_con_flights f1 join direct_flights f2
	on f1.inbound_code = f2.outbound_code
where
	f2.s_dep-f1.arv >= '00:30:00'
	and f1.dep between '2022-04-30' and '2022-04-30 23:59:59'
	and f2.s_arv between '2022-04-30' and '2022-04-30 23:59:59';


---- US-CANADA CITY PAIRS ----
drop view if exists city_pairs cascade;
create view city_pairs as
select distinct
	a1.city as a1_city,
	a1.country as a1_country,
	a2.city as a2_city,
	a2.country as a2_country
from airport a1, airport a2
where
	a1.country='Canada' and a2.country='USA'
	or a1.country='USA' and a2.country='Canada';


---- FINAL QUERY ----
INSERT INTO q3
select
	city_pairs.a1_city as outbound,
	city_pairs.a2_city as inbound,
	(select count(*)
	from direct_flights as f
	where f.outbound = city_pairs.a1_city
	and f.inbound = city_pairs.a2_city) as direct,
	(select count(*)
	from one_con_flights as cf
	where cf.outbound = city_pairs.a1_city
	and cf.inbound = city_pairs.a2_city) as one_con,
	(select count(*)
	from two_con_flights as c2f
	where c2f.outbound = city_pairs.a1_city
	and c2f.inbound = city_pairs.a2_city) as two_con,
	(select least(
	(select min(s_arv)
	from direct_flights as f
	where f.outbound = city_pairs.a1_city
	and f.inbound = city_pairs.a2_city),
	(select min(arv)
	from one_con_flights as cf
	where cf.outbound = city_pairs.a1_city
	and cf.inbound = city_pairs.a2_city),
	(select min(arv)
	from two_con_flights as c2f
	where c2f.outbound = city_pairs.a1_city
	and c2f.inbound = city_pairs.a2_city))) as earliest
from city_pairs;
