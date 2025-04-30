-- Customer Analysis
-- Objective: Explore customer ordering behavior to identify patterns such as repeat ordering, customer segmentation, and trends over time.



-- Monthly Active Customers
-- Helps assess growth and customer engagement trends
SELECT 
    DATE_FORMAT(order_month, '%M, %Y') AS month,
    COUNT(DISTINCT customer_id) AS active_customers
FROM (
    SELECT 
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m-01') AS order_month
    FROM customer_orders
) AS sub
GROUP BY order_month
ORDER BY order_month;





-- First-Time vs Repeat Customers Per Month
-- Tracks customer acquisition vs retention
WITH first_orders AS (
    SELECT 
        customer_id,
        MIN(order_date) AS first_order_date
    FROM 
        customer_orders
    GROUP BY 
        customer_id
)
SELECT 
    DATE_FORMAT(o.order_month, '%M, %Y') AS month,
    COUNT(DISTINCT CASE WHEN o.order_date = f.first_order_date THEN o.customer_id END) AS first_time_customers,
    COUNT(DISTINCT CASE WHEN o.order_date > f.first_order_date THEN o.customer_id END) AS repeat_customers
FROM (
    SELECT 
        customer_id,
        order_date,
        DATE_FORMAT(order_date, '%Y-%m-01') AS order_month  -- Pre-format the date
    FROM 
        customer_orders
) AS o
JOIN 
    first_orders f ON o.customer_id = f.customer_id
GROUP BY 
    o.order_month
ORDER BY 
    o.order_month;







-- Customer Lifetime Value (LTV)
-- Identifies high-value customers based on total spend
SELECT 
    customer_id,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_amount), 2) AS total_spent,
    ROUND(AVG(order_amount), 2) AS avg_order_value
FROM 
    customer_orders
GROUP BY 
    customer_id
ORDER BY 
    total_spent DESC;




-- Top 10% Customers by Spending
-- Useful for segmentation and loyalty campaigns
WITH ranked_customers AS (
  SELECT 
    customer_id,
    SUM(order_amount) AS total_spent,
    NTILE(10) OVER (ORDER BY SUM(order_amount) DESC) AS decile
  FROM 
    customer_orders
  GROUP BY 
    customer_id
)
SELECT 
  CASE WHEN decile = 1 THEN 'Top 10%' ELSE 'Others' END AS segment,
  ROUND(AVG(total_spent), 2) AS avg_spent_per_customer
FROM 
  ranked_customers
GROUP BY 
  segment;




-- Repeat Orders by Month
-- Helps understand retention patterns across months
WITH customer_months AS (
    SELECT 
        customer_id,
        DATE_FORMAT(order_date, '%m') AS month_num,
        DATE_FORMAT(order_date, '%M') AS month_name,
        DATE_FORMAT(order_date, '%Y') AS year,
        COUNT(*) AS order_count
    FROM customer_orders
    GROUP BY customer_id, year, month_num, month_name
),
repeaters AS (
    SELECT month_num, month_name, year, COUNT(*) AS repeat_customers
    FROM customer_months
    WHERE order_count > 1
    GROUP BY year, month_num, month_name
),
all_customers AS (
    SELECT month_num, month_name, year, COUNT(DISTINCT customer_id) AS total_customers
    FROM customer_months
    GROUP BY year, month_num, month_name
)
SELECT 
    CONCAT(r.month_name, ", ", r.year) AS month,
    CONCAT(ROUND((r.repeat_customers * 100.0) / a.total_customers, 2), '%') AS customer_repeat_rate
FROM 
    repeaters r
JOIN 
    all_customers a 
    ON r.month_num = a.month_num AND r.year = a.year
ORDER BY
    r.year, r.month_num;




-- Average Order Value by Customer Segment
-- Groups customers based on order frequency
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'One-Time Buyer'
        WHEN order_count BETWEEN 2 AND 4 THEN 'Occasional Buyer'
        ELSE 'Frequent Buyer'
    END AS customer_segment,
    COUNT(*) AS num_customers,
    ROUND(AVG(total_spent), 2) AS avg_spent
FROM (
    SELECT 
        customer_id,
        COUNT(*) AS order_count,
        SUM(order_amount) AS total_spent
    FROM 
        customer_orders
    GROUP BY 
        customer_id
) AS customer_summary
GROUP BY 
    customer_segment
ORDER BY 
    num_customers DESC;




-- Monthly Retention Rate
-- Tracks customers returning month over month
WITH monthly_customers AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS order_month,
        customer_id
    FROM 
        customer_orders
    GROUP BY 
        DATE_FORMAT(order_date, '%Y-%m'), customer_id
),
month_pairs AS (
    SELECT 
        curr.order_month AS current_month,
        COUNT(DISTINCT curr.customer_id) AS total_customers,
        COUNT(DISTINCT CASE WHEN prev.customer_id IS NOT NULL THEN curr.customer_id END) AS retained_customers
    FROM 
        monthly_customers curr
    LEFT JOIN 
        monthly_customers prev 
        ON curr.customer_id = prev.customer_id 
        AND DATE_SUB(STR_TO_DATE(CONCAT(curr.order_month, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH) = STR_TO_DATE(CONCAT(prev.order_month, '-01'), '%Y-%m-%d')
    GROUP BY 
        curr.order_month
)
SELECT 
    DATE_FORMAT(STR_TO_DATE(CONCAT(current_month, '-01'), '%Y-%m-%d'), '%M %Y') AS month,
    total_customers,
    retained_customers,
    CONCAT(ROUND(retained_customers * 100.0 / total_customers, 2), '%') AS retention_rate
FROM 
    month_pairs
ORDER BY 
    STR_TO_DATE(CONCAT(current_month, '-01'), '%Y-%m-%d');





-- Average Days Between Orders
-- Useful to identify customer purchase frequency
WITH lagged_orders AS (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date
    FROM 
        customer_orders
)
SELECT 
    customer_id,
    ROUND(AVG(DATEDIFF(order_date, previous_order_date)), 2) AS avg_days_between_orders,
    COUNT(*) AS total_orders
FROM 
    lagged_orders
WHERE 
    previous_order_date IS NOT NULL
GROUP BY 
    customer_id
HAVING 
    total_orders > 1
ORDER BY 
    avg_days_between_orders;





-- Order Frequency Buckets
-- Segments customers based on how often they order
WITH customer_freq AS (
    SELECT 
        customer_id,
        COUNT(*) AS total_orders
    FROM 
        customer_orders
    GROUP BY 
        customer_id
)
SELECT 
    CASE 
        WHEN total_orders = 1 THEN '1 order'
        WHEN total_orders BETWEEN 2 AND 5 THEN '2-5 orders'
        WHEN total_orders BETWEEN 6 AND 10 THEN '6-10 orders'
        ELSE '10+ orders'
    END AS frequency_bucket,
    COUNT(*) AS customer_count
FROM 
    customer_freq
GROUP BY 
    frequency_bucket
ORDER BY 
    customer_count DESC;




-- Customers with Unpaid Orders
-- Highlights customers who placed orders but didn’t complete payment
SELECT 
    o.customer_id,
    COUNT(DISTINCT o.order_id) AS unpaid_orders
FROM 
    customer_orders o
LEFT JOIN 
    payments p ON o.order_id = p.order_id
WHERE 
    p.payment_status IS NULL OR p.payment_status != 'completed'
GROUP BY 
    o.customer_id
ORDER BY 
    unpaid_orders DESC;