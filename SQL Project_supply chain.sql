-- Task #1
-- Create a physical helper table combining sold & forecast quantity
CREATE TABLE fact_act_est
             (
                       SELECT    date,
                                 product_code,
                                 customer_code,
                                 sold_quantity,
                                 forecast_quantity
                       FROM      fact_sales_monthly s
                       LEFT JOIN fact_forecast_monthly f
                       USING     (date, product_code, customer_code)
                       UNION
                       SELECT     date,
                                  product_code,
                                  customer_code,
                                  sold_quantity,
                                  forecast_quantity
                       FROM       fact_sales_monthly s
                       RIGHT JOIN fact_forecast_monthly f
                       USING      (date, product_code, customer_code)
             );

-- Task #2
-- update table to replace NA quantities with 0
UPDATE fact_act_est
SET    forecast_quantity = 0
WHERE  forecast_quantity IS NULL;
UPDATE fact_act_est
SET    sold_quantity = 0
WHERE  sold_quantity IS NULL;

-- Task #3
-- Create trigger to auto update the newly created tableSHOW triggers;
-- Task #4
-- insert new record into original fact tables and make sure the new helper table is updated automatically
INSERT INTO fact_sales_monthly
            (
                        date,
                        product_code,
                        customer_code,
                        sold_quantity
            )
            VALUES
            (
                        "2030-09-01",
                        "haha",
                        99,
                        98
            );
SELECT *
FROM   fact_act_est
WHERE  product_code= "haha";
INSERT INTO fact_forecast_monthly
            (
                        date,
                        product_code,
                        customer_code,
                        forecast_quantity
            )
            VALUES
            (
                        "2030-09-01",
                        "haha",
                        99,
                        43
            );
SELECT *
FROM   fact_forecast_monthly
WHERE  product_code= "haha";

-- Task #5
-- Generate forecast accuracy data table using CTE approach
WITH cte1
AS
  (
           SELECT   customer_code,
                    sum(sold_quantity)                                                              AS total_sold_qty,
                    sum(forecast_quantity)                                                          AS total_forcast_qty,
                    sum((forecast_quantity - sold_quantity))                                        AS net_err,
                    round(sum((forecast_quantity - sold_quantity))*100/sum(forecast_quantity),2)    AS net_err_per, -- use sum separately for numerator and denominator
                    sum(abs(forecast_quantity - sold_quantity))                                     AS abs_err,
                    round(sum(abs(forecast_quantity - sold_quantity))*100/sum(forecast_quantity),2) AS abs_err_per
           FROM     fact_act_est
           WHERE    fiscal_year = 2021
           GROUP BY customer_code )
  SELECT   customer_code,
           customer AS customer_name,
           market,
           total_sold_qty,
           total_forcast_qty,
           net_err,
           net_err_per,
           abs_err,
           abs_err_per,
           IF (abs_err_per > 100, 0, 100-abs_err_per) AS forecast_accuracy
  FROM     cte1
  JOIN     dim_customer
  USING    (customer_code)
  ORDER BY forecast_accuracy ;
  
  -- Task #5
  -- Generate forecast accuracy data table using a temorary table (valid for the whole session)
  CREATE temporary TABLE  forecast_err_table
  SELECT   customer_code,
           Sum(sold_quantity)                                                              AS total_sold_qty,
           Sum(forecast_quantity)                                                          AS total_forcast_qty,
           Sum((forecast_quantity - sold_quantity))                                        AS net_err,
           Round(Sum((forecast_quantity - sold_quantity))*100/Sum(forecast_quantity),2)    AS net_err_per, -- use sum separately for numerator and denominator
           Sum(Abs(forecast_quantity - sold_quantity))                                     AS abs_err,
           Round(Sum(Abs(forecast_quantity - sold_quantity))*100/Sum(forecast_quantity),2) AS abs_err_per
  FROM     fact_act_est
  WHERE    fiscal_year = 2021
  GROUP BY customer_code;
  
  -- Task #6
  -- a. Prodide data to understand which customers’ forecast accuracy has dropped from 2020 to 2021.
  -- b. Generate a complete report with these columns: customer_code, customer_name, market, forecast_accuracy_2020, forecast_accuracy_2021
WITH cte2021
AS
  (WITH cte1
AS
  (
           SELECT   customer_code,
                    sum(abs(forecast_quantity - sold_quantity))                                     AS abs_err,
                    round(sum(abs(forecast_quantity - sold_quantity))*100/sum(forecast_quantity),2) AS abs_err_per
           FROM     fact_act_est
           WHERE    fiscal_year = 2021
           GROUP BY customer_code )
  SELECT customer_code,
         customer AS customer_name,
         market,
         IF (abs_err_per > 100, 0, 100-abs_err_per) AS forecast_accuracy_2021
  FROM   cte1
  JOIN   dim_customer
  USING  (customer_code)
  ),
  cte2020
AS
  (WITH cte1
AS
  (
           SELECT   customer_code,
                    sum(abs(forecast_quantity - sold_quantity))                                     AS abs_err,
                    round(sum(abs(forecast_quantity - sold_quantity))*100/sum(forecast_quantity),2) AS abs_err_per
           FROM     fact_act_est
           WHERE    fiscal_year = 2020
           GROUP BY customer_code )
  SELECT customer_code,
         customer AS customer_name,
         market,
         IF (abs_err_per > 100, 0, 100-abs_err_per) AS forecast_accuracy_2020
  FROM   cte1
  JOIN   dim_customer
  USING  (customer_code)
  )
  SELECT   cte2021.*,
           cte2020.forecast_accuracy_2020,
           forecast_accuracy_2021-forecast_accuracy_2020 AS forecast_accuracy_change
  FROM     cte2021
  JOIN     cte2020
  USING    (customer_code)
  WHERE    forecast_accuracy_2021<forecast_accuracy_2020
  AND      forecast_accuracy_2021>0
  ORDER BY forecast_accuracy_change;
  
  -- Task #7: Provide user access to the databaseSHOW grants FOR 'wonda';
  -- Task #8: Improve SQL query performance by adding useful indexesshow indexes IN fact_act_est;explain ANALYZE
  SELECT *
  FROM   fact_act_est
  WHERE  fiscal_year = 2020
  LIMIT  1000000
