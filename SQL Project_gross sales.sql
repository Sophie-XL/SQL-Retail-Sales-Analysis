-- Task #1:
# Query gross sales data FOR a specific customer IN one fiscal YEAR: IN the final TABLE the following information should be included
# MONTH|Product Name|Product Variant|Sold quantity|Gross Price Per Item|Gross Price Total
-- Step 1: Find customer information
SELECT *
FROM   dim_customer
WHERE  customer LIKE "%croma%";

-- Step 2: Find transactions specific to Croma
SELECT *
FROM   fact_sales_monthly
WHERE  customer_code = 90002002;

-- Step 3: Get trasaction data only for 2021: calendar year -> fiscal year
SELECT *,
       Year(Date_add(date, INTERVAL 4 month)) AS fiscal_year
FROM   fact_sales_monthly
WHERE  customer_code = 90002002
AND    Year(Date_add(date, INTERVAL 4 month)) = 2021;

-- User defined function for fiscal year
CREATE definer=`root`@`localhost` function `get_fiscal_year`
	(
	calendar_date date
	) 
	returns INT
    DETERMINISTIC
  begin
    DECLARE fiscal_year INT;
    SET fiscal_year = year(date_add(calendar_date, INTERVAL 4 month));
	RETURN fiscal_year;
END
  -- Use defined function to get fiscal year
  SELECT *,
         get_fiscal_year(date) AS fiscal_year
  FROM   fact_sales_monthly
  WHERE  customer_code = 90002002
  AND    get_fiscal_year(date) = 2021;
  
  -- Select data from a specific fiscal quarter
  SELECT   *,
           Get_fiscal_quarter(date) AS fiscal_quarter
  FROM     fact_sales_monthly
  WHERE    customer_code = 90002002
  AND      Get_fiscal_year(   date) = 2021
  AND      Get_fiscal_quarter(date) = "q4"
  ORDER BY date
  LIMIT    1000000;
  
  -- Add other columns to complete the request in task #1
  SELECT s.date,
         Get_fiscal_year(s.date) AS fiscal_year,
         s.product_code,
         s.customer_code,
         p.product,
         p.variant,
         s.sold_quantity,
         Round(gp.gross_price,2)                    AS grosss_price,
         Round((gp.gross_price*s.sold_quantity), 2) AS gross_price_total
  FROM   fact_sales_monthly s
  JOIN   dim_product p
  USING  (product_code)
  JOIN   fact_gross_price gp
  ON     (
                s.product_code = gp.product_code
         AND    Get_fiscal_year(s.date) = gp.fiscal_year)
  WHERE  customer_code = 90002002
  AND    Get_fiscal_year(date) = 2021
  LIMIT  1000000;
  
  -- Task #2: Total monthly sales for croma in 2021
  SELECT   s.date,
           Round(Sum((gp.gross_price*s.sold_quantity)), 2) AS gross_price_total
  FROM     fact_sales_monthly s
  JOIN     fact_gross_price gp
  ON       (
                    s.product_code = gp.product_code
           AND      Get_fiscal_year(s.date) = gp.fiscal_year)
  WHERE    customer_code = 90002002
  GROUP BY s.date
  ORDER BY s.date;
  
  -- Task #3: Generate a yearly report for Croma India where there are two columns
  # 1. Fiscal YEAR
  # 2. Total Gross Sales amount IN that YEAR FROM Croma
  SELECT   Get_fiscal_year(s.date)                         AS fiscal_year,
           Round(Sum((gp.gross_price*s.sold_quantity)), 2) AS gross_price_total
  FROM     fact_sales_monthly s
  JOIN     fact_gross_price gp
  ON       (
                    s.product_code = gp.product_code
           AND      Get_fiscal_year(s.date) = gp.fiscal_year)
  WHERE    customer_code = 90002002
  GROUP BY Get_fiscal_year(s.date)
  ORDER BY fiscal_year;
  
  -- Task #4: Market Badge >5 million total quantity
  SELECT   c.market,
           Sum(s.sold_quantity)            AS total_sold_quantity,
           Get_badge(Sum(s.sold_quantity)) AS badge
  FROM     fact_sales_monthly s
  JOIN     dim_customer c
  ON       s.customer_code = c.customer_code
  WHERE    c.market = "india"
  AND      Get_fiscal_year(s.date)=2021
  GROUP BY c. market;
  
  -- Task #5: Get top selling product in each division
  WITH cte2
AS
  (
  WITH cte1
AS
  (
           SELECT   division,
                    product,
                    sum(sold_quantity) AS total_quantity
           FROM     fact_sales_monthly s
           JOIN     dim_product
           USING    (product_code)
           WHERE    fiscal_year = 2021
           GROUP BY product,
                    division )
  SELECT   *,
           row_number() over(partition BY division ORDER BY total_quantity DESC) AS rn,
           rank() over(partition BY division ORDER BY total_quantity DESC)       AS rnk,
           dense_rank() over(partition BY division ORDER BY total_quantity DESC) AS drnk
  FROM     cte1
  ORDER BY division )
SELECT rnk,
       division,
       product,
       total_quantity
FROM   cte2
WHERE  rnk<=3;

-- Task #6: Retrieve the top 2 markets in every region by their gross sales amount in FY=2021
WITH cte2
AS
  (
  WITH cte1
AS
  (
           SELECT   market,
                    region,
                    round(sum(gross_price_total)/1000000,2) AS gross_sales_mln
           FROM     gross_sales
           WHERE    fiscal_year = 2021
           GROUP BY market,
                    region )
  SELECT   *,
           rank() over(partition BY region ORDER BY gross_sales_mln DESC) AS rnk
  FROM     cte1 )
SELECT *
FROM   cte2
WHERE  rnk <=2;
-- Task #7: Create stored procedures for
# a. gross sales FOR a specific customer IN a given YEAR AS IN task #1 
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_gross_sales_data`(
 in_fiscal_year INT, 
 in_customer_code VARCHAR(45) 
 ) 
BEGIN
SELECT s.date,
       get_fiscal_year(s.date) AS fiscal_year,
       s.product_code,
       s.customer_code,
       p.product,
       p.variant,
       s.sold_quantity,
       round(gp.gross_price,2)                    AS grosss_price,
       round((gp.gross_price*s.sold_quantity), 2) AS gross_price_total
FROM   fact_sales_monthly s
JOIN   dim_product p
USING  (product_code)
JOIN   fact_gross_price gp
ON     (
              s.product_code = gp.product_code
       AND    get_fiscal_year(s.date) = gp.fiscal_year)
WHERE  customer_code = in_customer_code
AND    get_fiscal_year(date) = in_fiscal_year
LIMIT  1000000;
END
# b. monthly gross sales data FOR selected customers
CREATE definer=`root`@`localhost` PROCEDURE `get_monthly_gross_sales_for_customer`
(
	in_customer_codes text
)
begin
  SELECT   s.date,
           round(sum((gp.gross_price*s.sold_quantity)), 2) AS monthly_sales
  FROM     fact_sales_monthly s
  JOIN     fact_gross_price gp
  ON       (
                    s.product_code = gp.product_code
           AND      get_fiscal_year(s.date) = gp.fiscal_year)
  WHERE    find_in_set(s.customer_code, in_customer_codes)>0
  GROUP BY s.date;
  END
# c. top n selling products BY gross sales IN EACH division IN a given YEAR
CREATE definer=`root`@`localhost` PROCEDURE `get_top_product_each_division`
(
in_fiscal_year INT,
in_top_n       INT
)
begin
  WITH cte2
AS
  (
  WITH cte1
AS
  (
           SELECT   division,
                    product,
                    sum(sold_quantity) AS total_quantity
           FROM     fact_sales_monthly s
           JOIN     dim_product
           USING    (product_code)
           WHERE    fiscal_year = 2021
           GROUP BY product,
                    division )
  SELECT   *,
           row_number() over(partition BY division ORDER BY total_quantity DESC) AS rn,
           rank() over(partition BY division ORDER BY total_quantity DESC)       AS rnk,
           dense_rank() over(partition BY division ORDER BY total_quantity DESC) AS drnk
  FROM     cte1
  ORDER BY division )
SELECT rnk,
       division,
       product,
       total_quantity
FROM   cte2
WHERE  rnk<= in_top_n;
END
# d. top n markets IN every region BY their gross sales amount IN a given YEAR
CREATE definer=`root`@`localhost` PROCEDURE `top_n_market_each_region_by_gross_sales`
(
	in_fiscal_year INT,
	in_top_n       SMALLINT
)
begin
  WITH cte2
AS
  (
  WITH cte1
AS
  (
           SELECT   market,
                    region,
                    round(sum(gross_price_total)/1000000,2) AS gross_sales_mln
           FROM     gross_sales
           WHERE    fiscal_year = in_fiscal_year
           GROUP BY market,
                    region )
  SELECT   *,
           rank() over(partition BY region ORDER BY gross_sales_mln DESC) AS rnk
  FROM     cte1 )
SELECT *
FROM   cte2
WHERE  rnk <=in_top_n;
END
