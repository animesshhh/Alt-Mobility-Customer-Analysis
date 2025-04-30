-- Orders Analysis
-- Objective: Understand order status, order distribution, payment behavior, sales performance, and trends.



-- Order Status Count and Percentage
-- Shows how many orders fall under each status (e.g., delivered, pending) and their percentage of total orders.
SELECT 
    order_status,
    COUNT(*) AS total_orders,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM customer_orders), 2) AS percentage_share
FROM 
    customer_orders
GROUP BY 
    order_status
ORDER BY 
    total_orders DESC;




-- Monthly Revenue and Order Count
-- Summarizes total sales and order volume per month.
SELECT 
    DATE_FORMAT(month_raw, '%M %Y') AS month,
    ROUND(SUM(order_amount), 2) AS total_revenue,
    COUNT(order_id) AS total_orders
FROM (
    SELECT 
        order_id,
        order_amount,
        DATE_FORMAT(order_date, '%Y-%m-01') AS month_raw
    FROM 
        customer_orders
) AS sub
GROUP BY 
    month_raw
ORDER BY 
    STR_TO_DATE(month_raw, '%Y-%m-%d');





-- Revenue by Order Status
-- Helps assess which order statuses contribute most to the total revenue.
SELECT 
    order_status,
    ROUND(SUM(order_amount), 2) AS total_revenue
FROM 
    customer_orders
GROUP BY 
    order_status
ORDER BY 
    total_revenue DESC;




-- Overall Average Order Value (AOV)
-- Indicates the average revenue per order.
SELECT 
    ROUND(AVG(order_amount), 2) AS avg_order_value
FROM 
    customer_orders;




-- Monthly Average Order Value (AOV) Trend
-- Tracks how the AOV changes month-over-month.
SELECT 
    DATE_FORMAT(month_raw, '%M %Y') AS month,
    ROUND(AVG(order_amount), 2) AS avg_order_value
FROM (
    SELECT 
        order_amount,
        DATE_FORMAT(order_date, '%Y-%m-01') AS month_raw
    FROM 
        customer_orders
) AS sub
GROUP BY 
    month_raw
ORDER BY 
    STR_TO_DATE(month_raw, '%Y-%m-%d');





-- AOV by Order Status
-- Helps understand how order value varies across different statuses.
SELECT 
    order_status,
    COUNT(*) AS total_orders,
    ROUND(AVG(order_amount), 2) AS avg_order_value
FROM 
    customer_orders
GROUP BY 
    order_status;




-- Delivery Conversion Rate
-- Calculates what percentage of orders get successfully delivered.
SELECT 
    CONCAT(ROUND(AVG(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) * 100.0, 2), '%') AS delivery_conversion_rate
FROM 
    customer_orders;




-- Fulfillment Lag (Avg Days from Order to Payment)
-- Measures the average number of days it takes for payment to be completed after an order is placed.
SELECT 
    ROUND(AVG(DATEDIFF(p.payment_date, o.order_date)), 2) AS avg_days_to_payment
FROM 
    customer_orders o
JOIN 
    payments p ON o.order_id = p.order_id
WHERE 
    p.payment_status = 'completed';




-- Payment Completion Rate
-- What percentage of payments have been successfully completed.
SELECT 
    CONCAT(ROUND(AVG(CASE WHEN payment_status = 'completed' THEN 1 ELSE 0 END) * 100.0, 2), '%') AS payment_success_rate
FROM 
    payments;




-- Year-over-Year (YoY) Revenue Growth
-- Tracks total revenue growth annually and computes the YoY change in percentage.
SELECT 
    YEAR(order_date) AS year,
    ROUND(SUM(order_amount), 2) AS revenue,
    CONCAT(ROUND(
        (SUM(order_amount) - LAG(SUM(order_amount)) OVER (ORDER BY YEAR(order_date))) / 
        NULLIF(LAG(SUM(order_amount)) OVER (ORDER BY YEAR(order_date)), 0) * 100, 
        2
    ), "%") AS revenue_increase_percentage
FROM 
    customer_orders
GROUP BY 
    year
ORDER BY 
    year;




-- Revenue by Payment Method
-- Helps identify which payment methods bring in the most completed revenue.
SELECT 
    payment_method,
    ROUND(SUM(payment_amount), 2) AS total_paid
FROM 
    payments
WHERE 
    payment_status = 'completed'
GROUP BY 
    payment_method
ORDER BY 
    total_paid DESC;




-- Cumulative Sales Over Time
-- Running total of sales to observe how revenue accumulates day by day.
SELECT 
    order_id,
    order_date,
    order_amount,
    ROUND(SUM(order_amount) OVER (ORDER BY order_date, order_id), 2) AS cumulative_sales
FROM 
    customer_orders;




-- Monthly Order-to-Delivery Conversion Rate
-- Calculates delivery success rate for each month.
SELECT 
    DATE_FORMAT(order_month, '%M %Y') AS month,
    CONCAT(
        ROUND(COUNT(CASE WHEN order_status = 'delivered' THEN 1 END) * 100.0 / COUNT(*), 2),
        '%'
    ) AS delivery_rate
FROM (
    SELECT 
        order_date,
        order_status,
        DATE_FORMAT(order_date, '%Y-%m-01') AS order_month
    FROM 
        customer_orders
) AS sub
GROUP BY 
    order_month
ORDER BY 
    STR_TO_DATE(order_month, '%Y-%m-%d');
 











-- Top 10% Highest Value Orders vs Others
-- Compares average order value of top 10% of orders to the rest.
WITH order_ranks AS (
    SELECT 
        *, 
        NTILE(10) OVER (ORDER BY order_amount DESC) AS decile
    FROM 
        customer_orders
)
SELECT 
    CASE WHEN decile = 1 THEN 'Top 10%' ELSE 'Others' END AS category,
    ROUND(AVG(order_amount), 2) AS avg_order_amount
FROM 
    order_ranks
GROUP BY 
    category;




-- Daily Revenue vs 7-Day Rolling Average
-- Compares daily sales to a rolling 7-day average to identify short-term trends.
SELECT 
    order_date,
    ROUND(SUM(order_amount), 2) AS daily_revenue,
    ROUND(AVG(SUM(order_amount)) OVER (
        ORDER BY order_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS rolling_7d_avg
FROM 
    customer_orders
GROUP BY 
    order_date;




-- Identify Orders With Missing or Incomplete Payments
-- Detects possible payment issues (null or not completed) for follow-up.
SELECT 
    o.order_id,
    o.order_status,
    o.order_date,
    p.payment_status
FROM 
    customer_orders o
LEFT JOIN 
    payments p ON o.order_id = p.order_id
WHERE 
    p.payment_status IS NULL OR p.payment_status != 'completed';




-- Monthly Repeat Order Rate
-- Measures customer loyalty by calculating how many customers placed more than one order in a month.
WITH customer_months AS (
    SELECT 
        customer_id,
        DATE_FORMAT(order_date, '%m') AS month_num,
        DATE_FORMAT(order_date, '%M') AS month_name,
        DATE_FORMAT(order_date, '%Y') AS year,
        COUNT(*) AS order_count
    FROM 
        customer_orders
    GROUP BY 
        customer_id, year, month_num, month_name
),
repeaters AS (
    SELECT 
        month_num, month_name, year, COUNT(*) AS repeat_customers
    FROM 
        customer_months
    WHERE 
        order_count > 1
    GROUP BY 
        year, month_num, month_name
),
all_customers AS (
    SELECT 
        month_num, month_name, year, COUNT(DISTINCT customer_id) AS total_customers
    FROM 
        customer_months
    GROUP BY 
        year, month_num, month_name
)
SELECT 
    CONCAT(r.month_name, " ", r.year) AS month,
    CONCAT(ROUND((r.repeat_customers * 100.0) / a.total_customers, 2), '%') AS repeat_rate
FROM 
    repeaters r
JOIN 
    all_customers a 
    ON r.month_num = a.month_num AND r.year = a.year
ORDER BY 
    r.year, r.month_num;