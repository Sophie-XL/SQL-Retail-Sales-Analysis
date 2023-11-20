# SQL-Retail-Sales-Analysis
Query gross and net sales and  sales forecast tables
## Project Background
Atliq is an online retailer for electronic products. Atliq has multiple sales channels including direct, distributor and retailer with physical stores and online presence. Atliq’s customers are in various countries across Asian Pacific, North America, South America and Europe. Atliq offers about 400 product SKUs in over 10 categories like mouse, processors, laptops, keyboard, etc. customized for personal and professional users. With over 1 million sales record in the period of 5 years, the business managers want to make strategic decisions based on the health of their global operation.
## Dataset
There are two dimension tables for customer and product details and 5 fact tables about actual sales quantity, product price and discount as well as forecasted sales quantities.
The sales quantity related tables and discount tables has the largest quantity data, varying from 1 to 2 million rows. Whereas other tables have data vary from about 200 to 2000 rows.
## Tasks: 
1. Gross Sales: [SQL Project_gross sales.sql](https://github.com/Sophie-XL/SQL-Retail-Sales-Analysis/blob/a4c72d2a6dd73e98071c72d35ab1109afa00a23c/SQL%20Project_gross%20sales.sql)

The business manager wanted a data table for a yearly sales report in which he needs the gross sales data (gross price * quantity sold) for a particular customer over a customized period of time. He also wants to classify the markets into “Gold” and “Silver” categories based on aggregated gross sales. With the aggregated gross sales data, it’s valuable to identify the top performing products and markets in a given period of time. For example, it is clear to see from the table below that in fiscal year 2021, India is the leading market in APAC whereas USA is the leading market in North America.

![gross sales rank](https://github.com/Sophie-XL/SQL-Retail-Sales-Analysis/assets/146779290/131fc959-7dee-4811-8643-3111495b92a2)


The data tables are built through MySQL. And the accompanied stored procedure provides a quick way for the business manager to customize data table based on the interested market, product or customer for a given period of time.
 
2. Market Share: [SQL Project_net sales.sql](https://github.com/Sophie-XL/SQL-Retail-Sales-Analysis/blob/a4c72d2a6dd73e98071c72d35ab1109afa00a23c/SQL%20Project_market%20share.sql)

In this task, the business focus shifts from gross sales to net sales, considering the discount given to the customers based on royalty and product. There are two kinds of discounts, pre-invoice discount offers to a certain customer on a fiscal year basis. While post-invoice discount is transaction based, meaning different discount rates applied to different customer for different product at a given date. Because of the complexity of discount, SQL database views are created by joining multiple tables so that the business analyst or manager can pull data when they needed. Again, more stored procedures are provided to enable interactive data table generation.
With net sales data available to be aggregated on customer, market or product level, it is handy for business owners to understand their top performing customers and products in terms of net sales and make apocopate business strategies. It is also possible to find market share of each customer either across the entire customer base or across a certain region. The data can be exported to CSV and visualized with the assistance of Excel [Market Share.xlsx](https://github.com/Sophie-XL/SQL-Retail-Sales-Analysis/blob/a4c72d2a6dd73e98071c72d35ab1109afa00a23c/Market%20Share.xlsx).

![regional market share](https://github.com/Sophie-XL/SQL-Retail-Sales-Analysis/assets/146779290/b6ce0c33-b188-4987-bdcb-a9c1d25d15b9)
 
2. Supply Chain: [SQL Project_supply chain.sql](https://github.com/Sophie-XL/SQL-Retail-Sales-Analysis/blob/a4c72d2a6dd73e98071c72d35ab1109afa00a23c/SQL%20Project_supply%20chain.sql)

The goal of this task is to find variance between forecasted sales quantity and the actual sold quantity. With the forecast accuracy data (forecast accuracy = 100% - absolute error%) in hand, the supply chain manager can slice and dice the data based on different criteria like customer, product or region. Thus they can understand, and more importantly improve, their ability to accurately forecast demand.
 
![sales forecast accuracy](https://github.com/Sophie-XL/SQL-Retail-Sales-Analysis/assets/146779290/7b835d24-df85-45c9-83d5-e980b2399e09)


## SQL Skills:
- [x]	SQL Basics (SELECT, WHERE, BETWEEN, GROUP BY, ORDER BY, etc.)
- [x]	Joins (LEFT, RIGHT, INNER, FULL, CROSS).
- [x]	Subqueries, CTEs, Views, Temporary Tables
- [x]	Fundamentals of ETL, Data Warehouse, OLAP, OLTP, Data Engineer-Specific Topis: Indexes, Triggers, Events, User Accounts & Privileges, Kanban Project Management
- [x]	Proficiency in User Defined Functions, Stored Procedures
- [x]	Window Functions (Over, ROW_NUMBER, RANK, DENSE_RANK, etc.)
