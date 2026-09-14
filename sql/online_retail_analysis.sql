-- Overall sales performance --
SELECT 
	COUNT(*) AS total_transactions,
	SUM(quantity) AS net_quantity,
	ROUND(SUM(line_value), 2) AS total_revenue,
    ROUND(SUM(line_value) / COUNT(*) ,2) AS avg_transaction_value,
	COUNT(DISTINCT customer_id) AS total_customers,
	COUNT(DISTINCT country) AS countries_served
FROM online_retail;

-- Monthly revenue trends --
SELECT 
	YEAR(invoice_date) AS sales_year,
    MONTH(invoice_date) AS sales_month,
    date_format(invoice_date, '%Y-%M') AS month,
    ROUND(SUM(line_value), 2) AS total_revenue
FROM online_retail
GROUP BY sales_year, sales_month, month
ORDER BY sales_year, sales_month;
	
-- Top 10 products by revenue --
SELECT 
	description AS product_description,
    ROUND(SUM(line_value), 2) AS total_revenue
FROM online_retail
WHERE description IS NOT NULL
	AND description <> ''
GROUP BY product_description
ORDER BY total_revenue DESC
LIMIT 10;


-- Top 10 Products by Quantity --
SELECT
	description AS product_description,
    SUM(quantity) AS total_qty_sold
FROM online_retail
WHERE description IS NOT NULL
	AND description <> ''
GROUP BY product_description
ORDER BY total_qty_sold DESC
LIMIT 10;


-- Top-performing countries --

SELECT
	country,
    ROUND(SUM(line_value), 2) AS total_revenue,
    ROUND(
    SUM(line_value) / (SELECT SUM(line_value) FROM online_retail)
    * 100 , 2) AS percentage_revenue
FROM online_retail
GROUP BY country
ORDER BY percentage_revenue DESC;


-- percentage of total revenue comes from the UK --
SELECT
	ROUND(
    SUM(CASE WHEN country = 'United Kingdom' THEN line_value ELSE 0 END) /
    SUM(line_value) * 100 , 2
    ) AS uk_revenue_percentage
FROM online_retail;


-- Revenue per Customer by Country --

SELECT
    country,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(line_value), 2) AS total_revenue,
    ROUND(
        SUM(line_value) / COUNT(DISTINCT customer_id),
        2
    ) AS revenue_per_customer
FROM online_retail
WHERE country IS NOT NULL
  AND country <> ''
  AND customer_id IS NOT NULL
GROUP BY country
ORDER BY revenue_per_customer DESC;

-- Average Revenue by Country -- 
SELECT 
	country,
	COUNT(DISTINCT invoice_no) AS total_transactions,
    SUM(line_value) AS total_revenue,
    ROUND(
    SUM(line_value) / COUNT(DISTINCT invoice_no) , 2
    ) AS average_revenue
FROM online_retail
WHERE country IS NOT NULL 
	AND country <> ''
GROUP BY country
ORDER BY average_revenue DESC;


-- top 10 customers by revenue --
SELECT
	customer_id,
    COUNT(DISTINCT invoice_no) AS total_transactions,
    SUM(quantity) AS net_quantity,
    SUM(line_value) AS total_revenue
FROM online_retail
WHERE customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY total_revenue DESC;


-- Average Order Value by Customer --

SELECT 
	customer_id,
	COUNT(DISTINCT invoice_no) AS total_transaction,
    SUM(line_value) AS total_revenue,
    ROUND(
    SUM(line_value) / COUNT(DISTINCT invoice_no) , 2
    ) AS average_transaction_value
FROM online_retail
WHERE customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY average_transaction_value DESC;


-- Customer Purchase Frequency (Customers who make the most purchases and no cancellations) --
SELECT 
	customer_id,
	COUNT(DISTINCT invoice_no) AS total_transaction,
    SUM(line_value) AS total_revenue
FROM online_retail
WHERE customer_id IS NOT NULL
	AND quantity > 0
GROUP BY customer_id
ORDER BY total_transaction DESC
LIMIT 10;


-- Customer Revenue percentage sharing--

SELECT 
	customer_id,
	SUM(line_value) AS total_revenue,
    ROUND(
	SUM(line_value) / (SELECT SUM(line_value) FROM online_retail 
    WHERE customer_id IS NOT NULL) * 100, 2 
    ) AS customer_revenue_percentage
FROM online_retail
WHERE customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY total_revenue DESC
LIMIT 10;


-- average revenue per customer.--
SELECT 
	ROUND (
    SUM(line_value) / COUNT(DISTINCT customer_id) , 2 
    ) average_customer_revenue
FROM online_retail
WHERE customer_id IS NOT NULL;


-- How significant are cancellations relative to overall transactions and revenue?--
SELECT
    COUNT(*) AS cancellation_records,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM online_retail),
        2
    ) AS cancellation_rate,
    ABS(SUM(quantity)) AS cancelled_quantity,
    ROUND(ABS(SUM(line_value)), 2) AS cancellation_value,
    ROUND(
        ABS(SUM(line_value)) * 100.0 /
        (SELECT SUM(line_value) FROM online_retail),
        2
    ) AS cancellation_value_rate
FROM online_retail
WHERE cancellation_flag = 'Cancellation';


-- Next: Which Products Have the Highest Cancellation Impact?--
SELECT 
	description AS product_description,
    COUNT(*) AS cancellation_records,
    ABS(SUM(quantity)) AS qty_cancelled,
    ABS(SUM(line_value)) AS cancellation_value
FROM online_retail
WHERE cancellation_flag = 'Cancellation'
	AND description IS NOT NULL
    AND description <> ''
GROUP BY description
ORDER BY cancellation_value DESC
LIMIT 10;


-- Which products have the highest proportion of their sales cancelled? --

SELECT
    description AS product_description,

    SUM(CASE
        WHEN quantity > 0 THEN quantity
        ELSE 0
    END) AS quantity_sold,

    ABS(SUM(CASE
        WHEN cancellation_flag = 'Cancellation'
        THEN quantity
        ELSE 0
    END)) AS quantity_cancelled,

    ROUND(
        ABS(SUM(CASE
            WHEN cancellation_flag = 'Cancellation'
            THEN quantity
            ELSE 0
        END))
        /
        NULLIF(
            SUM(CASE
                WHEN quantity > 0 THEN quantity
                ELSE 0
            END),
            0
        ) * 100,
        2
    ) AS cancellation_rate_percentage

FROM online_retail

WHERE description IS NOT NULL
  AND description <> ''

GROUP BY description

HAVING quantity_sold > 0

ORDER BY cancellation_rate_percentage DESC
LIMIT 20;


-- Actual product cancellation rates --

SELECT
    description AS product_description,

    SUM(CASE
        WHEN quantity > 0 THEN quantity
        ELSE 0
    END) AS quantity_sold,

    ABS(SUM(CASE
        WHEN cancellation_flag = 'Cancellation'
        THEN quantity
        ELSE 0
    END)) AS quantity_cancelled,

    ROUND(
        ABS(SUM(CASE
            WHEN cancellation_flag = 'Cancellation'
            THEN quantity
            ELSE 0
        END))
        /
        NULLIF(
            SUM(CASE
                WHEN quantity > 0 THEN quantity
                ELSE 0
            END),
            0
        ) * 100,
        2
    ) AS cancellation_rate_percentage

FROM online_retail

WHERE description IS NOT NULL
  AND description <> ''
  AND description NOT IN (
      'SAMPLES',
      'AMAZON FEE',
      'Bank Charges',
      'Manual',
      'POSTAGE',
      'Cruk Commission'
  )

GROUP BY description

HAVING quantity_sold >= 100

ORDER BY cancellation_rate_percentage DESC
LIMIT 20;


-- Monthly cancellation rates --
SELECT
    YEAR(invoice_date) AS sale_year,
    MONTH(invoice_date) AS sale_month,
    DATE_FORMAT(invoice_date, '%Y - %M') AS month,
    COUNT(*) AS cancellation_records,
    ABS(SUM(quantity)) AS cancelled_quantity,
    ROUND(ABS(SUM(line_value)), 2) AS cancellation_value
FROM online_retail
WHERE cancellation_flag = 'Cancellation'
GROUP BY sale_year, sale_month, month
ORDER BY sale_year, sale_month, month;


-- Which actual products generate the most revenue when non-product entries are excluded?

SELECT
    description AS product_description,
    ROUND(SUM(line_value), 2) AS total_revenue,
    SUM(quantity) AS net_quantity
FROM online_retail
WHERE description IS NOT NULL
  AND description <> ''
  AND description NOT IN (
      'POSTAGE',
      'DOTCOM POSTAGE',
      'AMAZON FEE',
      'Bank Charges',
      'Cruk Commission',
      'Manual',
      'Adjust bad debt'
  )
GROUP BY description
ORDER BY total_revenue DESC
LIMIT 10;


-- average selling price by actual products --
SELECT
    description AS product_description,
    SUM(quantity) AS net_quantity,
    ROUND(SUM(line_value), 2) AS total_revenue,
    ROUND(
        SUM(line_value) / NULLIF(SUM(quantity), 0),
        2
    ) AS average_selling_price
FROM online_retail
WHERE description IS NOT NULL
  AND description <> ''
  AND description NOT IN (
      'POSTAGE',
      'DOTCOM POSTAGE',
      'AMAZON FEE',
      'Bank Charges',
      'Cruk Commission',
      'Manual',
      'Adjust bad debt'
  )
  AND quantity > 0
GROUP BY description
HAVING SUM(quantity) >= 1000
ORDER BY average_selling_price DESC
LIMIT 10;


-- How many customers made only one purchase, compared with customers who returned and purchased multiple times?--
WITH customer_frequency AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS total_transactions
    FROM online_retail
    WHERE customer_id IS NOT NULL
      AND quantity > 0
    GROUP BY customer_id
)

SELECT
    CASE
        WHEN total_transactions = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_frequency),
        2
    ) AS percentage_of_customers
FROM customer_frequency
GROUP BY customer_type
ORDER BY customer_count DESC;		


-- How much revenue comes from repeat customers?
WITH customer_revenue AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS total_transactions,
        SUM(line_value) AS total_revenue
    FROM online_retail
    WHERE customer_id IS NOT NULL
      AND quantity > 0
    GROUP BY customer_id
)

SELECT
    CASE
        WHEN total_transactions = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_revenue), 2) AS total_revenue,
    ROUND(
        SUM(total_revenue) * 100.0 /
        (SELECT SUM(total_revenue) FROM customer_revenue),
        2
    ) AS percentage_of_revenue
FROM customer_revenue
GROUP BY customer_type
ORDER BY total_revenue DESC; 			


-- how much revenue the average customer in each group generates -- 
WITH customer_revenue AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS total_transactions,
        SUM(line_value) AS total_revenue
    FROM online_retail
    WHERE customer_id IS NOT NULL
      AND quantity > 0
    GROUP BY customer_id
)

SELECT
    CASE
        WHEN total_transactions = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_revenue), 2) AS average_customer_revenue
FROM customer_revenue
GROUP BY customer_type
ORDER BY average_customer_revenue DESC;   


-- Sales Performance by Day & Time --

-- Revenue by Day of Week--
SELECT 
	dayname(invoice_date) AS sales_day,
    dayofweek(invoice_date) AS day_of_week,
    COUNT(DISTINCT invoice_no) AS total_transactions,
    SUM(line_value) AS total_revenue
FROM online_retail
GROUP BY sales_day, day_of_week
ORDER BY day_of_week;
	

-- Sales by each Hour --

SELECT
	hour(invoice_time) AS sales_hour,
    COUNT(DISTINCT invoice_no) AS total_transactions,
    SUM(line_value) AS total_revenue
FROM online_retail
GROUP BY sales_hour
ORDER BY sales_hour;


-- average transaction value by hour --

SELECT 
	hour(invoice_time) AS sales_hour,
    COUNT(DISTINCT invoice_no) AS total_transactions,
    SUM(line_value) AS total_revenue,
    ROUND(
		SUM(line_value) / NULLIF(COUNT(DISTINCT invoice_no), 0)	,2 
        ) AS average_transaction_value
	FROM online_retail
    GROUP BY sales_hour
    ORDER BY sales_hour;
    