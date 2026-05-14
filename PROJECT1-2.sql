

/*====================================================================================================================
                                        Question "1"
📌 What is the ranking of each product in terms of total sales within its category?
======================================================================================================================*/
USE BikeStore
-----------
SELECT *FROM production.categories
SELECT *FROM production.products
SELECT*FROM sales.order_items
------------------------------------
SELECT 
C.category_id,
C.category_name ,
P.product_name,
SUM(OI.quantity * OI.list_price *(1-OI.discount)) AS TOTAL_SALES,
   RANK() OVER (
        PARTITION BY C.category_id
        ORDER BY SUM(OI.quantity * OI.list_price *(1-OI.discount)) DESC )
     AS product_rank
      
FROM production.categories AS C
 INNER JOIN production.products AS P
 ON C.category_id=P.category_id
 INNER JOIN sales.order_items AS OI
 ON P.product_id=OI.product_id
 GROUP BY 
 C.category_id,
 C.category_name ,
P.product_name
/*
📌 Why is it important?
    1- Decision to remove/support products
*/



/*====================================================================================================================
                                        Question "2"
📌 What is the Product Contribution % within Category?
======================================================================================================================*/
 

/*
📌 Why is it important?
    1- Shows which products are actually driving the category’s performance.
    2- Inventory Optimization.
*/
------------------------------------
SELECT *FROM sales.order_items
SELECT*FROM production.products
SELECT *FROM production.categories
---------------------------------

CREATE VIEW COUNTRIBUTION AS
SELECT 
C.category_name,
P.product_name,
SUM(OI.quantity *OI.list_price)AS PRODUCT_SALES,
SUM(SUM(OI.quantity *OI.list_price)) OVER ( PARTITION BY C.category_name) AS CATEGORY_SALES 
, ROUND(SUM(OI.quantity *OI.list_price) *100 /
SUM(SUM(OI.quantity *OI.list_price)) 
OVER ( PARTITION BY C.category_name) ,2) AS COUNTRIBUTION 
FROM sales.order_items AS OI
INNER JOIN production.products AS P
ON OI.product_id=P.product_id
INNER JOIN production.categories AS C
ON P.category_id=C.category_id
GROUP BY 
C.category_name,
P.product_name
---------------------------
SELECT *FROM COUNTRIBUTION
/*====================================================================================================================
                                        Question "3"
📌 Who is the top 1 Sales Rep each month?
======================================================================================================================*/


/*
📌 Why is it important?
    1- KPIs for employees
    2- Performance evaluation and rewards
*/
SELECT *
FROM (
    SELECT 
        S.staff_id,
        CONCAT( S.first_name,' ',S.last_name) AS FULL_NAME ,
        SUM(OI.quantity * OI.list_price * (1 - OI.discount)) AS total_sales,
                FORMAT(O.order_date, 'yyyy-MM') AS month_sales,
        ROW_NUMBER () OVER (

            PARTITION BY   
            FORMAT(O.order_date, 'yyyy-MM') 
            
            ORDER BY 
            SUM(OI.quantity * OI.list_price * (1 - OI.discount)) DESC) AS sales_rank

    FROM sales.orders AS O
    INNER JOIN sales.order_items AS OI
        ON O.order_id = OI.order_id
    INNER JOIN sales.staffs AS S
        ON O.staff_id = S.staff_id

    GROUP BY 
        S.staff_id,
        CONCAT( S.first_name,' ',S.last_name) ,
        FORMAT(O.order_date, 'yyyy-MM')
) AS ranked_sales

WHERE sales_rank = 1;



/*====================================================================================================================
                                        Question "4"
📌 Running Total Sales per Store?
======================================================================================================================*/


/*
📌 Why is it important?
    1- Track long-term growth per store
    2- Compare store performance
*/
SELECT  *FROM sales.order_items
SELECT *FROM sales.orders
SELECT *FROM sales.stores
---------------
CREATE PROCEDURE Store_Running_Total AS
BEGIN
SELECT 
S.store_id ,
S.store_name,
O.order_date,
SUM(OI.quantity * OI.list_price ) AS DAILY_SALES
, SUM(SUM(OI.quantity * OI.list_price )) OVER(PARTITION BY S.store_id 
ORDER BY O.order_date ASC ) AS RUNNING_TOTAL
FROM sales.order_items AS OI
INNER JOIN sales.orders AS O
ON OI.order_id=O.order_id
INNER JOIN sales.stores AS S
ON O.store_id=S.store_id
GROUP BY
S.store_id ,
S.store_name,
O.order_date
END

-----------------------------------
SELECT *FROM Store_Running_Total

/*====================================================================================================================
                                        Question "5"
📌 Have sales increased or decreased compared to the previous month?
======================================================================================================================*/
CREATE VIEW previous_month AS
WITH previous_month AS (
SELECT 
SUM(OI.discount * OI.list_price) AS TOTAL_SALES ,
FORMAT(O.order_date , 'yyyy-MM') AS SALES_MONTH
FROM sales.order_items AS OI
INNER JOIN sales.orders AS O
ON O.order_id= OI.order_id 
GROUP BY
FORMAT(O.order_date , 'yyyy-MM') 
)
SELECT 
TOTAL_SALES ,
SALES_MONTH ,
LAG(TOTAL_SALES) OVER (ORDER BY SALES_MONTH ) AS previous_month_SALES ,
TOTAL_SALES - LAG(TOTAL_SALES) OVER (ORDER BY SALES_MONTH ) AS previous_month_SALES_2
FROM previous_month;
---------------------
SELECT * FROM previous_month
/*
📌 Why is it important?
    1- Growth / Decline
    2- Business health check
*/


/*====================================================================================================================
                                        Question "6"
📌 Customer Ranking by Number of Orders
======================================================================================================================*/
SELECT *FROM sales.customers
SELECT *FROM sales.orders
----------------------------------
CREATE VIEW Customer_Ranking AS
WITH Customer_Ranking AS (
SELECT 
    C.customer_id,
    CONCAT(C.first_name,' ', C.last_name) AS CUSTOMER_NAME,
    COUNT(O.order_id) AS NO_OF_ORDER
FROM sales.customers AS C
LEFT JOIN sales.orders AS O
ON  C.customer_id = O.customer_id
GROUP BY 
    C.customer_id,
    CONCAT(C.first_name,' ', C.last_name)
    ) 
SELECT * FROM (
SELECT *,
    DENSE_RANK() OVER(ORDER BY NO_OF_ORDER DESC) AS RNK
FROM Customer_Ranking )  AS NEW
-----------
SELECT * FROM Customer_Ranking
/*====================================================================================================================
                                        Question "7"
📌 How can we segment customers into 4 performance groups based on total sales?
======================================================================================================================*/
IF OBJECT_ID('Customer_Sales_Segments', 'V') IS NOT NULL
    DROP VIEW Customer_Sales_Segments

CREATE VIEW Customer_Sales_Segments AS
WITH customer_sales AS (
    SELECT
        c.customer_id,
        c.first_name + ' ' + c.last_name AS customer_name,
        SUM(oi.quantity * oi.list_price) AS total_sales
    FROM sales.customers c
    JOIN sales.orders o ON c.customer_id = o.customer_id
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name
)
SELECT
    *,
    NTILE(4) OVER (ORDER BY total_sales DESC) AS customer_segment
FROM customer_sales

/*
📌 Why is it important?
    1- Identifies high-value customers
        → Helps you quickly spot top-spending customers to prioritize retention and rewards.
    2- Supports targeted strategies
        → Enables personalized marketing, pricing, and service based on customer value.
    3- Improves resource allocation
        → Focuses time and budget on segments that generate the most revenue.
*/

SELECT * FROM Customer_Sales_Segments
/*
📌 Why is it important?
    1- Identifies high-value customers
        → Helps you quickly spot top-spending customers to prioritize retention and rewards.
    2- Supports targeted strategies
        → Enables personalized marketing, pricing, and service based on customer value.
    3- Improves resource allocation
        → Focuses time and budget on segments that generate the most revenue.
*/

SELECT * FROM Customer_Sales_Segments
/*
📌 Why is it important?
    1- Identifies high-value customers
        → Helps you quickly spot top-spending customers to prioritize retention and rewards.
    2- Supports targeted strategies
        → Enables personalized marketing, pricing, and service based on customer value.
    3- Improves resource allocation
        → Focuses time and budget on segments that generate the most revenue.
*/


/*====================================================================================================================
                                        Question "8"
📌 How can we segment products into 4 performance groups based on total sales?
======================================================================================================================*/
CREATE VIEW PRODUCTS_SEG AS 
WITH PRODUCTS_SEG AS(
SELECT 
    P.product_id,
    P.product_name,
    SUM(OI.quantity*OI.list_price) AS TOTAL_SALES
FROM sales.order_items AS OI
INNER JOIN production.products AS P
ON OI.product_id = P.product_id
GROUP BY 
    P.product_id,
    P.product_name
)
SELECT*,
    CASE 
    WHEN PRODUCTS_SEG = 1 THEN 'A'
    WHEN PRODUCTS_SEG = 2 THEN 'B'
    WHEN PRODUCTS_SEG = 3 THEN 'C'
    WHEN PRODUCTS_SEG = 4 THEN 'D'
    END AS SEG
FROM (
SELECT 
    *,
    NTILE(4) OVER(ORDER BY TOTAL_SALES DESC ) AS PRODUCTS_SEG
FROM PRODUCTS_SEG ) AS NEW



/*
?? Why is it important?
    1- Product segmentation
    2- Focus marketing & promotions
    3- Decide which products to discontinue
*/
--------------------------------------------
SELECT * FROM PRODUCTS_SEG

/*
📌 Why is it important?
    1- Product segmentation
    2- Focus marketing & promotions
    3- Decide which products to discontinue
*/
--------------------------------------------

/*====================================================================================================================
                                        Question "9"
📌 What percentage of customers generate a given level of sales?
======================================================================================================================*/


/*
📌 Why is it important?
    1- 20% of customers generate 80% of revenue.
*/


