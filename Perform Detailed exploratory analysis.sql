
---------------------------------> ( Perform Detailed exploratory analysis ) <----------------------------------------

-- 1. Finde the number of orders ?

select  count(order_id) as Order_count
from Orders

-- 2. Finde the total discount?

select sum(Discount) as Total_Discount
from Orders 

-- 3. Finde the average discount per coustomer ?

select Customer_id , AVG(Discount) as AVG_Discount
from Orders
group by Customer_id


-- 4. Finde the average discount per Order ?

select order_id , AVG(Discount) as AVG_Discount
from Orders
group by order_id


-- 3. Finde the average Order value or average bill value ?

select AVG(MRP) as Avg_Order_Value ,AVG([Total Amount]) as Avg_Bill_Value
from Orders

-- 4. Find the Average sales per customers ?

select Customer_id , AVG(payment_value) as Avg_Sales
from Orders as o
join OrderPayments as p
on o.order_id = p.order_id
group by Customer_id


-- 5. Find the Average profit per customers ?


WITH Customer_Profit AS (
    SELECT 
        Customer_id,
        SUM(payment_value - [Total Amount]) AS total_profit
    FROM 
        Orderpayments as op
    JOIN 
        Orders as o 
    ON 
        op.order_id = o.order_id  -- Assuming orderid is the common field
    GROUP BY 
        Customer_id
)
SELECT 
    AVG(total_profit) AS avg_profit_per_customer
FROM 
    Customer_Profit


-- 6. find the averege number of categories per order ?

--  number of categories per order

SELECT order_id, COUNT(DISTINCT product_id) AS category_count
FROM Orders
GROUP BY order_id

-- averege number of categories per order

SELECT AVG(category_count) AS average_categories_per_order
FROM (
    SELECT order_id, COUNT(DISTINCT product_id) AS category_count
    FROM Orders
    GROUP BY order_id
) AS category_counts


-- 7. find the  number of customer ?

select COUNT(Custid) as Customer_count
from Customers

-- 8. find the Transction per customer ?

select Customer_id , sum(payment_value) as [Transaction]
from Orders as o
join OrderPayments as op
on o.order_id = op.order_id
group by Customer_id


-- 9. find the total revenue ?

select sum([Total Amount]) as Total_Revenue
from Orders

-- 10. find the total Profit ?

select sum([Total Amount] - [Cost Per Unit]) as Total_Profit
from Orders

-- 10. find the total Cost ?

select sum([Cost Per Unit]) as Total_Cost
from Orders

-- 11. find the total Quantity ?

select sum(Quantity) as Total_Quantity
from Orders

-- 12. find the total Quantity ?

select sum(Quantity) as Total_Quantity
from Orders

-- 13. find the total Product ?

select count(Distinct product_id) as Total_product
from ProductsInfo

-- 14. find the total Category ?

select count( Distinct Category) as Total_category
from ProductsInfo

-- 15. find the total Store ?

select count( Distinct StoreID) as Total_store
from [Stores Info]

-- 16. find the total Location ?

select count( Distinct seller_city) as Total_location
from [Stores Info]


-- 17. find the total Region ?

select Region , count( Distinct Region) as Total_Region
from [Stores Info]
group by Region


-- 18. find the total Chanlas ?

select Channel , count( Distinct Channel) as Total_channels
from Orders
group by Channel

-- 18. find the total Payments Method ?

select payment_type , count( Distinct payment_type) as Payments_Method
from OrderPayments
group by payment_type	


-- 19. Average Number of Days Between Two Transactions (if the customer has more than one transaction) ?

select avg(days_between) as Avg_days
from (
  SELECT Customer_id, 
  DATEDIFF ( day, min ( Bill_date_timestamp),
  max (Bill_date_timestamp)) AS days_between
  FROM orders
  GROUP BY Customer_id
  HAVING COUNT(order_id) > 1
) as x

-- 20. find the Percentage of Profit ?

SELECT (SUM([Cost Per Unit]) / SUM([Total Amount])) * 100 AS profit_percentage
FROM orders


-- 21. Understanding how many new customers acquired every month (who made transaction first time in the data)

WITH FirstOrder AS (
    SELECT 
        customer_id, 
        MIN(Bill_date_timestamp) AS FirstTransactionDate
    FROM Orders
    GROUP BY customer_id
)
SELECT 
    MONTH(FirstTransactionDate) AS Month,
    COUNT(DISTINCT customer_id) AS NewCustomers
FROM FirstOrder
GROUP BY MONTH(FirstTransactionDate)
order by MONTH


-- 22. How the revenues from existing/new customers on monthly basis

WITH New_Customer_Revenue AS (
    SELECT 
        CONVERT(VARCHAR(7), Bill_date_timestamp, 120) AS order_month,  -- Convert to 'YYYY-MM' format
        SUM([Total Amount]) AS new_customer_revenue
    FROM orders AS o
    WHERE Bill_date_timestamp = (
        SELECT MIN(Bill_date_timestamp) 
        FROM orders 
        WHERE Customer_id = o.Customer_id
    )
    GROUP BY CONVERT(VARCHAR(7), Bill_date_timestamp, 120)
),
Existing_Customer_Revenue AS (
    SELECT 
        CONVERT(VARCHAR(7), Bill_date_timestamp, 120) AS order_month,  -- Convert to 'YYYY-MM' format
        SUM([Total Amount]) AS existing_customer_revenue
    FROM orders AS o
    WHERE Bill_date_timestamp > (
        SELECT MIN(Bill_date_timestamp) 
        FROM orders 
        WHERE Customer_id = o.Customer_id
    )
    GROUP BY CONVERT(VARCHAR(7), Bill_date_timestamp, 120)
)

SELECT 
    COALESCE(ncr.order_month, ecr.order_month) AS order_month,
    COALESCE(new_customer_revenue, 0) AS new_customer_revenue,
    COALESCE(existing_customer_revenue, 0) AS existing_customer_revenue
FROM New_Customer_Revenue AS ncr
FULL OUTER JOIN Existing_Customer_Revenue AS ecr
ON ncr.order_month = ecr.order_month
ORDER BY order_month;


-- 23. Understand the trends/seasonality of sales, quantity by category, region, store, channel, payment method.

-- 1. Trends of Sales (Revenue) Over Time

SELECT CONVERT(VARCHAR(7), Bill_date_timestamp, 105) AS Months, category,SUM([Total Amount]) AS monthly_sales
FROM orders as o 
JOIN ProductsInfo as p ON o.product_id = p.product_id
GROUP BY CONVERT(VARCHAR(7), Bill_date_timestamp, 105), category
ORDER BY Months ASC

-- 2. Quantity by Category Over Time (Monthly):

SELECT CONVERT(VARCHAR(7), Bill_date_timestamp, 105) AS month, category, SUM(quantity) AS monthly_quantity
FROM ProductsInfo as p
JOIN Orders as o ON p.product_id = o.product_id
GROUP BY CONVERT(VARCHAR(7), Bill_date_timestamp, 105) , category
ORDER BY month ASC

-- Sales by Week and Region:

SELECT CONCAT(DATEPART(YEAR, Bill_date_timestamp), '-', RIGHT('0' + CAST(DATEPART(WEEK, Bill_date_timestamp) AS VARCHAR(2)), 2)) AS week, region, 
SUM([Total Amount]) AS weekly_sales
FROM orders AS o
JOIN [Stores Info] AS s ON o.Delivered_StoreID = s.storeid
GROUP BY 
    DATEPART(YEAR, Bill_date_timestamp), 
    DATEPART(WEEK, Bill_date_timestamp), region
ORDER BY week

--  Quantity by Store and Channel (Months):

SELECT CONCAT(DATEPART(YEAR, Bill_date_timestamp), '-', RIGHT('0' + CAST(DATEPART(MONTH, Bill_date_timestamp) AS VARCHAR(2)), 2)) AS Months, 
Delivered_StoreID, channel, SUM(quantity) AS Monthly_quantity
FROM Orders
GROUP BY CONCAT(DATEPART(YEAR, Bill_date_timestamp), '-', RIGHT('0' + CAST(DATEPART(MONTH, Bill_date_timestamp) AS VARCHAR(2)), 2)),
Delivered_StoreID , channel
ORDER BY Months 

-- Sales by Payment Method and Month:

SELECT CONCAT(DATEPART(YEAR, Bill_date_timestamp), '-', RIGHT('0' + CAST(DATEPART(MONTH, Bill_date_timestamp) AS VARCHAR(2)), 2)) AS month, 
payment_type, SUM([Total Amount]) AS monthly_sales
FROM  orders as o join OrderPayments as p 
on o.order_id = p.order_id
GROUP BY CONCAT(DATEPART(YEAR, Bill_date_timestamp), '-', RIGHT('0' + CAST(DATEPART(MONTH, Bill_date_timestamp) AS VARCHAR(2)), 2)) , payment_type
ORDER BY month


-- 24. List the top 10 most expensive products sorted by price and their contribution to sales

SELECT TOP 10 p.product_id, COALESCE(p.Category, 'Unknown') AS Category,  -- Replace NULL values in Category with 'Unknown'
SUM(o.quantity * o.[Total Amount]) AS total_sales,
(SUM(o.quantity * o.[Total Amount]) / (SELECT SUM(o2.quantity * o2.[Total Amount]) FROM Orders AS o2)) * 100 AS sales_contribution_percentage
FROM ProductsInfo AS p
JOIN Orders AS o ON p.product_id = o.product_id
GROUP BY  p.product_id, COALESCE(p.Category, 'Unknown') 
ORDER BY total_sales DESC


-- 25. Top 10-performing & worst 10 performance stores in terms of sales

-- Top 10 Performing Stores by Sales

SELECT top 10 Delivered_StoreID, SUM([Total Amount]) AS total_sales
FROM orders
GROUP BY Delivered_StoreID
ORDER BY total_sales DESC

-- Worst 10 Performing Stores by Sales

SELECT top 10 Delivered_StoreID, SUM([Total Amount]) AS total_sales
FROM orders
GROUP BY Delivered_StoreID
ORDER BY total_sales Asc


select * from Customers
select * from OrderReview_Ratings
select * from OrderPayments
select * from Orders
select * from ProductsInfo
select * from [Stores Info]


