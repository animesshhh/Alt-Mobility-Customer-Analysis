-- Payments Analysis
-- Objective: Investigate payment status data to identify any potential issues or trends related to payment success and failure.



-- Monthly Payment Success Rate
-- Helps track how payment success evolves over time
SELECT
    DATE_FORMAT(MIN(p.payment_date), '%M %Y') AS month,
    CONCAT(
        ROUND(SUM(CASE WHEN p.payment_status = 'completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2),
        '%'
    ) AS payment_success_rate
FROM
    payments p
GROUP BY
    DATE_FORMAT(p.payment_date, '%Y-%m')
ORDER BY
    MIN(p.payment_date);




-- Failed Payments Count Over Time
-- Identifies spikes or patterns in payment failures
SELECT
    DATE_FORMAT(MIN(p.payment_date), '%M %Y') AS month, -- Use MIN(p.payment_date) to align with the grouping
    COUNT(*) AS failed_payments
FROM
    payments p
WHERE
    p.payment_status = 'failed'
GROUP BY
    DATE_FORMAT(p.payment_date, '%Y-%m')
ORDER BY
    MIN(p.payment_date);




-- Payment Methods with Highest Failure Rates
-- Helps isolate unreliable payment methods
SELECT 
    p.payment_method,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN p.payment_status = 'failed' THEN 1 ELSE 0 END) AS failed_transactions,
    CONCAT(ROUND(SUM(CASE WHEN p.payment_status = 'failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), '%') AS failure_rate
FROM 
    payments p
GROUP BY 
    p.payment_method
ORDER BY 
    failure_rate DESC;




-- Customers with Most Payment Failures
-- Flags customers potentially facing payment issues (tech/user-related)
SELECT 
    o.customer_id,
    COUNT(*) AS failed_payments
FROM 
    payments p
JOIN 
    customer_orders o ON p.order_id = o.order_id
WHERE 
    p.payment_status = 'failed'
GROUP BY 
    o.customer_id
ORDER BY 
    failed_payments DESC
LIMIT 10;




-- Repeat Failures by Same Customers
-- Helps detect persistent user-specific payment problems
SELECT 
    o.customer_id,
    COUNT(*) AS repeat_failures
FROM 
    payments p
JOIN 
    customer_orders o ON p.order_id = o.order_id
WHERE 
    p.payment_status = 'failed'
GROUP BY 
    o.customer_id
HAVING 
    COUNT(*) > 1
ORDER BY 
    repeat_failures DESC;




-- Orders with Payment Failures but Marked as Delivered
-- Detects data inconsistencies between payment and fulfillment
SELECT 
    o.order_id,
    o.customer_id,
    o.order_date,
    p.payment_status,
    o.order_status
FROM 
    customer_orders o
JOIN 
    payments p ON o.order_id = p.order_id
WHERE 
    p.payment_status = 'failed'
    AND o.order_status = 'delivered';




-- Payment Method Trends Over Time
-- Monitors usage and adoption of payment methods monthly
WITH formatted_payments AS (
    SELECT
        p.payment_method,
        COUNT(*) AS transaction_count,
        DATE_FORMAT(p.payment_date, '%Y-%m') AS order_month  -- Format to 'YYYY-MM' for grouping
    FROM
        payments p
    GROUP BY
        order_month, p.payment_method
)
SELECT
    DATE_FORMAT(CONCAT(order_month, '-01'), '%M %Y') AS month_year, -- Concatenate '-01' to make it a valid date string
    payment_method,
    transaction_count
FROM
    formatted_payments
ORDER BY
    order_month ASC, transaction_count DESC;




-- Monthly Payment Failure Analysis
-- Identifies whether failures peak at specific times of day
SELECT 
    DATE(p.payment_date) AS date,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN p.payment_status = 'failed' THEN 1 ELSE 0 END) AS failed_transactions,
    CONCAT(ROUND(AVG(CASE WHEN p.payment_status = 'failed' THEN 1 ELSE 0 END) * 100.0, 2), '%') AS failure_rate
FROM 
    payments p
GROUP BY 
    DATE(p.payment_date)
ORDER BY 
    date;




-- Correlation Between Order Value and Payment Failures
-- Determines if higher-value transactions fail more frequently
SELECT 
    CASE 
        WHEN o.order_amount < 100 THEN 'Below ₹100'
        WHEN o.order_amount BETWEEN 100 AND 499 THEN '₹100 - ₹499'
        WHEN o.order_amount BETWEEN 500 AND 999 THEN '₹500 - ₹999'
        ELSE '₹1000+'
    END AS order_value_band,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN p.payment_status = 'failed' THEN 1 ELSE 0 END) AS failed_orders,
    CONCAT(ROUND(AVG(CASE WHEN p.payment_status = 'failed' THEN 1 ELSE 0 END) * 100.0, 2), '%') AS failure_rate
FROM 
    customer_orders o
JOIN 
    payments p ON o.order_id = p.order_id
GROUP BY 
    order_value_band
ORDER BY 
    failure_rate DESC;
