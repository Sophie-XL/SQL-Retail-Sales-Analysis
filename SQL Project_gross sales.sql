-- Task #1: 
# Query gross sales data for a specific customer in one fiscal year: in the final table the following information should be included
# Month|Product Name|Product Variant|Sold quantity|Gross Price Per Item|Gross Price Total
-- Step 1: Find customer information
select * from dim_customer
where customer like "%croma%"; 
-- Step 2: Find transactions specific to Croma
select * from fact_sales_monthly
where customer_code = 90002002;
-- Step 3: Get trasaction data only for 2021: calendar year -> fiscal year
select *, year(date_add(date, interval 4 month)) as fiscal_year
from fact_sales_monthly
where customer_code = 90002002 and 
year(date_add(date, interval 4 month)) = 2021;
-- User defined function to short fiscal year
select *, get_fiscal_year(date) as fiscal_year
from fact_sales_monthly
where customer_code = 90002002 and 
get_fiscal_year(date) = 2021;
-- Select data from a specific fiscal quarter
select *, get_fiscal_quarter(date) as fiscal_quarter
from fact_sales_monthly
where customer_code = 90002002 and 
get_fiscal_year(date) = 2021 and
get_fiscal_quarter(date) = "Q4"
order by date
limit 1000000;
-- Add other columns to complete the request in task #1
select s.date, get_fiscal_year(s.date) as fiscal_year, s.product_code, 
s.customer_code, p.product, p.variant, s.sold_quantity, 
round(gp.gross_price,2) as grosss_price,
round((gp.gross_price*s.sold_quantity), 2) as gross_price_total
from fact_sales_monthly s
join dim_product p
using (product_code)
join fact_gross_price gp
on (s.product_code = gp.product_code and get_fiscal_year(s.date) = gp.fiscal_year)
where customer_code = 90002002 and 
get_fiscal_year(date) = 2021
limit 1000000;
-- Task #2: Total monthly sales for croma in 2021
select s.date, round(sum((gp.gross_price*s.sold_quantity)), 2) as gross_price_total
from fact_sales_monthly s
join fact_gross_price gp
on (s.product_code = gp.product_code and get_fiscal_year(s.date) = gp.fiscal_year)
where customer_code = 90002002
group by s.date
order by s.date;
-- Task #3: Generate a yearly report for Croma India where there are two columns
# 1. Fiscal Year
# 2. Total Gross Sales amount In that year from Croma
select 
	get_fiscal_year(s.date) as fiscal_year, 
	round(sum((gp.gross_price*s.sold_quantity)), 2) as gross_price_total
from fact_sales_monthly s
join fact_gross_price gp
on (s.product_code = gp.product_code and get_fiscal_year(s.date) = gp.fiscal_year)
where customer_code = 90002002
group by get_fiscal_year(s.date)
order by fiscal_year;
-- Task #4: Market Badge >5 million total quantity
select
c.market,
sum(s.sold_quantity) as total_sold_quantity,
get_badge(sum(s.sold_quantity)) as badge
from 
fact_sales_monthly s
join dim_customer c
on s.customer_code = c.customer_code
where c.market = "india" and get_fiscal_year(s.date)=2021
group by c. market;
-- Task #5: Get top selling product in each division
with cte2 as (
with cte1 as(
select 
division, product,
sum(sold_quantity) as total_quantity
from fact_sales_monthly s
join dim_product
using (product_code)
where fiscal_year = 2021
group by product, division
)
select *,
row_number() over(partition by division order by total_quantity desc) as rn,
rank() over(partition by division order by total_quantity desc) as rnk,
dense_rank() over(partition by division order by total_quantity desc) as drnk
from cte1
order by division
)
select rnk,
division, product, total_quantity
from cte2
where rnk<=3;
-- Task #6: Retrieve the top 2 markets in every region by their gross sales amount in FY=2021
with cte2 as (
with cte1 as (
select 
market,
region,
round(sum(gross_price_total)/1000000,2) as gross_sales_mln
 from gross_sales
 where fiscal_year = 2021
 group by market, region
 )
 select *,
 rank() over(partition by region order by gross_sales_mln desc) as rnk
 from cte1
 )
 select *
 from cte2
 where rnk <=2
 -- Task #7: Create stored procedures for
# a. gross sales for a specific customer in a given year as in task #1
# b. monthly gross sales data for selected customers
# c. top n selling products by gross sales in each division in a given year
# d. top n markets in every region by their gross sales amount in a given year