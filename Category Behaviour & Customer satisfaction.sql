
-----------------------------------------> ( 3. Category Behaviour ) <-----------------------------------------

--> 1. Total Sales & Percentage of sales by category (Perform Pareto Analysis)

WITH category_sales AS (
    SELECT category, SUM([Total Amount]) AS total_sales, 
    (SUM([Total Amount]) / (SELECT SUM([Total Amount]) FROM orders)) * 100 AS percentage_of_sales
    FROM orders as o JOIN ProductsInfo as p 
	ON o.product_id = p.product_id
    GROUP BY category
),
cumulative_sales AS (
    SELECT category, total_sales, percentage_of_sales, 
    SUM(percentage_of_sales) OVER (ORDER BY total_sales DESC) AS cumulative_percentage
    FROM category_sales
)
SELECT * FROM cumulative_sales

--> 2. Most profitable category and its contribution

-- Calculate profit for each category
WITH category_profit AS (
    SELECT category, SUM([Total Amount] - [Cost Per Unit]) AS total_profit
    FROM orders as o
    JOIN ProductsInfo as p ON o.product_id = p.product_id
    GROUP BY category
)

-- Find the most profitable category
SELECT category, total_profit, (total_profit / (SELECT SUM([Total Amount] - [Cost Per Unit]) FROM orders)) * 100 AS contribution_percentage
FROM category_profit


--> 3. Category Penetration Analysis by month on month (Category Penetration = number of orders containing the category/number of orders)

-- Count the number of unique orders that contain each category, grouped by month

WITH OrdersByCategory AS (
    SELECT 
        MONTH(Bill_date_timestamp) AS order_month, 
        Category,
        COUNT(DISTINCT o.order_id) AS category_order_count
    FROM orders AS o
    JOIN ProductsInfo AS p 
        ON o.product_id = p.product_id
    GROUP BY MONTH(Bill_date_timestamp), Category
),

-- Count the total number of orders for each month
TotalOrdersByMonth AS (
    SELECT 
        MONTH(Bill_date_timestamp) AS order_month,  
        COUNT(DISTINCT o.order_id) AS total_order_count
    FROM orders AS o
    GROUP BY MONTH(Bill_date_timestamp)
)

-- Final query to calculate category penetration by month
SELECT 
    obc.order_month,  
    obc.Category,  -- Replace 'category_id' with the actual 'Category' column
    (CAST(obc.category_order_count AS FLOAT) / tob.total_order_count) * 100 AS category_penetration_percentage
FROM OrdersByCategory AS obc 
JOIN TotalOrdersByMonth AS tob 
    ON obc.order_month = tob.order_month
ORDER BY obc.order_month, obc.Category

--> 4. Cross Category Analysis by month on Month (In Every Bill, how many categories shopped. Need to calculate average number of categories shopped in each bill by Region, By State etc)

--> 1. Calculate the number of unique categories in each order

WITH category_count_per_order AS (
    SELECT DISTINCT order_id  , COUNT(DISTINCT p.category) AS unique_categories
    FROM Orders as o
    JOIN ProductsInfo as p 
	ON o.product_id = p.product_id
    GROUP BY order_id
)
select * from category_count_per_order

-- 2. Join the category_count_per_order with the orders table for date, region, and state details

WITH category_count_per_order AS (
   SELECT DISTINCT order_id  , COUNT(DISTINCT p.category) AS unique_categories
    FROM Orders as o
    JOIN ProductsInfo as p 
	ON o.product_id = p.product_id
    GROUP BY order_id
)

SELECT Region, seller_state,
       CONVERT(VARCHAR(7), Bill_date_timestamp, 120) AS order_month, -- Convert order date to "YYYY-MM" format
       AVG(unique_categories) AS avg_categories_per_order
FROM category_count_per_order as c JOIN orders as o ON c.order_id = o.order_id
JOIN [Stores Info] as s ON o.Delivered_StoreID = s.StoreID  -- Assuming the regions table has a relation with orders
GROUP BY Region, seller_state , CONVERT(VARCHAR(7), Bill_date_timestamp, 120)
ORDER BY Region, seller_state , order_month

--> 5. Most popular category during first purchase of customer

WITH FirstPurchase AS (
-- Get the first purchase date for each customer

    SELECT o.Customer_id, MIN(o.Bill_date_timestamp) AS first_orderdate
    FROM orders AS o
    GROUP BY o.Customer_id
),
FirstOrderCategory AS (
-- Join the first purchase with orders to get the first order details

    SELECT o.Customer_id, o.order_id, o.Bill_date_timestamp, o.product_id, p.category
    FROM orders AS o 
    JOIN ProductsInfo AS p ON o.product_id = p.product_id
    JOIN FirstPurchase AS fp ON o.Customer_id = fp.Customer_id 
        AND o.Bill_date_timestamp = fp.first_orderdate
)
-- Count the number of times each category appears in first purchases

SELECT p.category, COUNT(*) AS first_purchase_count
FROM FirstOrderCategory AS p
GROUP BY p.category
ORDER BY first_purchase_count DESC


------------------------------------> ( 4. Customer satisfaction towards category & product ) <--------------------------------------

--> 1. Which categories (top 10) are maximum rated & minimum rated and average rating score?   

--> Top 10 [ Minimum , Maximum , Average ] Rated Categories

SELECT top 10 category, max(Customer_Satisfaction_Score) AS max_rating , min(Customer_Satisfaction_Score) AS min_rating,
AVG(Customer_Satisfaction_Score) AS AVG_rating
FROM OrderReview_Ratings as x JOIN Orders as o 
ON x.order_id = o.order_id
join ProductsInfo as p on o.product_id = p.product_id
GROUP BY category
ORDER BY max_rating DESC


--> 2. Average rating by location, store, product, category, month, etc.

--> Average Rating by Location

SELECT Seller_city, AVG(Customer_Satisfaction_Score) AS average_rating
FROM OrderReview_Ratings as od join Orders as o 
on od.order_id = o.order_id
join [Stores Info] as s on o.Delivered_StoreID = s.StoreID
GROUP BY Seller_city


--> Average Rating by Store

SELECT Storeid , AVG(Customer_Satisfaction_Score) AS average_rating
FROM OrderReview_Ratings as od join Orders as o 
on od.order_id = o.order_id
join [Stores Info] as s on o.Delivered_StoreID = s.StoreID
GROUP BY Storeid

--> Average Rating by Product

SELECT Category , AVG(Customer_Satisfaction_Score) AS average_rating
FROM OrderReview_Ratings as od join Orders as o 
on od.order_id = o.order_id
join ProductsInfo as s on o.product_id = s.product_id
GROUP BY Category



--> Average Rating by Month

SELECT  MONTH(Bill_Date_timestamp) as Months , AVG(Customer_Satisfaction_Score) AS average_rating
FROM orders as o join OrderReview_Ratings as x
on o.order_id = x.order_id
GROUP BY MONTH(Bill_Date_timestamp)
order by Months


--> Average Rating by Store and Product

SELECT Category , Delivered_StoreID ,  AVG(Customer_Satisfaction_Score) AS average_rating
FROM OrderReview_Ratings as od join Orders as o 
on od.order_id = o.order_id
join ProductsInfo as s on o.product_id = s.product_id
GROUP BY Category , Delivered_StoreID


--> Average Rating by Category and Month

SELECT Category , MONTH(Bill_date_timestamp) as Months ,  AVG(Customer_Satisfaction_Score) AS average_rating
FROM OrderReview_Ratings as od join Orders as o 
on od.order_id = o.order_id
join ProductsInfo as s on o.product_id = s.product_id
GROUP BY Category , MONTH(Bill_date_timestamp)
order by Months





select * from Customers
select * from OrderPayments
select * from Orders
select * from ProductsInfo
select * from OrderReview_Ratings
select * from [Stores Info]

