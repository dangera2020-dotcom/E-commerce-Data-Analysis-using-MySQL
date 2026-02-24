Create database Olist;
Use Olist;

-- Total Orders
Select Count(*) As total_orders
From olist_orders_dataset;

-- Unique Customers
SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM olist_customers_dataset;

-- Total Revenue
SELECT ROUND(SUM(payment_value), 2) AS total_revenue
FROM olist_order_payments_dataset;

-- Average Order Value
SELECT ROUND(AVG(payment_value), 2) AS avg_order_value
FROM olist_order_payments_dataset;

-- Monthly Revenue
Select 
date_format(o.order_purchase_timestamp, '%Y-%m') AS month,
SUM(p.payment_value) AS revenue
FROM olist_orders_dataset o
Join olist_order_payments_dataset p On o.order_id = p.order_id
Group By month 
Order By month ;

-- Orders per Month  
Select
date_format(order_purchase_timestamp, '%Y-%m') AS month,
	COUNT(*) AS Total_Orders
    From olist_orders_dataset
    Group by month 
    Order by month;
    
-- Top Categories by Revenue
ALTER TABLE product_category_name_translation
CHANGE COLUMN `ï»¿product_category_name` product_category_name VARCHAR(255);
SELECT 
    pt.product_category_name_english,
    ROUND(SUM(oi.price), 2) AS Revenue
FROM olist_order_items_dataset oi
JOIN olist_products_dataset pr 
    ON oi.product_id = pr.product_id
JOIN product_category_name_translation pt 
    ON pr.product_category_name = pt.product_category_name
GROUP BY pt.product_category_name_english
ORDER BY Revenue DESC
LIMIT 10;

Select customer_state,
Count(*) AS Total_customers
From olist_customers_dataset
Group by customer_state
Order by Total_customers DESC;

-- Repeat Customers
Select Count(*) AS repeat_customers
From(Select customer_id
          From olist_orders_dataset
          Group by customer_id
          Having Count(order_id)>1)t;
          
   -- Avg Orders per Customer       
          SELECT 
    ROUND(AVG(order_count),2) AS avg_orders
FROM (
    SELECT customer_id, COUNT(order_id) AS order_count
    FROM olist_orders_dataset
    GROUP BY customer_id
) t;
  
  -- Average Delivery Days
SELECT 
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)),2) AS avg_delivery_days
FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NOT NULL;

-- Late Delivery Percentage
SELECT 
 ROUND(
        100 * SUM(
            CASE 
                WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 
                ELSE 0 
            END
        ) / COUNT(*), 2
    ) AS late_delivery_percentage
FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NOT NULL;

-- Delivery Time per State
SELECT 
    c.customer_state,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)),2) AS avg_delivery_days
FROM olist_orders_dataset o
JOIN olist_customers_dataset c 
ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;

-- Average Review Score
SELECT ROUND(AVG(review_score),2) AS avg_rating
FROM olist_order_reviews_dataset;

-- Review Distribution
SELECT 
    review_score,
    COUNT(*) AS total_reviews
FROM olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_score;

-- Late Delivery vs Rating
SELECT 
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status,
    ROUND(AVG(r.review_score),2) AS avg_rating
FROM olist_orders_dataset o
JOIN olist_order_reviews_dataset r 
ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;

-- Payment Type Usage
SELECT 
    payment_type,
    COUNT(*) AS total_transactions
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_transactions DESC;

-- Revenue by Payment Type
SELECT 
    payment_type,
    ROUND(SUM(payment_value),2) AS revenue
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY revenue DESC;

-- Avg Installments
SELECT 
    ROUND(AVG(payment_installments),2) AS avg_installments
FROM olist_order_payments_dataset;

-- Top Sellers by Revenue
SELECT 
    seller_id,
    ROUND(SUM(price),2) AS revenue
FROM olist_order_items_dataset
GROUP BY seller_id
ORDER BY revenue DESC
LIMIT 10;

-- Sellers with Most Orders
SELECT 
    seller_id,
    COUNT(*) AS total_orders
FROM olist_order_items_dataset
GROUP BY seller_id
ORDER BY total_orders DESC
LIMIT 10;

-- Most Sold Products
SELECT 
    product_id,
    COUNT(*) AS total_sold
FROM olist_order_items_dataset
GROUP BY product_id
ORDER BY total_sold DESC
LIMIT 10;

-- Avg Price per Category
SELECT 
    pt.product_category_name_english,
    ROUND(AVG(oi.price),2) AS avg_price
FROM olist_order_items_dataset oi
JOIN olist_products_dataset pr 
ON oi.product_id = pr.product_id
JOIN product_category_name_translation pt 
ON pr.product_category_name = pt.product_category_name
GROUP BY pt.product_category_name_english
ORDER BY avg_price DESC;

-- Top 3 Products per Category 
SELECT *
FROM (
    SELECT 
        pt.product_category_name_english,
        oi.product_id,
        SUM(oi.price) AS revenue,
        RANK() OVER (
            PARTITION BY pt.product_category_name_english 
            ORDER BY SUM(oi.price) DESC
        ) AS rnk
    FROM olist_order_items_dataset oi
    JOIN olist_products_dataset pr 
    ON oi.product_id = pr.product_id
    JOIN product_category_name_translation pt 
    ON pr.product_category_name = pt.product_category_name
    GROUP BY pt.product_category_name_english, oi.product_id
) t
WHERE rnk <= 3;

-- Customers Above Average Spend
SELECT customer_id, total_spent
FROM (
    SELECT 
        o.customer_id,
        SUM(p.payment_value) AS total_spent
    FROM olist_orders_dataset o
    JOIN olist_order_payments_dataset p 
    ON o.order_id = p.order_id
    GROUP BY o.customer_id
) t
WHERE total_spent > (
    SELECT AVG(payment_value) FROM olist_order_payments_dataset
);

-- Monthly Growth
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
        SUM(p.payment_value) AS revenue
    FROM olist_orders_dataset o
    JOIN olist_order_payments_dataset p 
    ON o.order_id = p.order_id
    GROUP BY month
)
SELECT 
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) 
        / LAG(revenue) OVER (ORDER BY month) * 100, 2
    ) AS growth_rate
FROM monthly_sales;