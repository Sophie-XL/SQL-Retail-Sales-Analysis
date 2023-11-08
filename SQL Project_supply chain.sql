-- Task #1
-- Create a physical helper table combining sold & forecast quantity
create table fact_act_est
(
SELECT 
date,
product_code,
customer_code,
sold_quantity,
forecast_quantity
from fact_sales_monthly s
left join fact_forecast_monthly f
using (date, product_code, customer_code)
union
SELECT 
date,
product_code,
customer_code,
sold_quantity,
forecast_quantity
from fact_sales_monthly s
right join fact_forecast_monthly f
using (date, product_code, customer_code)
);
-- Task #2
-- update table to replace NA quantities with 0
update fact_act_est
set forecast_quantity = 0
where forecast_quantity is null;
update fact_act_est
set sold_quantity = 0
where sold_quantity is null;
-- Task #3
-- Create trigger to auto update the newly created table
show triggers;
-- Task #4
-- insert new record into original fact tables and make sure the new helper table is updated automatically
insert into fact_sales_monthly
	(date, product_code, customer_code, sold_quantity)
    values ("2030-09-01", "HAHA", 99, 98);
select * from fact_act_est
where product_code= "HAHA";
insert into fact_forecast_monthly
	(date, product_code, customer_code, forecast_quantity)
    values ("2030-09-01", "HAHA", 99, 43);
select * from fact_forecast_monthly
where product_code= "HAHA";
-- Task #5
-- Generate forecast accuracy data table using CTE approach
with cte1 as (
select
customer_code,
sum(sold_quantity) as total_sold_qty,
sum(forecast_quantity) as total_forcast_qty,
sum((forecast_quantity - sold_quantity)) as net_err,
round(sum((forecast_quantity - sold_quantity))*100/sum(forecast_quantity),2) as net_err_per, -- use sum separately for numerator and denominator
sum(abs(forecast_quantity - sold_quantity)) as abs_err,
round(sum(abs(forecast_quantity - sold_quantity))*100/sum(forecast_quantity),2) as abs_err_per
from fact_act_est
where fiscal_year = 2021
group by customer_code
)
select 
customer_code,
customer as customer_name,
market,
total_sold_qty,
total_forcast_qty,
net_err,
net_err_per,
abs_err,
abs_err_per,
if (abs_err_per > 100, 0, 100-abs_err_per) as forecast_accuracy
from cte1
join dim_customer
using (customer_code)
order by forecast_accuracy
;
-- Task #5
-- Generate forecast accuracy data table using a temorary table (valid for the whole session)
create temporary table forecast_err_table
select
customer_code,
sum(sold_quantity) as total_sold_qty,
sum(forecast_quantity) as total_forcast_qty,
sum((forecast_quantity - sold_quantity)) as net_err,
round(sum((forecast_quantity - sold_quantity))*100/sum(forecast_quantity),2) as net_err_per, -- use sum separately for numerator and denominator
sum(abs(forecast_quantity - sold_quantity)) as abs_err,
round(sum(abs(forecast_quantity - sold_quantity))*100/sum(forecast_quantity),2) as abs_err_per
from fact_act_est
where fiscal_year = 2021
group by customer_code;
-- Task #6
-- a. Prodide data to understand which customers’ forecast accuracy has dropped from 2020 to 2021. 
-- b. Generate a complete report with these columns: customer_code, customer_name, market, forecast_accuracy_2020, forecast_accuracy_2021
with cte2021 as
(with cte1 as (
select
customer_code,
sum(abs(forecast_quantity - sold_quantity)) as abs_err,
round(sum(abs(forecast_quantity - sold_quantity))*100/sum(forecast_quantity),2) as abs_err_per
from fact_act_est
where fiscal_year = 2021
group by customer_code
)

select 
customer_code,
customer as customer_name,
market,
if (abs_err_per > 100, 0, 100-abs_err_per) as forecast_accuracy_2021
from cte1
join dim_customer
using (customer_code)
),
cte2020 as
(with cte1 as (
select
customer_code,
sum(abs(forecast_quantity - sold_quantity)) as abs_err,
round(sum(abs(forecast_quantity - sold_quantity))*100/sum(forecast_quantity),2) as abs_err_per
from fact_act_est
where fiscal_year = 2020
group by customer_code
)
select 
customer_code,
customer as customer_name,
market,
if (abs_err_per > 100, 0, 100-abs_err_per) as forecast_accuracy_2020
from cte1
join dim_customer
using (customer_code)
)
select cte2021.*,
cte2020.forecast_accuracy_2020,
forecast_accuracy_2021-forecast_accuracy_2020 as forecast_accuracy_change
from cte2021
join cte2020
using (customer_code)
where forecast_accuracy_2021<forecast_accuracy_2020 and forecast_accuracy_2021>0
order by forecast_accuracy_change;
-- Task #7: Provide user access to the database
show grants for 'wonda';
-- Task #8: Improve SQL query performance by adding useful indexes
show indexes in fact_act_est;
explain analyze
select * from fact_act_est where fiscal_year = 2020
limit 1000000
-- indext types
#1. unique, 2. primary, 3. regular or normal index, 4. fulltext

