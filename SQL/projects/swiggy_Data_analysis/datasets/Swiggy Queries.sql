use swiggy_DB;

SELECT * FROM Swiggy_Data;

-- Data validation and Cleaning

-- NUll Check

Select 
	SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS null_state,
	SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS null_city,
	SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
	SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS null_location,
	SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS null_restaurant,
	SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS null_category,
	SUM(CASE WHEN Dish_Name IS NULL THEN 1 ELSE 0 END) AS null_disn_name,
	SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS null_price_inr,
	SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
	SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) AS null_rating_count
FROM swiggy_data;



--blank or empty strings...,

select *
from Swiggy_Data
where State = '' OR City='' OR Order_date='' OR Restaurant_Name=''
				 OR Location='' OR Category='' OR Dish_Name='';


-- Duplicate detection

select
State, City,Order_Date,Restaurant_Name,Location, Category,Dish_Name,Price_INR,Rating,Rating_Count,count(*) as count
from swiggy_data
group by
State, City,Order_Date,Restaurant_Name,Location, Category,Dish_Name,Price_INR,Rating,Rating_Count
having count(*)>1;


-- Delete Duplicates

with CTE as(
	Select *, ROW_NUMBER() over(
		partition by State,City,Order_Date,Restaurant_Name,Location,Category,Dish_Name,
	Price_INR,Rating,Rating_count 
	order by (select null)
	) as rn
	from swiggy_data
	) Delete from CTE where rn>1;


-- create Schema

-- creating the Dimensional tables
-- data Table

create table dim_date(
	date_id int identity(1,1) primary key,
	Full_Date DATE,
	Year int,
	Month int,
	Month_Name varchar(20),
	Quarter int,
	Day int,
	week int
)

select * from dim_date;


-- create the dimension location table
create table dim_location(
	location_id int identity(1,1) primary key,
	state varchar(100),
	city varchar(100),
	location varchar(200),
)

select * from dim_location;


--create the dim restaurant table

create table dim_restaurant(
	restaurant_id int identity(1,1) primary key,
	restaurant_name varchar(200)
);

select * from dim_restaurant;


-- create dim category date table
create table dim_category(
	category_id int identity(1,1) primary key,
	category varchar(200)
);

select * from dim_restaurant;


-- create dim dish table

create table dim_dish(
	dish_id int identity(1,1) primary key,
	dish_name varchar(200)
);

select * from dim_dish;


-- creating the fact table

create table fact_swiggy_orders(
	order_id int identity(1,1) primary key,

	date_id int,
	Price_INR decimal(10,2),
	Rating Decimal(4,2),
	Rating_Count int,

	location_id int,
	restaurant_id int,
	category_id int,
	dish_id int,

	foreign key (date_id) references dim_date(date_id),
	foreign key (location_id) references dim_location(location_id),
	foreign key (restaurant_id) references dim_restaurant(restaurant_id),
	foreign key (category_id) references dim_category(category_id),
	foreign key (dish_id) references dim_dish(dish_id)

);


select * from swiggy_data;

drop table fact_swiggy_orders;




-- now insert the data into the dimension tables
-- insert data into dim_date table

insert into dim_date (Full_Date,Year,Month,Month_Name,Quarter,Day,week)
select Distinct
	Order_Date,
	year(Order_Date),
	month(Order_Date),
	datename(month,Order_Date),
	datepart(Quarter,Order_Date),
	day(Order_Date),
	datepart(week,Order_Date)
from swiggy_data
where order_date is not null;

-- query to get the day name in a week based on date

SELECT Full_Date,
       DATENAME(WEEKDAY, Full_Date) AS Day_Name
FROM dim_date;


insert into dim_location(State,City,location)
select distinct
	State,
	City,
	location
	from swiggy_data;


	-- inserting the restaurant data into dim_restaurant  table

insert into dim_restaurant(restaurant_name)
select Distinct
	Restaurant_Name
from swiggy_data;


select * from dim_restaurant;

-- insert the data into the dim_category table
insert into dim_category(category)
select distinct
 category
 from swiggy_data;

 select * from dim_category;


 --insert data into dim_dish table

 insert into dim_dish(dish_name)
 select distinct dish_name
 from swiggy_data;




 -- insert the data into the fact table
 
INSERT INTO fact_swiggy_orders
(
    date_id,
    Price_INR,
    Rating,
    Rating_Count,
    location_id,
    restaurant_id,
    category_id,
    dish_id
)
SELECT 
    dd.date_id,
    s.Price_INR,
    s.Rating,
    s.Rating_Count,
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    dsh.dish_id
FROM swiggy_data s
JOIN dim_date dd
    ON dd.Full_Date = s.Order_Date
JOIN dim_location dl
    ON dl.state = s.State
   AND dl.city = s.City
   AND dl.location = s.Location
JOIN dim_restaurant dr
    ON dr.restaurant_name = s.restaurant_name
JOIN dim_category dc
    ON dc.category = s.category
JOIN dim_dish dsh
    ON dsh.dish_name = s.Dish_Name;


select * from fact_swiggy_orders;

SELECT * FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
JOIN dim_location l ON f.location_id = l.location_id
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
JOIN dim_category c ON f.category_id = c.category_id
JOIN dim_dish di ON f.dish_id=di.dish_id;




-- kpis
-- total orders

select count(*) as Total_orders
from fact_swiggy_orders;


-- total revenue
select format(sum(convert(float,Price_INR))/100000 ,'N2') + ' INR Million' as Total_revenue
from fact_swiggy_orders;


-- Average Dish Price

select format(Avg(convert(float,Price_INR)),'N2')+' INR' as Average_dish_price
from fact_swiggy_orders;


-- Aerage rating
select avg(Rating) as average_rating
from fact_swiggy_orders;



-- Monthly Orders trends

select
d.year,
d.month,
d.month_name,
count(*) as total_orders
from fact_swiggy_orders f
join dim_date d on f.date_id = d.date_id
group by 
d.year,d.month,d.month_name
order by count(*) desc;



-- total revenue

select
d.year,
d.month,
d.month_name,
sum(Price_INR) as total_revenue
from fact_swiggy_orders f
join dim_date d on f.date_id = d.date_id
group by 
d.year,d.month,d.month_name
order by sum(Price_INR) desc;


-- quarterly oredr trends

select
d.year,
d.quarter,
count(*) as Quarterly_orders
from fact_swiggy_orders f
join dim_date d on f.date_id = d.date_id
group by 
d.year,d.quarter
order by count(*) desc;


-- orders by dsy of week
select
d.year,
d.quarter,
count(*) as Quarterly_orders
from fact_swiggy_orders f
join dim_date d on f.date_id = d.date_id
group by 
d.year,d.quarter
order by count(*) desc;


-- get the revenue from the weekdays
select 
	datename(weekday,d.full_date) as day_name,
	count(*) as total_orders
from fact_swiggy_orders f
join dim_date d on f.date_id = d.date_id
group by datename(weekday,d.full_date), datepart(weekday,d.full_date)
order by datepart(weekday,d.full_date);


-- top 10 cites by order value
select top 10
l.city,10,count(*) as total_orders from fact_swiggy_orders f
join dim_location l on l.location_id = f.location_id
group by l.city;



select top 10
l.city,10,sum(f.Price_INR) as total_orders from fact_swiggy_orders f
join dim_location l on l.location_id = f.location_id
group by l.city
order by sum(f.Price_INR) asc;



--- revenue contribution of the states

select
l.State,sum(f.Price_INR) as total_orders from fact_swiggy_orders f
join dim_location l on l.location_id = f.location_id
group by l.State
order by sum(f.Price_INR) asc;

-- if want top 10

select top 10
l.State,sum(f.Price_INR) as total_orders from fact_swiggy_orders f
join dim_location l on l.location_id = f.location_id
group by l.State
order by sum(f.Price_INR) asc;



-- top 10 restaurants by order

select top 10
dr.restaurant_name,count(*) as total_orders from fact_swiggy_orders f
join dim_restaurant dr on dr.restaurant_id = f.restaurant_id
group by dr.restaurant_name
order by count(*) desc;



-- top 10 retsaurants by revenue 

select top 10
dr.restaurant_name,sum(f.Price_INR) as total_orders from fact_swiggy_orders f
join dim_restaurant dr on dr.restaurant_id = f.restaurant_id
group by dr.restaurant_name
order by sum(f.Price_INR) desc;


-- top categorys
select top 10
dc.category,count(*) as total_orders from fact_swiggy_orders f
join dim_category dc on dc.category_id = f.category_id
group by dc.category
order by count(*) desc;



-- most ordered dishes
select
 d.dish_name,count(*) as total_orders
 from fact_swiggy_orders f
 join dim_dish d on d.dish_id = f.dish_id
 group by d.dish_name
 order by count(*) desc;


 -- most top 10 orders foods are
 select top 10
 d.dish_name,count(*) as total_orders
 from fact_swiggy_orders f
 join dim_dish d on d.dish_id = f.dish_id
 group by d.dish_name
 order by count(*) desc;



 -- cusine performance(orders + avg Rating )

 select top 10
dc.category,
count(*) as total_orders,
avg(convert(float,f.rating)) as avg_rating
from fact_swiggy_orders f
join dim_category dc on dc.category_id = f.category_id
group by dc.category
order by count(*) desc;

-- orders based on the price range 
select
	case
		when CONVERT(float,Price_INR) > 100 then 'under 100'
		when CONVERT(float,Price_INR)  between 100 and 199 then '100-199'
		when CONVERT(float,Price_INR)  between 200 and 299 then '200-299'
		when CONVERT(float,Price_INR)  between 300 and 499 then '300-499'
		Else '500+'
	end as price_range,count(*) as total_orders
	from fact_swiggy_orders
	group by
		case
			when CONVERT(float,Price_INR) > 100 then 'under 100'
			when CONVERT(float,Price_INR)  between 100 and 199 then '100-199'
			when CONVERT(float,Price_INR)  between 200 and 299 then '200-299'
			when CONVERT(float,Price_INR)  between 300 and 499 then '300-499'
			Else '500+'
	     end
		order by total_orders desc;



		--- Rating count distribution

select
	rating,
	count(*) as rating_count
	from fact_swiggy_orders
		group by rating
		order by count(*) desc;