/*
Philly Housing Exploration

Skills used: Creating Tables, Creating Temp Tables, Window Functions, Aggregate Functions, Case When Statements,
CTEs, Subqueries, Like Operator, Having Clause

*/

---preview the data, limiting to first 10 rows
select top 10 *
from Portfolio..philly_housing;

---create a new table with only the data we will need; split date column into year, month, and day columns; exlude null addresses
select address,
sale_date,
DATEPART(year, sale_date) as year,
DATEPART(month, sale_date) as month,
DATEPART(day, sale_date) as day,
opening_bid,
sale_price_bid_price,
postal_code,
attorney,
ward,
seller,
buyer,
avg_walk_transit_score,
violent_crime_rate,
school_score,
zillow_estimate,
rent_estimate,
yearBuilt,
finished_SqFt,
bathrooms,
bedrooms,
PropType,
Average_comps
into philly_housing_2
from Portfolio..philly_housing
where address is not null;

---look at top 10 rows in new table
select top 10 *
from philly_housing_2;

---find how many records are in the data
select COUNT(*) as record_count
from philly_housing_2;

---find first and last sale date in the data
select MIN(sale_date)
from philly_housing_2;

select MAX(sale_date)
from philly_housing_2;

---find top 10 most expensive homes/least expensive homes
select top 10 address, seller, buyer, zillow_estimate
from philly_housing_2
order by zillow_estimate desc;

select top 10 address, seller, buyer, zillow_estimate
from philly_housing_2
order by zillow_estimate;

---find average rent across the data
select AVG(rent_estimate) as Average_rent
from philly_housing_2;

---use CTE to find number of apartments/average rent for each apartment type
with bedroom_table as
(select address, bedrooms, rent_estimate,
case
	when bedrooms = 1 then '1 bedroom apt'
	when bedrooms = 2 then '2 bedroom apt'
	when bedrooms = 3 then '3 bedroom apt'
	when bedrooms = 4 then '4 bedroom apt'
	when bedrooms = 5 then '5 bedroom apt'
	when bedrooms = 6 then '6 bedroom apt'
	else 'N/A'
end as apt_type
from philly_housing_2)
select apt_type, COUNT(*) as number_of_apts, AVG(rent_estimate) as avg_rent
from bedroom_table
group by apt_type
order by apt_type;

---find average rent/number of properties bought by buyer/seller/ward; include only those with average rent of 1200 or more
select buyer, AVG(rent_estimate) as Avg_rent,
count(*) as record_count
from philly_housing_2
group by buyer
having AVG(rent_estimate) >= 1200
order by Avg_rent desc, record_count desc, buyer;

select seller, AVG(rent_estimate) as Avg_rent,
count(*) as record_count
from philly_housing_2
group by seller
having AVG(rent_estimate) >= 1200
order by Avg_rent desc, record_count desc, seller;

select ward, AVG(rent_estimate) as Avg_rent,
count(*) as record_count
from philly_housing_2
group by ward
having AVG(rent_estimate) >= 1200
order by Avg_rent desc, record_count desc, ward;

---find all the records where the school score is between 25 and 50 and the violent crime rate is less than 0.5
select * from philly_housing_2
where school_score between 25 and 50
and violent_crime_rate < 0.5
order by school_score;

---find all the addresses/rent for where the seller is Wells Fargo Bank
select distinct address, seller, postal_code,
rent_estimate
from philly_housing_2
where seller like 'Wells Fargo%'
order by rent_estimate desc;

---find all the addresses/rent for where the buyer is Phelan Hallinan LLP
select distinct address, buyer, postal_code,
rent_estimate
from philly_housing_2
where buyer like 'Phelan%'
order by rent_estimate desc;

---create a temp table for only August and September data; then use a subquery to pull specific information about August and September data
select *
into #Aug_Sept_sales
from philly_housing_2
where month = 8 or month = 9;

select address, sale_date, ward, rent_estimate
from philly_housing_2
where address in (
select address
from #Aug_Sept_sales)
order by sale_date, rent_estimate desc, address;

---find average cost for different property types, along with the total comps and number of properties for each property type
select PropType, AVG(zillow_estimate) as Avg_Cost, 
SUM(Average_comps) as total_comps,
COUNT(*) as Number_of_properties
from philly_housing_2
group by PropType
order by Avg_Cost desc;

---find average cost for different postal codes
select postal_code, AVG(zillow_estimate) as Avg_Cost
from philly_housing_2
group by postal_code
order by Avg_Cost desc;

---find addresses, property types, and zip codes with a new column for average rent by zip code
select address, proptype, postal_code,
AVG(rent_estimate) over (partition by postal_code) as avg_rent
from philly_housing_2
order by avg_rent desc;

---find houses in center city zip codes
select address, 
sale_date,
seller, 
buyer,
postal_code
from philly_housing_2
where postal_code in (19102, 19103, 19106, 19107, 19146, 19147)
order by postal_code, address;

---find the average cost for each house, based on year built; also show how many houses there are for each year in the data
select yearBuilt, AVG(zillow_estimate) as Avg_Cost, count(*) as house_count
from philly_housing_2
group by yearBuilt
order by Avg_Cost desc;

---find sale price minus opening bid
select address, buyer, seller, 
sale_price_bid_price, opening_bid,
sale_price_bid_price - opening_bid as price_increase
from philly_housing_2
order by price_increase desc;

---use a CTE to find aggregations based off of rent classification
with rent_table as
(select address, rent_estimate,
case 
	when rent_estimate < 1000 then 'cheap'
	when rent_estimate between 1000 and 2000 then 'average'
	when rent_estimate between 2001 and 3000 then 'expensive'
	else 'very expensive'
end as rent_classification
from philly_housing_2
order by rent_estimate desc offset 0 rows)
select rent_classification, AVG(rent_estimate) as avg_rent, MIN(rent_estimate) as min_rent, MAX(rent_estimate) as max_rent, SUM(rent_estimate) as sum_rent, count(*) as number_of_homes
from rent_table
group by rent_classification
order by avg_rent desc;

