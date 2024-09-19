
-----------------> ( 5. Perform cohort analysis (customer retention for month on month and retention for fixed month) ) <--------------------

/*
--> "Customers who started in each month and understand their behavior in the respective months 
     (Example: If 100 new customers started in Jan -2023, how is the 100 new customer behavior (in terms of purchases, revenue, etc..) in Feb-2023, Mar-2023, Apr-2023, etc...)
      Which Month cohort has maximum retention?"
*/

WITH customer_cohorts AS (
    -- Step 1: Find the first purchase month for each customer (cohort month)
    SELECT Customer_id, MIN(MONTH(Bill_date_timestamp) ) AS cohort_month
    FROM orders
    GROUP BY Customer_id
),

cohort_behavior AS (
    -- Step 2: Track purchases and revenue for each cohort in each subsequent month
    SELECT c.Customer_id, c.cohort_month, MONTH(bill_date_timestamp) AS order_month,
    COUNT(o.order_id) AS purchases, SUM(o.[Total Amount]) AS revenue
    FROM customer_cohorts as c JOIN orders as o 
	ON c.Customer_id = o.Customer_id
    GROUP BY c.Customer_id, c.cohort_month, MONTH(bill_date_timestamp)
),

cohort_size AS (
    -- Step 3: Calculate the total number of customers in each cohort
    SELECT cohort_month, COUNT(DISTINCT Customer_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
)

-- Step 4: Calculate cohort behavior and retention rate
SELECT cb.cohort_month, cb.order_month, COUNT(DISTINCT cb.Customer_id) AS active_customers,  
SUM(cb.purchases) AS total_purchases, SUM(cb.revenue) AS total_revenue, (COUNT(DISTINCT cb.Customer_id) / cs.cohort_size) * 100 AS retention_rate  
FROM cohort_behavior as cb JOIN cohort_size as cs 
ON cb.cohort_month = cs.cohort_month
GROUP BY cb.cohort_month, cb.order_month, cs.cohort_size
ORDER BY cb.cohort_month, cb.order_month

--------------------------------> ( 6. Perform analysis related to Sales Trends, patterns, and seasonality ) <--------------------------------------

/*
"Which months have had the highest sales, what is the sales amount and contribution in percentage?    

Which months have had the least sales, what is the sales amount and contribution in percentage?  

Sales trend by month   

Is there any seasonality in the sales (weekdays vs. weekends, months, days of week, weeks etc.)?

Total Sales by Week of the Day, Week, Month, Quarter, Weekdays vs. weekends etc."

*/


--> Which months have had the highest sales, what is the sales amount and contribution in percentage?

SELECT MONTH(Bill_date_timestamp) AS Months, SUM([Total Amount]) AS sales_amount, 
(SUM([Total Amount]) / (SELECT SUM([Total Amount]) FROM orders)) * 100 AS contribution_percentage
FROM orders
GROUP BY MONTH(Bill_date_timestamp)
ORDER BY Months , sales_amount DESC


--> Which months have had the least sales, what is the sales amount and contribution in percentage?  

WITH monthly_sales AS (
    SELECT MONTH(Bill_date_timestamp) as Months , SUM([Total Amount]) AS monthly_sales
    FROM orders
    GROUP BY MONTH(Bill_date_timestamp)
)
SELECT Months , monthly_sales,
(monthly_sales / (SELECT SUM([Total Amount]) FROM orders)) * 100 AS contribution_percentage
FROM monthly_sales
ORDER BY monthly_sales ASC


-->  Is there any seasonality in the sales (weekdays vs. weekends, months, days of week, weeks etc.)?

--> Sales by Weekdays vs. Weekends

SELECT 
    CASE 
        WHEN DatePart( weekday , Bill_date_timestamp) IN (1, 7) THEN 'Weekend' 
        ELSE 'Weekday' 
    END AS day_type,
    COUNT(order_id) AS total_orders, SUM([Total Amount]) AS total_sales
FROM orders
GROUP BY 
   CASE 
        WHEN DatePart( weekday , Bill_date_timestamp) IN (1, 7) THEN 'Weekend' 
        ELSE 'Weekday' 
    END

--> months, days of week

SELECT MONTH(Bill_date_timestamp) AS Months , DATENAME(weekday , Bill_date_timestamp) AS day_of_week,
COUNT(order_id) AS total_orders,
SUM([Total Amount]) AS total_sales
FROM orders
GROUP BY MONTH(Bill_date_timestamp), DATENAME(weekday , Bill_date_timestamp)
ORDER BY Months





select * from Customers
select * from OrderPayments
select * from Orders
select * from ProductsInfo
select * from OrderReview_Ratings
select * from [Stores Info]