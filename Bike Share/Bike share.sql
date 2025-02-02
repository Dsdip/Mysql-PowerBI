create database bike_share;

use bike_share;

-- update 2021 tables data
select * from bike_share_yr_0
limit 5;

-- Diactive Safe update mode
SET SQL_SAFE_UPDATES = 0;

-- Change the data to date 
UPDATE bike_share_yr_0
SET Date = STR_TO_DATE(Date, '%d/%m/%Y');

-- Change the column datatype text to Date
alter table bike_share_yr_0
modify column `Date` DATE;

-- Change year value 0 to 2021
UPDATE bike_share_yr_0
SET Year = 2021
WHERE Year = 0;



-- update 2022 tables data

select * from bike_share_yr_1
limit 5;

-- Change the data to date 
UPDATE bike_share_yr_1
SET Date = STR_TO_DATE(Date, '%d/%m/%Y');

-- Change the column datatype text to Date
alter table bike_share_yr_1
modify column `Date` DATE;

-- Change year value 0 to 2021
UPDATE bike_share_yr_1
SET Year = 2022
WHERE Year = 1;

-- update year in cost table
UPDATE cost_table
SET year = CASE 
    WHEN year = 0 THEN 2021
    WHEN year = 1 THEN 2022
END;

select * from cost_table;


-- Active Safe update mode
SET SQL_SAFE_UPDATES = 1;



-- Final project query

with fact as (
select * from bike_share_yr_0
union
select * from bike_share_yr_1)

select 
	f.Date,
    f.season,
    f.Year,
    f.Month,
    f.Hour,
    f.Weekday,
    f.rider_type,
    f.riders,
    ct.price,
    ct.COGS,
    round((f.riders * ct.price),2) as Revenue,
    round((f.riders * ct.price) - (f.riders * ct.COGS),2) AS profit
from fact as f
  left join 
cost_table as ct on f.Year = ct.Year;


create view Fact_table as (
with fact as (
select * from bike_share_yr_0
union
select * from bike_share_yr_1)

select 
	f.Date,
    f.season,
    f.Year,
    f.Month,
    f.Hour,
    f.Weekday,
    f.rider_type,
    f.riders,
    ct.price,
    ct.COGS,
    round((f.riders * ct.price),2) as Revenue,
    round((f.riders * ct.price) - (f.riders * ct.COGS),2) AS profit
from fact as f
  left join 
cost_table as ct on f.Year = ct.Year
);

select * from fact_table;