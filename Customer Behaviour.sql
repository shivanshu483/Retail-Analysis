
-----------------------------------------> ( 2. Customer Behaviour ) <-----------------------------------------

--> 1. Segment the customers (divide the customers into groups) based on the revenue

--> Calculate Total Revenue per Customer

SELECT customer_id, SUM([Total Amount]) AS total_revenue
FROM orders
GROUP BY Customer_id

--> Define Revenue Segments

SELECT customer_id, total_revenue,
       CASE 
           WHEN total_revenue > 5000 THEN 'High Revenue'
           WHEN total_revenue BETWEEN 2500 AND 3500 THEN 'Medium Revenue'
           ELSE 'Low Revenue'
       END AS revenue_segment
FROM (
    SELECT Customer_id, SUM([Total Amount]) AS total_revenue
    FROM orders
    GROUP BY Customer_id
) AS customer_revenue

/* --> 2. Divide the customers into groups based on Recency, Frequency, and Monetary (RFM Segmentation) -  
Divide the customers into Premium, Gold, Silver, Standard customers and understand the behaviour of each segment of customers */

--> Calculate Recency:

/* Recency is the number of days since the customer’s last purchase. 
We’ll calculate the number of days between the current date and the last purchase date for each customer.*/

SELECT Customer_id,DATEDIFF(day , getdate(), MAX(Bill_date_timestamp)) AS recency
FROM orders
GROUP BY Customer_id

--> Calculate Frequency:-> Frequency is the total number of orders placed by a customer.

SELECT Customer_id, COUNT(order_id) AS frequency
FROM orders
GROUP BY Customer_id

--> Calculate Monetary Value:-> Monetary value is the total amount spent by a customer.

SELECT Customer_id, SUM([Total Amount]) AS monetary
FROM orders
GROUP BY Customer_id

--> Combine RFM Metrics:-> Combine the recency, frequency, and monetary metrics into a single query.

SELECT 
    r.customer_id,
    r.recency,
    f.frequency,
    m.monetary
FROM 
    (SELECT Customer_id, DATEDIFF(day , getdate(), MAX(Bill_date_timestamp)) AS recency FROM orders GROUP BY Customer_id) r
JOIN 
    (SELECT Customer_id, COUNT(order_id) AS frequency FROM orders GROUP BY Customer_id) f ON r.Customer_id = f.Customer_id
JOIN 
    (SELECT Customer_id, SUM([Total Amount]) AS monetary FROM orders GROUP BY Customer_id) m ON r.Customer_id = m.Customer_id;


--> Score Customers on RFM

--> Recency Scoring

SELECT Customer_id,
    CASE 
        WHEN recency <= 30 THEN 5
        WHEN recency BETWEEN 31 AND 60 THEN 4
        WHEN recency BETWEEN 61 AND 90 THEN 3
        WHEN recency BETWEEN 91 AND 120 THEN 2
        ELSE 1 
    END AS recency_score
FROM (
    SELECT Customer_id, DATEDIFF(day , getdate(), MAX(Bill_date_timestamp)) AS recency
    FROM orders
    GROUP BY Customer_id
) AS recency_table

--> Frequency Scoring

SELECT customer_id,
    CASE 
        WHEN frequency >= 10 THEN 5
        WHEN frequency BETWEEN 6 AND 9 THEN 4
        WHEN frequency BETWEEN 3 AND 5 THEN 3
        WHEN frequency = 2 THEN 2
        ELSE 1
    END AS frequency_score
FROM (
    SELECT customer_id, COUNT(order_id) AS frequency
    FROM orders
    GROUP BY customer_id
) AS frequency_table

--> Monetary Scoring

SELECT 
    Customer_id,
    CASE 
        WHEN monetary >= 5000 THEN 5
        WHEN monetary BETWEEN 2500 AND 3500 THEN 4
        WHEN monetary BETWEEN 1000 AND 2400 THEN 3
        WHEN monetary BETWEEN 500 AND 999 THEN 2
        ELSE 1
    END AS monetary_score
FROM (
    SELECT Customer_id, SUM([Total Amount]) AS monetary
    FROM orders
    GROUP BY Customer_id
) AS monetary_table

--> Segment Customers (Premium, Gold, Silver, Standard):

WITH RecencyScore AS (
    SELECT customer_id, DATEDIFF(DAY, MAX(Bill_date_timestamp), GETDATE()) AS recency,
        CASE 
            WHEN DATEDIFF(DAY, MAX(Bill_date_timestamp), GETDATE()) <= 30 THEN 5
            WHEN DATEDIFF(DAY, MAX(Bill_date_timestamp), GETDATE()) BETWEEN 31 AND 60 THEN 4
            ELSE 1
        END AS recency_score
    FROM Orders
    GROUP BY customer_id
),
FrequencyScore AS (
    SELECT customer_id, COUNT(order_id) AS frequency,
        CASE 
            WHEN COUNT(order_id) >= 10 THEN 5
            ELSE 1
        END AS frequency_score
    FROM Orders
    GROUP BY customer_id
),
MonetaryScore AS (
    SELECT customer_id, SUM([Total Amount]) AS monetary,
        CASE 
            WHEN SUM([Total Amount]) >= 10000 THEN 5
            ELSE 1
        END AS monetary_score
    FROM Orders
    GROUP BY customer_id
)
SELECT r.customer_id, r.recency_score, f.frequency_score, m.monetary_score, (r.recency_score + f.frequency_score + m.monetary_score) AS rfm_score,
    CASE 
        WHEN (r.recency_score + f.frequency_score + m.monetary_score) BETWEEN 13 AND 15 THEN 'Premium'
        WHEN (r.recency_score + f.frequency_score + m.monetary_score) BETWEEN 10 AND 12 THEN 'Gold'
        WHEN (r.recency_score + f.frequency_score + m.monetary_score) BETWEEN 7 AND 9 THEN 'Silver'
        ELSE 'Standard'
    END AS customer_segment
FROM RecencyScore as r
JOIN FrequencyScore as f ON r.customer_id = f.customer_id
JOIN MonetaryScore as m ON r.customer_id = m.customer_id

--> 3. Find out the number of customers who purchased in all the channels and find the key metrics.

WITH TotalChannels AS (
    SELECT COUNT(DISTINCT channel) AS total_channels
    FROM orders
),
CustomerChannels AS (
    SELECT Customer_id
    FROM orders
    GROUP BY Customer_id
    HAVING COUNT(DISTINCT channel) = (SELECT total_channels FROM TotalChannels)
)
SELECT
    COUNT(DISTINCT o.channel) AS customers_in_all_channels,
    SUM(o.[Total Amount]) AS total_revenue,
    SUM(o.[Total Amount] - o.[Cost Per Unit]) AS total_profit,
    SUM(o.[Cost Per Unit]) AS total_cost,
    SUM(o.quantity) AS total_quantity
FROM orders AS o
JOIN ProductsInfo AS p ON o.product_id = p.product_id
WHERE o.Customer_id IN (SELECT Customer_id FROM CustomerChannels)

--> 4. Understand the behavior of one time buyers and repeat buyers

--> Segregate One-Time Buyers and Repeat Buyers
	
SELECT Customer_id,
  CASE
      WHEN COUNT(order_id) = 1 THEN 'One-Time Buyer'
      ELSE 'Repeat Buyer'
  END AS buyer_type FROM orders
GROUP BY Customer_id

--> Average Order Value

SELECT buyer_type, AVG(totalamount) AS avg_order_value
FROM (
    SELECT Customer_id, SUM([Total Amount]) AS totalamount,
           CASE
           WHEN COUNT(order_id) = 1 THEN 'One-Time Buyer'
           ELSE 'Repeat Buyer'
           END AS buyer_type FROM orders
    GROUP BY Customer_id
) AS customer_orders
GROUP BY buyer_type

--> Total Revenue Contribution

SELECT buyer_type, SUM(totalamount) AS total_revenue
FROM (
        SELECT Customer_id, SUM([Total Amount]) AS totalamount,
        CASE
        WHEN COUNT(order_id) = 1 THEN 'One-Time Buyer'
        ELSE 'Repeat Buyer'
        END AS buyer_type FROM orders
    GROUP BY Customer_id
) AS customer_orders
GROUP BY buyer_type

-->5. Understand the behavior of discount seekers & non discount seekers

--> Identifying Discount Seekers and Non-Discount Seekers:

WITH customer_behavior AS (
    SELECT Customer_id,  SUM([Total Amount]) AS total_spent, SUM(CASE WHEN discount > 0 THEN 1 ELSE 0 END) AS discount_purchase_count,
    COUNT(order_id) AS total_purchase_count
    FROM orders
    GROUP BY customer_id
)
SELECT Customer_id, total_spent, discount_purchase_count, total_purchase_count,
(CAST(discount_purchase_count AS FLOAT) / total_purchase_count) * 100 AS discount_purchase_percentage
FROM customer_behavior
ORDER BY discount_purchase_percentage DESC


--> Average Order Value Comparison:

WITH avg_order_value 
AS (
 SELECT Customer_id,
 SUM([Total Amount]) / COUNT(order_id) AS avg_order_value,
 SUM(CASE WHEN discount > 0 THEN [Total Amount] ELSE 0 END) / NULLIF(COUNT(CASE WHEN discount > 0 THEN order_id END), 0) AS avg_order_value_with_discount,
 SUM(CASE WHEN discount = 0 THEN [Total Amount] ELSE 0 END) / NULLIF(COUNT(CASE WHEN discount = 0 THEN order_id END), 0) AS avg_order_value_without_discount
 FROM orders
 GROUP BY Customer_id
 )
SELECT 
AVG(avg_order_value_with_discount) AS avg_discount_order_value,
AVG(avg_order_value_without_discount) AS avg_non_discount_order_value
FROM avg_order_value


--> Profit Margin Comparison:

WITH profit_comparison AS (
    SELECT Customer_id,
           SUM([Total Amount] - ([Cost Per Unit] * Quantity)) AS total_profit,
           SUM(CASE WHEN discount > 0 THEN ([Total Amount] - ([Cost Per Unit] * Quantity)) ELSE 0 END) AS profit_with_discount,
           SUM(CASE WHEN discount = 0 THEN ([Total Amount] - ([Cost Per Unit] * Quantity)) ELSE 0 END) AS profit_without_discount
    FROM orders
    GROUP BY Customer_id
)
SELECT AVG(profit_with_discount) AS avg_profit_with_discount,
       AVG(profit_without_discount) AS avg_profit_without_discount
FROM profit_comparison


--> 6. Understand preferences of customers (preferred channel, Preferred payment method, preferred store, discount preference, preferred categories etc.)

--> Preferred Sales Channel

SELECT Customer_id, channel, COUNT(order_id) AS order_count
FROM orders
GROUP BY Customer_id, channel
ORDER BY Customer_id, order_count DESC

--> Preferred Payment Method

SELECT payment_type, COUNT(payment_type) AS payment_count
FROM OrderPayments 
GROUP BY payment_type

--> Identify the store each customer most frequently buys from:

SELECT Customer_id, Delivered_StoreID, COUNT(order_id) AS store_count
FROM orders
GROUP BY Customer_id, Delivered_StoreID
ORDER BY customer_id, store_count DESC

--> Preferred Categories

SELECT Customer_id, category, COUNT(p.product_id) AS category_count
FROM orders as o
JOIN ProductsInfo as p ON o.product_id = p.product_id
GROUP BY Customer_id, category
ORDER BY Customer_id, category_count DESC

--> 7. Understand the behavior of customers who purchased one category and purchased multiple categories

--> 1. Customers Who Purchased Only One Category

SELECT Customer_id, COUNT(DISTINCT category) AS category_count
FROM orders as o
JOIN ProductsInfo as p ON o.product_id = p.product_id
GROUP BY Customer_id
HAVING COUNT(DISTINCT category) = 1

--> 2. Customers Who Purchased Multiple Categories

SELECT Customer_id, COUNT(DISTINCT category) AS category_count
FROM orders as o
JOIN ProductsInfo as p ON o.product_id = p.product_id
GROUP BY Customer_id
HAVING COUNT(DISTINCT category) > 1





select * from Customers
select * from OrderReview_Ratings
select * from OrderPayments
select * from Orders
select * from ProductsInfo
select * from [Stores Info]

