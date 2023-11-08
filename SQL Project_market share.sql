-- Task #1
-- Calculate Net Sales: Net Sales = Gross Sales - Pre-invoice discount - Post-invoice discount
select 
	s.date,
    get_fiscal_year(s.date) as fiscal_year, 
    s.product_code, 
    s.customer_code, 
    gp.gross_price,
    s.sold_quantity,
	round((gp.gross_price*s.sold_quantity), 2) as gross_sales,
    pre_invoice_discount_pct,
    gp.gross_price*s.sold_quantity*(1-pre_invoice_discount_pct) as net_invoice_sales,
    (pod.discounts_pct + pod.other_deductions_pct) as post_invoice_discount_pct,
    gp.gross_price*s.sold_quantity*(1-pre_invoice_discount_pct)*(1-pod.discounts_pct-pod.other_deductions_pct) as net_sales
from fact_sales_monthly s
join fact_gross_price gp
on (s.product_code = gp.product_code and get_fiscal_year(s.date) = gp.fiscal_year)
join fact_pre_invoice_deductions ped
on (s.customer_code = ped.customer_code and get_fiscal_year(s.date) = ped.fiscal_year)
join fact_post_invoice_deductions pod
on 
s.customer_code = pod.customer_code and 
s.product_code = pod.product_code and
s.date = pod.date
order by s.customer_code;
-- Task #2
-- Use Explain Analyze to understand the performance of the query
explain analyze
select 
	s.date,
    s.fiscal_year, 
    s.product_code, 
    s.customer_code,
    c.customer, 
    c.market,
    gp.gross_price,
    s.sold_quantity,
	round((gp.gross_price*s.sold_quantity), 2) as gross_price_total,
    pre_invoice_discount_pct,
    pod.discounts_pct,
    pod.other_deductions_pct,
    (gp.gross_price*s.sold_quantity*(1-pre_invoice_discount_pct)*(1-pod.discounts_pct-pod.other_deductions_pct)) as net_sales
from fact_sales_monthly s
join dim_customer c
on s.customer_code = c.customer_code
join fact_gross_price gp
on (s.product_code = gp.product_code and s.fiscal_year = gp.fiscal_year)
join fact_pre_invoice_deductions ped
on (s.customer_code = ped.customer_code and s.fiscal_year = ped.fiscal_year)
join fact_post_invoice_deductions pod
on 
s.customer_code = pod.customer_code and 
s.product_code = pod.product_code and
s.date = pod.date;
-- Task #2: Create a database View for Net Sales table
-- Task #3: Identify top market, top customer and top product by Net Sales with database view
# TOP MARKET
select
market,
round(sum((net_sales)/1000000),2) as net_sales_mln
from net_sales s
join dim_customer c
on s.customer_code = c.customer_code
where fiscal_year = 2021
group by market
order by net_sales_mln desc
limit 5;
# TOP CUSTOMER
select
customer,
round(sum((net_sales)/1000000),2) as net_sales_mln
from net_sales s
join dim_customer c
on s.customer_code = c.customer_code
where fiscal_year = 2021
group by customer
order by net_sales_mln desc
limit 5;
# TOP PRODUCT
select
product,
round(sum((net_sales)/1000000),2) as net_sales_mln
from net_sales s
join dim_product p
on s.product_code = p.product_code
where fiscal_year = 2021
group by product
order by net_sales_mln desc
limit 5;
-- Task #4: Create Stored Procedure to query top n market, customer and products by Net Sales in a given year
-- Task #5: Market share by Net Sales for all customers and create a stored procedure
with cte1 as(
select 
customer,
round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales s
join dim_customer c
on s.customer_code = c.customer_code
where fiscal_year=2021
group by customer
)
select *,
round(net_sales_mln*100/sum(net_sales_mln) over(),2) as net_sales_pct
from cte1
order by net_sales_mln desc;
-- Task #6: Market share by Net Sales for customers in each region and create a stored procedure specific regions
with cte1 as(
select 
customer, region,
round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales s
join dim_customer c
on s.customer_code = c.customer_code
where fiscal_year=2021
group by customer, region
)
select *,
net_sales_mln*100/sum(net_sales_mln) over(partition by region) as net_sales_pct
from cte1
order by region, net_sales_mln desc;
