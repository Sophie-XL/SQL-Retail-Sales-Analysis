-- Task #1
-- Calculate Net Sales: Net Sales = Gross Sales - Pre-invoice discount - Post-invoice discount
SELECT   s.date,
         Get_fiscal_year(s.date) AS fiscal_year,
         s.product_code,
         s.customer_code,
         gp.gross_price,
         s.sold_quantity,
         Round((gp.gross_price*s.sold_quantity), 2) AS gross_sales,
         pre_invoice_discount_pct,
         gp.gross_price*s.sold_quantity*(1-pre_invoice_discount_pct)                                                AS net_invoice_sales,
         (pod.discounts_pct + pod.other_deductions_pct)                                                             AS post_invoice_discount_pct,
         gp.gross_price*s.sold_quantity*(1-pre_invoice_discount_pct)*(1-pod.discounts_pct-pod.other_deductions_pct) AS net_sales
FROM     fact_sales_monthly s
JOIN     fact_gross_price gp
ON       (
                  s.product_code = gp.product_code
         AND      Get_fiscal_year(s.date) = gp.fiscal_year)
JOIN     fact_pre_invoice_deductions ped
ON       (
                  s.customer_code = ped.customer_code
         AND      Get_fiscal_year(s.date) = ped.fiscal_year)
JOIN     fact_post_invoice_deductions pod
ON       s.customer_code = pod.customer_code
AND      s.product_code = pod.product_code
AND      s.date = pod.date
ORDER BY s.customer_code;

-- Task #2
-- Use Explain Analyze to understand the performance of the queryexplain ANALYZE
SELECT s.date,
       s.fiscal_year,
       s.product_code,
       s.customer_code,
       c.customer,
       c.market,
       gp.gross_price,
       s.sold_quantity,
       round((gp.gross_price*s.sold_quantity), 2) AS gross_price_total,
       pre_invoice_discount_pct,
       pod.discounts_pct,
       pod.other_deductions_pct,
       (gp.gross_price*s.sold_quantity*(1-pre_invoice_discount_pct)*(1-pod.discounts_pct-pod.other_deductions_pct)) AS net_sales
FROM   fact_sales_monthly s
JOIN   dim_customer c
ON     s.customer_code = c.customer_code
JOIN   fact_gross_price gp
ON     (
              s.product_code = gp.product_code
       AND    s.fiscal_year = gp.fiscal_year)
JOIN   fact_pre_invoice_deductions ped
ON     (
              s.customer_code = ped.customer_code
       AND    s.fiscal_year = ped.fiscal_year)
JOIN   fact_post_invoice_deductions pod
ON     s.customer_code = pod.customer_code
AND    s.product_code = pod.product_code
AND    s.date = pod.date;

-- Task #2: Create a database View for Net Sales tableCREATE
  algorithm = undefined
  definer = `root`@`localhost`
  SQL security definer
  view `net_sales`
AS
  SELECT   `s`.`date`                                                                                                                                             AS `date`,
           get_fiscal_year(`s`.`date`)                                                                                                                            AS `fiscal_year`,
           `s`.`product_code`                                                                                                                                     AS `product_code`,
           `s`.`customer_code`                                                                                                                                    AS `customer_code`,
           `gp`.`gross_price`                                                                                                                                     AS `gross_price`,
           `s`.`sold_quantity`                                                                                                                                    AS `sold_quantity`,
           round((`gp`.`gross_price` * `s`.`sold_quantity`), 2)                                                                                                   AS `gross_sales`,
           `ped`.`pre_invoice_discount_pct`                                                                                                                       AS `pre_invoice_discount_pct`,
           ((`gp`.`gross_price` * `s`.`sold_quantity`) * (1 - `ped`.`pre_invoice_discount_pct`))                                                                  AS `net_invoice_sales`,
           (`pod`.`discounts_pct` + `pod`.`other_deductions_pct`)                                                                                                 AS `post_invoice_discount_pct`,
           (((`gp`.`gross_price` * `s`.`sold_quantity`) * (1 - `ped`.`pre_invoice_discount_pct`)) * ((1 - `pod`.`discounts_pct`) - `pod`.`other_deductions_pct`)) AS `net_sales`
  FROM     (((`fact_sales_monthly` `s`
  JOIN     `fact_gross_price` `gp`
  ON       (((
                                      `s`.`product_code` = `gp`.`product_code`)
                    AND      (
                                      get_fiscal_year(`s`.`date`) = `gp`.`fiscal_year`))))
  JOIN     `fact_pre_invoice_deductions` `ped`
  ON       (((
                                      `s`.`customer_code` = `ped`.`customer_code`)
                    AND      (
                                      get_fiscal_year(`s`.`date`) = `ped`.`fiscal_year`))))
  JOIN     `fact_post_invoice_deductions` `pod`
  ON       (((
                                      `s`.`customer_code` = `pod`.`customer_code`)
                    AND      (
                                      `s`.`product_code` = `pod`.`product_code`)
                    AND      (
                                      `s`.`date` = `pod`.`date`))))
  ORDER BY `s`.`customer_code`
-- Task #3: Identify top market, top customer and top product by Net Sales with database view
# TOP MARKET
  SELECT   market,
           round(sum((net_sales)/1000000),2) AS net_sales_mln
  FROM     net_sales s
  JOIN     dim_customer c
  ON       s.customer_code = c.customer_code
  WHERE    fiscal_year = 2021
  GROUP BY market
  ORDER BY net_sales_mln DESC
  LIMIT    5;
  
  # TOP CUSTOMER
  SELECT   customer,
           Round(Sum((net_sales)/1000000),2) AS net_sales_mln
  FROM     net_sales s
  JOIN     dim_customer c
  ON       s.customer_code = c.customer_code
  WHERE    fiscal_year = 2021
  GROUP BY customer
  ORDER BY net_sales_mln DESC
  LIMIT    5;
  
  # TOP PRODUCT
  SELECT   product,
           Round(Sum((net_sales)/1000000),2) AS net_sales_mln
  FROM     net_sales s
  JOIN     dim_product p
  ON       s.product_code = p.product_code
  WHERE    fiscal_year = 2021
  GROUP BY product
  ORDER BY net_sales_mln DESC
  LIMIT    5;
  
  -- Task #4: Create Stored Procedure to query top n market, customer and products by Net Sales in a given year
  -- top market stored procedure
  CREATE definer=`root`@`localhost`
  PROCEDURE `get_top_market_by_net_sales`(
                                          in_fiscal_year INT,
                                          in_top_n       SMALLINT
                                          )
  begin
    SELECT   market,
             round(sum((net_sales)/1000000),2) AS net_sales_mln
    FROM     net_sales s
    JOIN     dim_customer c
    ON       s.customer_code = c.customer_code
    WHERE    fiscal_year = in_fiscal_year
    GROUP BY market
    ORDER BY net_sales_mln DESC
    LIMIT    in_top_n;
  END
    -- top customer stored procedure
  CREATE definer=`root`@`localhost`
  PROCEDURE `get_top_customer_by_net_sales`(
                                            in_fiscal_year INT,
                                            in_top_n       SMALLINT
                                            )
  begin
    SELECT   customer,
             round(sum((net_sales)/1000000),2) AS net_sales_mln
    FROM     net_sales s
    JOIN     dim_customer c
    ON       s.customer_code = c.customer_code
    WHERE    fiscal_year = in_fiscal_year
    GROUP BY customer
    ORDER BY net_sales_mln DESC
    LIMIT    in_top_n;
  END
 -- top product stored procedure
  CREATE definer=`root`@`localhost`
  PROCEDURE `get_top_product_by_net_sales`( in_fiscal_year INT,
                                           in_top_n        SMALLINT
                                           )
  begin
    SELECT   product,
             round(sum((net_sales)/1000000),2) AS net_sales_mln
    FROM     net_sales s
    JOIN     dim_product p
    ON       s.product_code = p.product_code
    WHERE    fiscal_year = in_fiscal_year
    GROUP BY product
    ORDER BY net_sales_mln DESC
    LIMIT    in_top_n;
END
  -- Task #5: Market share by Net Sales for all customers and create a stored procedure
  WITH cte1
AS
  (
           SELECT   customer,
                    round(sum(net_sales)/1000000,2) AS net_sales_mln
           FROM     net_sales s
           JOIN     dim_customer c
           ON       s.customer_code = c.customer_code
           WHERE    fiscal_year=2021
           GROUP BY customer )
  SELECT   *,
           round(net_sales_mln*100/sum(net_sales_mln) over(),2) AS net_sales_pct
  FROM     cte1
  ORDER BY net_sales_mln DESC;
  
  -- Stored Procedure
  CREATE definer=`root`@`localhost`
  PROCEDURE `get_market_share`(
                               in_fiscal_year INT
                               )
  begin
    WITH cte1
  AS
    (
             SELECT   customer,
                      round(sum(net_sales)/1000000,2) AS net_sales_mln
             FROM     net_sales s
             JOIN     dim_customer c
             ON       s.customer_code = c.customer_code
             WHERE    fiscal_year=in_fiscal_year
             GROUP BY customer )
    SELECT   *,
             round(net_sales_mln*100/sum(net_sales_mln) over(),2) AS net_sales_pct
    FROM     cte1
    ORDER BY net_sales_mln DESC;
    END
  -- Task #6: Market share by Net Sales for customers in each region and create a stored procedure specific regions
  WITH cte1
AS
  (
           SELECT   customer,
                    region,
                    round(sum(net_sales)/1000000,2) AS net_sales_mln
           FROM     net_sales s
           JOIN     dim_customer c
           ON       s.customer_code = c.customer_code
           WHERE    fiscal_year=2021
           GROUP BY customer,
                    region )
  SELECT                *,
           net_sales_mln*100/sum(net_sales_mln) over(partition BY region) AS net_sales_pct
  FROM     cte1
  ORDER BY region,
           net_sales_mln DESC;
  
  -- Stored Procedure
  CREATE definer=`root`@`localhost`
  PROCEDURE `get_market_share_each_region`(
                                           in_fiscal_year INT,
                                           in_region      VARCHAR(45)
                                           )
  begin
    WITH cte1
  AS
    (
             SELECT   customer,
                      region,
                      round(sum(net_sales)/1000000,2) AS net_sales_mln
             FROM     net_sales s
             JOIN     dim_customer c
             ON       s.customer_code = c.customer_code
             WHERE    fiscal_year=in_fiscal_year
             AND      region = in_region
             GROUP BY customer,
                      region )
    SELECT   *,
             round(net_sales_mln*100/sum(net_sales_mln) over(partition BY region),2) AS net_sales_pct
    FROM     cte1
    ORDER BY region,
             net_sales_mln DESC;
  END
