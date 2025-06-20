USE olist2;

/*
-- -------------------------------------
# CHAPTER 1: SALES/ REVENUE ANALYSIS
-- -------------------------------------
Data Coverage and  Initial Sales Audit
Auditing time range, checking order uniqueness, and ensuring payment alignment
*/ 

# Finding the the timeframe for the data
SELECT MAX(purchase_time) AS Last_purchase, MIN(purchase_time) AS first_purchase
FROM orders;
# 4 Septermber 2016 to 17 October 2018 - thats about 25 months

# Checking the number of orders
SELECT COUNT(order_id)
FROM orders;
# 99,441 Orders

# Checking if all order_ids are unique in orders table
SELECT order_id, COUNT(*) AS count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;
# All Order_ids are unique

# Joining orders table to payments table via order_id field
SELECT 
    o.order_id,
    o.customer_id,
    o.purchase_time,
    p.payment_type,
    p.payment_value
FROM orders o
JOIN order_payments p
  ON o.order_id = p.order_id;

# Checking if there are payments that doesnt match any orders
SELECT p.order_id
FROM order_payments p
LEFT JOIN orders o ON p.order_id = o.order_id
WHERE o.order_id IS NULL;
# There are 4

# Finding the orders that does not have payments
SELECT COUNT(*) AS orders_without_payments
FROM orders o
LEFT JOIN order_payments p ON o.order_id = p.order_id
WHERE p.order_id IS NULL;

# Listing the orders that does not have payments 
SELECT o.order_id, purchase_time
FROM orders o
LEFT JOIN order_payments p ON o.order_id = p.order_id
WHERE p.order_id IS NULL;

# Deleting the records that does not have payments made
DELETE FROM orders o
WHERE NOT EXISTS (
  SELECT 1
  FROM order_payments p
  WHERE p.order_id = o.order_id
);

# What is Order_status field? Perhaps I need to check this before 
SELECT 
    order_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

/*
# There are 8 distinct types: (delivered, shipped, cancelled, unavailable, invoiced, processing, created & approved)
# For revenue calculations I am going to use only DELIVERED and SHIPPED orders.
*/ 


# Total revenues
SELECT 
    ROUND(SUM(p.payment_value), 2) AS total_revenue
FROM order_payments p
JOIN orders o ON p.order_id = o.order_id
WHERE o.order_status IN ('delivered', 'shipped');
# Total Revenues: 15,599,675.73

# Breakingdown revenue for each year 
SELECT 
    EXTRACT(YEAR FROM o.Purchase_time) AS year,
    ROUND(SUM(p.payment_value), 2) AS revenue
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status IN ('delivered', 'shipped')
GROUP BY year
ORDER BY year;

# Revenue per month
SELECT 
    DATE_FORMAT(o.purchase_time, '%Y-%m') AS month,
    ROUND(SUM(p.payment_value), 2) AS total_revenue
FROM order_payments p
JOIN orders o ON p.order_id = o.order_id
WHERE o.order_status IN ('delivered', 'shipped')
GROUP BY DATE_FORMAT(o.purchase_time, '%Y-%m')
ORDER BY month;

# Will be more useful to make a table with  total revenues, orders and average revenues on a monthly basis
# Before that lets make a merged table for matching order ids in Orders and Order_Payments

DROP TABLE IF EXISTS merged_orders_payments;
CREATE TABLE merged_orders_payments AS
SELECT 
    o.order_id,
    o.customer_id,
    o.order_status,
    o.purchase_time,
    p.payment_type,
    p.payment_installments,
    p.payment_value
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status IN ('delivered', 'shipped');

# Now lets make the above mentioned table: 
DROP TABLE IF EXISTS monthly_orders_revenue_summary;
CREATE TABLE monthly_orders_revenue_summary AS
SELECT 
    DATE_FORMAT(purchase_time, '%Y-%m') AS month,
    ROUND(SUM(payment_value), 2) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(payment_value) / COUNT(DISTINCT order_id), 2) AS avg_revenue_per_order
FROM merged_orders_payments
WHERE order_status IN ('delivered', 'shipped')
GROUP BY DATE_FORMAT(purchase_time, '%Y-%m')
ORDER BY month;

/*
#Great, so now we have total sales figures, order figures, average revenue per order broken down on a monthly basis.
#Lets tackle the figures on a product category level analysis
#Lets make a table with monthly category revenues (translated to english) without freight values.
*/

DROP TABLE IF EXISTS monthly_category_revenue;
CREATE TABLE monthly_category_revenue AS
SELECT 
    DATE_FORMAT(o.purchase_time, '%Y-%m') AS month,
    t.product_category_name_english AS category,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
JOIN category_name_translation t 
    ON pr.product_category_name = t.product_category_name
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status IN ('delivered', 'shipped')
GROUP BY DATE_FORMAT(o.purchase_time, '%Y-%m'), t.product_category_name_english
ORDER BY month, total_revenue DESC;


# Making a table with  total revenues and total qty sold for every category 
DROP TABLE IF EXISTS category_sales_summary;
CREATE TABLE category_sales_summary AS
SELECT 
    t.product_category_name_english AS category,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    COUNT(*) AS total_items_sold
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
JOIN category_name_translation t 
    ON pr.product_category_name = t.product_category_name
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status IN ('delivered', 'shipped')
GROUP BY t.product_category_name_english
ORDER BY total_revenue DESC;


#Lets move in to geography now: Revenue and order numbers by states?

DROP TABLE IF EXISTS state_city_revenue;
CREATE TABLE state_city_revenue AS
SELECT 
    c.customer_state,
    c.customer_city,
    ROUND(SUM(p.payment_value), 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.payment_value) / COUNT(DISTINCT o.order_id), 2) AS avg_revenue_per_order
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status IN ('delivered', 'shipped')
GROUP BY c.customer_state, c.customer_city
ORDER BY total_revenue DESC;


DROP TABLE IF EXISTS state_revenue_summary;
CREATE TABLE state_revenue_summary AS
SELECT 
    c.customer_state,
    ROUND(SUM(p.payment_value), 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.payment_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status IN ('delivered', 'shipped')
GROUP BY c.customer_state
ORDER BY total_revenue DESC;


# Lets move on to  revenue analysis for sellers: total revenues , total orders, and average revenue per order

DROP TABLE IF EXISTS seller_total_revenue;
CREATE TABLE seller_total_revenue AS
SELECT 
    oi.seller_id,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price) / COUNT(DISTINCT oi.order_id), 2) AS avg_revenue_per_order
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status IN ('delivered', 'shipped')
GROUP BY oi.seller_id
ORDER BY total_revenue DESC;

# Review ratings for sellers along with their total revenue, orders, average revenue per order

DROP TABLE IF EXISTS seller_revenue_review_summary;
CREATE TABLE seller_revenue_review_summary AS
SELECT 
    oi.seller_id,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price) / COUNT(DISTINCT oi.order_id), 2) AS avg_revenue_per_order,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(DISTINCT r.review_id) AS review_count
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status IN ('delivered', 'shipped')
  AND (r.review_score IS NOT NULL OR r.review_score IS NULL)
GROUP BY oi.seller_id
ORDER BY total_revenue DESC;

SELECT *
FROM seller_revenue_review_summary;

SELECT COUNT(*)
FROM sellers;

/* Sellers table had 3,095 records, but the above table generated 2,977 records. 
This probably means some sellers have zero sales. Lets confirm. */

SELECT COUNT(*) AS sellers_with_no_sales
FROM sellers s
LEFT JOIN order_items oi ON s.seller_id = oi.seller_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.order_status IN ('delivered', 'shipped')
WHERE oi.order_id IS NULL;

/*  Oops, theres no sellers with zero sales. This raises questions. 
-- Maybe its to do with order status (not yet delivered or shipped) Lets check.
Lets check sellers with only non-fulfilled orders? */

SELECT COUNT(*) AS sellers_with_only_unfulfilled_orders
FROM (
  SELECT s.seller_id
  FROM sellers s
  JOIN order_items oi ON s.seller_id = oi.seller_id
  JOIN orders o ON oi.order_id = o.order_id
  GROUP BY s.seller_id
  HAVING SUM(CASE WHEN o.order_status IN ('delivered', 'shipped') THEN 1 ELSE 0 END) = 0
) AS sub;

# Returns 118. That matches, 3095 - 2977. Perfect. Lets move on. 


/*
-- -------------------------------------
# CHAPTER 2: PAYMENTS ANALYSIS
-- -------------------------------------
*/

# Payment types used, total transactions, total revenue, average payment value
DROP TABLE IF EXISTS payment_type_distribution;
CREATE TABLE payment_type_distribution AS
SELECT 
    p.payment_type,
    COUNT(*) AS num_transactions,
    ROUND(SUM(p.payment_value), 2) AS total_revenue,
    ROUND(AVG(p.payment_value), 2) AS avg_payment_value,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(*) 
        FROM order_payments p2
        JOIN orders o2 ON p2.order_id = o2.order_id
        WHERE o2.order_status IN ('delivered', 'shipped')
    ), 2) AS percentage_of_transactions
FROM order_payments p
JOIN orders o ON p.order_id = o.order_id
WHERE o.order_status IN ('delivered', 'shipped')
GROUP BY p.payment_type
ORDER BY total_revenue DESC;


# Payments installment distribution? How many payments per order?
DROP TABLE IF EXISTS installment_distribution;
CREATE TABLE installment_distribution AS
SELECT 
    p.payment_installments,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(*) 
        FROM order_payments p2
        JOIN orders o2 ON p2.order_id = o2.order_id
        WHERE o2.order_status IN ('delivered', 'shipped')
    ), 2) AS percentage
FROM order_payments p
JOIN orders o ON p.order_id = o.order_id
WHERE o.order_status IN ('delivered', 'shipped')
GROUP BY p.payment_installments
ORDER BY p.payment_installments;

SELECT 
    payment_installments,
    COUNT(*) AS count,
    ROUND(AVG(payment_value), 2) AS avg_value
FROM order_payments
WHERE payment_installments > 6
GROUP BY payment_installments
ORDER BY count DESC;

/*
Checking the risk on installments: revenue share of high-installment payments. 
6 or more installments is often considered a risk signal in e-commerce and consumer finance.
*/ 

DROP TABLE IF EXISTS high_installment_revenue_share;
CREATE TABLE high_installment_revenue_share AS
SELECT 
    p.payment_installments,
    COUNT(*) AS count,
    ROUND(AVG(p.payment_value), 2) AS avg_value,
    ROUND(SUM(p.payment_value), 2) AS total_value,
    ROUND(SUM(p.payment_value) * 100.0 / (
        SELECT SUM(p2.payment_value)
        FROM order_payments p2
        JOIN orders o2 ON p2.order_id = o2.order_id
        WHERE o2.order_status IN ('delivered', 'shipped')
    ), 2) AS percentage_of_total_revenue
FROM order_payments p
JOIN orders o ON p.order_id = o.order_id
WHERE p.payment_installments > 6
  AND o.order_status IN ('delivered', 'shipped')
GROUP BY p.payment_installments
ORDER BY count DESC;


# Understanding if certain regions prefer different payment methods or are more reliant on installments.
DROP TABLE IF EXISTS state_payment_behavior;
CREATE TABLE state_payment_behavior AS
SELECT 
    c.customer_state,
    p.payment_type,
    COUNT(*) AS total_transactions,
    ROUND(AVG(p.payment_installments), 2) AS avg_installments
FROM order_payments p
JOIN orders o ON p.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state, p.payment_type
ORDER BY total_transactions DESC;

/*
-- -------------------------------------
# CHAPTER 3: FREIGHT ANALYSIS
-- -------------------------------------
*/

SELECT *
FROM order_items;

SELECT 
    order_id,
    SUM(freight_value) AS total_freight
FROM 
    order_items
GROUP BY 
    order_id;
    
SELECT COUNT(*) AS total_records
FROM order_items;
# 112,650 total records in order_items

# Count the number of orders grouped by the number of items per order
SELECT 
    item_count,
    COUNT(*) AS number_of_orders
FROM (
    SELECT 
        order_id,
        COUNT(*) AS item_count
    FROM 
        order_items
    GROUP BY 
        order_id
) AS order_item_counts
GROUP BY 
    item_count
ORDER BY 
    item_count;

# Checking total distinct order_ids in order_items
SELECT 
    COUNT(DISTINCT order_id) AS total_distinct_orders
FROM 
    order_items;
# 98,666 distinct orders

# Checking total distinct order_ids in orders table
SELECT 
    COUNT(DISTINCT order_id) AS total_orders
FROM 
    orders;
# 99,437 - so there is a difference here. Lets check why


SELECT 
    COUNT(*) AS orders_without_items
FROM 
    orders o
LEFT JOIN 
    order_items oi ON o.order_id = oi.order_id
WHERE 
    oi.order_id IS NULL;
# 772 orders not tied to any items. 

/* Now, it looks like  the total freight amount per order is repeated for each item in any single order. 
I need to tie unique order_ids to the a single freight value of any one item. */

DROP TABLE IF EXISTS order_freight_total;
CREATE TABLE order_freight_total AS
SELECT
    order_id,
    MAX(freight_value) AS freight_value
FROM
    order_items
GROUP BY
    order_id;

# Now lets find the weight summary for each order. For this I'll calculate a volume column and a dimensional weight column
DROP TABLE IF EXISTS order_weight_summary;
CREATE TABLE order_weight_summary AS
SELECT
    oi.order_id,
    SUM(p.product_weight_g) AS total_actual_weight_g,
    SUM(
        (p.product_length_cm * p.product_height_cm * p.product_width_cm) / 6000
    ) AS total_dim_weight_kg
FROM 
    order_items oi
JOIN 
    products p ON oi.product_id = p.product_id
GROUP BY 
    oi.order_id;

SELECT COUNT(*)
FROM order_weight_summary;

/* The count for the exported table just now was 97,270, but there were 98,666 unique order_id's in order_items table.
Maybe there are product_ids in order_items table that do not have a matching entry. Let me check */

SELECT COUNT(DISTINCT oi.order_id) AS unmatched_orders
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;
# OK, the difference is due to missing products metadata and because of the JOIN. 

# Lets move/merge the calculated fields to the order_freight_total table, rather than keep two tables: 
ALTER TABLE order_freight_total
ADD COLUMN total_actual_weight_g DOUBLE,
ADD COLUMN total_dim_weight_kg DOUBLE;
UPDATE order_freight_total oft
LEFT JOIN order_weight_summary ows ON oft.order_id = ows.order_id
SET 
    oft.total_actual_weight_g = ows.total_actual_weight_g,
    oft.total_dim_weight_kg = ows.total_dim_weight_kg;

# Remove the original 2 tables 
DROP TABLE IF EXISTS order_weight_summary, order_freight_summary;

# Regional Freight Band Analysis for shipped and delivered orders
DROP TABLE IF EXISTS state_freight_bucket_summary;
CREATE TABLE state_freight_bucket_summary AS
WITH order_freight AS (
    SELECT 
        o.order_id,
        c.customer_state,
        SUM(oi.freight_value) AS total_freight
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status IN ('delivered', 'shipped')
    GROUP BY o.order_id, c.customer_state
)
SELECT 
    customer_state,
    CASE
        WHEN total_freight < 10 THEN 'Under 10'
        WHEN total_freight BETWEEN 10 AND 19.99 THEN '10 - 19.99'
        WHEN total_freight BETWEEN 20 AND 29.99 THEN '20 - 29.99'
        WHEN total_freight BETWEEN 30 AND 49.99 THEN '30 - 49.99'
        ELSE '50+'
    END AS freight_bucket,
    COUNT(*) AS order_count
FROM order_freight
GROUP BY customer_state, freight_bucket
ORDER BY customer_state, freight_bucket;

# Total order value vs Total Freight Value with a ratio to determine which orders are disproportionately expensive to ship.
DROP TABLE IF EXISTS order_value_vs_freight;
CREATE TABLE order_value_vs_freight AS
SELECT
    oi.order_id,
    SUM(oi.price) AS total_order_value,
    MAX(oi.freight_value) AS freight_value,
    ROUND(MAX(oi.freight_value) / NULLIF(SUM(oi.price), 0), 4) AS freight_ratio
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status IN ('delivered', 'shipped')
GROUP BY oi.order_id;

# Lets check  which regions have high freight costs relative to order size
DROP TABLE IF EXISTS freight_ratio_by_region;
CREATE TABLE freight_ratio_by_region AS
SELECT 
    c.customer_state,
    c.customer_city,
    COUNT(ovf.order_id) AS total_orders,
    AVG(ovf.freight_value / ovf.total_order_value) AS avg_freight_ratio,
    AVG(ovf.freight_value) AS avg_freight,
    AVG(ovf.total_order_value) AS avg_order_value
FROM order_value_vs_freight ovf
JOIN orders o ON ovf.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state, c.customer_city
ORDER BY avg_freight_ratio DESC;
# That generated 4,285 records. Lets do by state instead.

DROP TABLE IF EXISTS freight_ratio_by_state;
CREATE TABLE freight_ratio_by_state AS
SELECT 
    c.customer_state,
    COUNT(ovf.order_id) AS total_orders,
    AVG(ovf.freight_value / ovf.total_order_value) AS avg_freight_ratio,
    AVG(ovf.freight_value) AS avg_freight,
    AVG(ovf.total_order_value) AS avg_order_value
FROM order_value_vs_freight ovf
JOIN orders o ON ovf.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_freight_ratio DESC;
# This is a bit more meaningful for a quick glance.


/* Lets look in to delivery efficiency
Whats the freight amount vs the number of days it took to deliver on a state level? */

DROP TABLE IF EXISTS freight_by_state;
CREATE TABLE freight_by_state AS
SELECT 
    c.customer_state,
    ROUND(SUM(oi.freight_value), 2) AS total_freight,
    ROUND(SUM(DATEDIFF(o.delivered_time, o.purchase_time)), 0) AS total_delivery_days,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.freight_value) / SUM(DATEDIFF(o.delivered_time, o.purchase_time)), 2) AS avg_freight_per_day,
    ROUND(SUM(oi.freight_value) / COUNT(DISTINCT o.order_id), 2) AS avg_freight_per_order,
    ROUND(SUM(DATEDIFF(o.delivered_time, o.purchase_time)) / COUNT(DISTINCT o.order_id), 2) AS avg_delivery_days
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.delivered_time IS NOT NULL
  AND o.purchase_time IS NOT NULL
  AND DATEDIFF(o.delivered_time, o.purchase_time) > 0
GROUP BY c.customer_state
ORDER BY avg_freight_per_day DESC;


# Order Count by Delivery Time Band
DROP TABLE IF EXISTS delivery_time_distribution;
CREATE TABLE delivery_time_distribution AS
SELECT 
  delivery_band,
  orders_in_band,
  ROUND(100.0 * orders_in_band / total_orders, 2) AS percent_of_total
FROM (
  SELECT 
    CASE 
      WHEN DATEDIFF(delivered_time, purchase_time) BETWEEN 0 AND 5 THEN '0-5 days'
      WHEN DATEDIFF(delivered_time, purchase_time) BETWEEN 6 AND 10 THEN '6-10 days'
      WHEN DATEDIFF(delivered_time, purchase_time) BETWEEN 11 AND 15 THEN '11-15 days'
      WHEN DATEDIFF(delivered_time, purchase_time) BETWEEN 16 AND 20 THEN '16-20 days'
      ELSE '21+ days'
    END AS delivery_band,
    COUNT(*) AS orders_in_band,
    (SELECT COUNT(*) 
     FROM orders 
     WHERE delivered_time IS NOT NULL AND purchase_time IS NOT NULL) AS total_orders
  FROM orders
  WHERE delivered_time IS NOT NULL AND purchase_time IS NOT NULL
  GROUP BY delivery_band
) AS banded
ORDER BY 
  CASE 
    WHEN delivery_band = '0-5 days' THEN 1
    WHEN delivery_band = '6-10 days' THEN 2
    WHEN delivery_band = '11-15 days' THEN 3
    WHEN delivery_band = '16-20 days' THEN 4
    ELSE 5
  END;


# State Level Delivery Performance: Time Band Distribution
DROP TABLE IF EXISTS delivery_band_by_state;
CREATE TABLE delivery_band_by_state AS
SELECT 
  customer_state,
  delivery_band,
  COUNT(*) AS orders_in_band,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY customer_state), 2) AS percent_within_state
FROM (
  SELECT 
    c.customer_state,
    CASE 
      WHEN DATEDIFF(o.delivered_time, o.purchase_time) BETWEEN 0 AND 5 THEN '0-5 days'
      WHEN DATEDIFF(o.delivered_time, o.purchase_time) BETWEEN 6 AND 10 THEN '6-10 days'
      WHEN DATEDIFF(o.delivered_time, o.purchase_time) BETWEEN 11 AND 15 THEN '11-15 days'
      WHEN DATEDIFF(o.delivered_time, o.purchase_time) BETWEEN 16 AND 20 THEN '16-20 days'
      ELSE '21+ days'
    END AS delivery_band
  FROM orders o
  JOIN customers c ON o.customer_id = c.customer_id
  WHERE o.delivered_time IS NOT NULL AND o.purchase_time IS NOT NULL
) AS sub
GROUP BY customer_state, delivery_band
ORDER BY customer_state, 
  CASE 
    WHEN delivery_band = '0-5 days' THEN 1
    WHEN delivery_band = '6-10 days' THEN 2
    WHEN delivery_band = '11-15 days' THEN 3
    WHEN delivery_band = '16-20 days' THEN 4
    ELSE 5
  END;

/* In few states, the majority of the orders are falling in to the 21 day+ bandwidth. 
This is concerning. Lets dig deeper in to the these super late deliveries */

SELECT 
  CASE 
    WHEN DATEDIFF(delivered_time, purchase_time) BETWEEN 20 AND 30 THEN '20-30 days'
    WHEN DATEDIFF(delivered_time, purchase_time) BETWEEN 31 AND 40 THEN '31-40 days'
    WHEN DATEDIFF(delivered_time, purchase_time) BETWEEN 41 AND 50 THEN '41-50 days'
    ELSE '51+ days'
  END AS delivery_band,
  COUNT(*) AS orders_in_band,
  ROUND(100.0 * COUNT(*) / (
    SELECT COUNT(*) 
    FROM orders 
    WHERE delivered_time IS NOT NULL AND purchase_time IS NOT NULL
  ), 2) AS percent_of_total
FROM orders
WHERE delivered_time IS NOT NULL AND purchase_time IS NOT NULL
  AND DATEDIFF(delivered_time, purchase_time) > 20
GROUP BY delivery_band
ORDER BY 
  CASE 
    WHEN delivery_band = '20-30 days' THEN 1
    WHEN delivery_band = '31-40 days' THEN 2
    WHEN delivery_band = '41-50 days' THEN 3
    ELSE 4
  END;
# Startling revelation that more than 12% of orders take more than 20 days to deliver. Thats about 12,000 orders.


# Seller operational speed. Order approval to shipping?
DROP TABLE IF EXISTS approval_to_shipping_bands;
CREATE TABLE approval_to_shipping_bands AS
SELECT 
  CASE 
    WHEN DATEDIFF(order_delivered_carrier_date, order_approved_at) = 0 THEN 'Same Day'
    WHEN DATEDIFF(order_delivered_carrier_date, order_approved_at) BETWEEN 1 AND 2 THEN '1-2 Days'
    WHEN DATEDIFF(order_delivered_carrier_date, order_approved_at) BETWEEN 3 AND 5 THEN '3-5 Days'
    WHEN DATEDIFF(order_delivered_carrier_date, order_approved_at) BETWEEN 6 AND 10 THEN '6-10 Days'
    ELSE '10+ Days'
  END AS approval_to_shipping_band,
  COUNT(*) AS order_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage_of_orders
FROM orders
WHERE order_status IN ('delivered', 'shipped')
  AND order_approved_at IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
GROUP BY approval_to_shipping_band
ORDER BY order_count DESC;

/* Looks like more than 60% of sellers shipping within 2 days. 
Although theres 12% of orders shipping 5+ days, of which almost 4% is 10+ days. */


/* -------------------------------------
CHAPTER 4: CUSTOMER EXPERIENCE AND FEEDBACK
-- ------------------------------------*/

/* Category-level review metrics
 Review summary per category with correct review-to-sales ratio
 It is noticed that almost 100% of orders have review ratings. */

DROP TABLE IF EXISTS category_review_summary;
CREATE TABLE category_review_summary AS
SELECT 
  t.product_category_name_english AS category_name,
  ROUND(AVG(r.review_score), 2) AS avg_review_score,
  COUNT(*) AS review_count
FROM order_reviews r
JOIN orders o ON r.order_id = o.order_id
JOIN order_items i ON o.order_id = i.order_id
JOIN products p ON i.product_id = p.product_id
LEFT JOIN category_name_translation t ON p.product_category_name = t.product_category_name
WHERE r.review_score IS NOT NULL
GROUP BY t.product_category_name_english
ORDER BY avg_review_score DESC;

# Sellers total revenue, total orders, average revenue per order, avg review score and review count

DROP TABLE IF EXISTS seller_revenue_review_summary;
CREATE TABLE seller_revenue_review_summary AS
SELECT 
    oi.seller_id,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price) / COUNT(DISTINCT oi.order_id), 2) AS avg_revenue_per_order,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(DISTINCT r.review_id) AS review_count
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status IN ('delivered', 'shipped')
  AND (r.review_score IS NOT NULL OR r.review_score IS NULL)
GROUP BY oi.seller_id
ORDER BY total_revenue DESC;

SELECT COUNT(*)
FROM sellers;

/* Sellers table had 3,095 records, but the above table generated 2,977 records. 
This probably means some sellers have zero sales. Lets confirm. */

SELECT COUNT(*) AS sellers_with_no_sales
FROM sellers s
LEFT JOIN order_items oi ON s.seller_id = oi.seller_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.order_status IN ('delivered', 'shipped')
WHERE oi.order_id IS NULL;

-- Oops, theres no sellers with zero sales. This raises questions. 
-- Maybe its to do with order status (not yet delivered or shipped) Lets check.

-- Sellers with only non-fulfilled orders
SELECT COUNT(*) AS sellers_with_only_unfulfilled_orders
FROM (
  SELECT s.seller_id
  FROM sellers s
  JOIN order_items oi ON s.seller_id = oi.seller_id
  JOIN orders o ON oi.order_id = o.order_id
  GROUP BY s.seller_id
  HAVING SUM(CASE WHEN o.order_status IN ('delivered', 'shipped') THEN 1 ELSE 0 END) = 0
) AS sub;

# Returns 118. That matches, 3095 - 2977. Perfect. Lets move on. 

# Moving on to the text reviews left. I'll export these to a table and CSV for NLP analysis on Python.

DROP TABLE IF EXISTS review_text_by_score;
CREATE TABLE review_text_by_score AS
SELECT 
  review_score,
  CONCAT(
    COALESCE(review_comment_title, ''), ' ',
    COALESCE(review_comment_message, '')
  ) AS full_review_text
FROM order_reviews
WHERE 
  (review_comment_message IS NOT NULL AND TRIM(review_comment_message) <> '')
  OR 
  (review_comment_title IS NOT NULL AND TRIM(review_comment_title) <> '');

# Is there a correlation between delivery time and score? 

DROP TABLE IF EXISTS delivery_time_vs_review_score;
CREATE TABLE delivery_time_vs_review_score AS
SELECT 
  r.review_score,
  ROUND(AVG(DATEDIFF(o.delivered_time, o.purchase_time)), 2) AS avg_delivery_days,
  COUNT(*) AS review_count
FROM order_reviews r
JOIN orders o ON r.order_id = o.order_id
WHERE r.review_score IS NOT NULL
  AND o.delivered_time IS NOT NULL
  AND o.purchase_time IS NOT NULL
GROUP BY r.review_score
ORDER BY r.review_score;

# Definite correlation

# Which cities or states report the highest or lowest customer satisfaction?

DROP TABLE IF EXISTS state_review_summary;
CREATE TABLE state_review_summary AS
SELECT 
  c.customer_state,
  ROUND(AVG(r.review_score), 2) AS avg_review_score,
  COUNT(*) AS review_count
FROM order_reviews r
JOIN orders o ON r.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE r.review_score IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_review_score ASC;


/* -------------------------------------
 CHAPTER 5: CUSTOMER BEHAVIOUR AND SEGMENTATION
-- ------------------------------------- */

# Unique customers in orders table and customers table?

SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM orders;
# 99437

SELECT COUNT(DISTINCT customer_unique_id) AS total_unique_customers
FROM customers; 
# 96,096 - why is there a difference between the customers in orders table and customers table. Lets check.

SELECT COUNT(DISTINCT o.customer_id)
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

/* Okay, this brought a result of 0 - this is good, but this does mean that the same users ordering through different devices, 
accounts, or checkout flows. For true customer analysis (retention, LTV, order frequency)I need to use customer_unique_id. */

SELECT COUNT(DISTINCT customer_id) AS customer_ids,
       COUNT(DISTINCT customer_unique_id) AS unique_ids
FROM customers;

SELECT customer_unique_id
FROM customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1
LIMIT 10;
# That was just making sure. 

# Count of customers by # of orders
DROP TABLE IF EXISTS customer_order_frequency;
CREATE TABLE customer_order_frequency AS
SELECT 
  total_orders,
  COUNT(*) AS customer_count,
  ROUND(COUNT(*) * 100.0 / (
    SELECT COUNT(DISTINCT customer_unique_id)
    FROM customers
  ), 2) AS percentage_of_customers
FROM (
  SELECT 
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  GROUP BY c.customer_unique_id
) AS order_counts
GROUP BY total_orders
ORDER BY total_orders;

/* From a total of 99,337 less thatn 4% ordered more than once. 
This makes retention or repeat behavior analysis statistically thin.
 Very well, but then is there anything we can do to reactivate customers? */

# Compare avg review score of one-time vs repeat buyers
# Compare average review score between one-time and repeat buyers

DROP TABLE IF EXISTS customer_type_review_summary;
CREATE TABLE customer_type_review_summary AS
SELECT 
  customer_type,
  ROUND(AVG(review_score), 2) AS avg_review_score,
  COUNT(*) AS review_count
FROM (
  SELECT 
    r.review_score,
    CASE 
      WHEN oc.total_orders = 1 THEN 'One-Time'
      ELSE 'Repeat'
    END AS customer_type
  FROM order_reviews r
  JOIN orders o ON r.order_id = o.order_id
  JOIN customers c ON o.customer_id = c.customer_id
  JOIN (
    SELECT 
      customer_unique_id,
      COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY customer_unique_id
  ) AS oc ON c.customer_unique_id = oc.customer_unique_id
  WHERE r.review_score IS NOT NULL
) AS classified_reviews
GROUP BY customer_type;

# there is not much of a difference, 4.08 for one-time and 4.13 for repeat customers. 

# Let me check interpurchase time for repeat customers 

DROP TABLE IF EXISTS repeat_customer_order_stats;
CREATE TABLE repeat_customer_order_stats AS
WITH order_gaps AS (
  SELECT 
    c.customer_unique_id,
    o.order_id,
    o.purchase_time,
    LAG(o.purchase_time) OVER (
      PARTITION BY c.customer_unique_id 
      ORDER BY o.purchase_time
    ) AS prev_purchase_time
  FROM orders o
  JOIN customers c ON o.customer_id = c.customer_id
),

gap_summary AS (
  SELECT 
    customer_unique_id,
    DATEDIFF(purchase_time, prev_purchase_time) AS days_between_orders
  FROM order_gaps
  WHERE prev_purchase_time IS NOT NULL
),

customer_stats AS (
  SELECT 
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_spent
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  JOIN order_items oi ON o.order_id = oi.order_id
  GROUP BY c.customer_unique_id
)
/* As customers place more orders, the average time between their purchases decreases significantly.
Meaning loyal customers reorder faster. 
This trend will be valuable for retargeting and re-engagement strategies. */


# Loyalty by Zip code

DROP TABLE IF EXISTS zip_loyalty_summary;
CREATE TABLE zip_loyalty_summary AS
SELECT 
  base.customer_zip_code_prefix,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
  ROUND(100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS loyalty_percent
FROM (
  SELECT 
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    COUNT(DISTINCT o.order_id) AS order_count
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  GROUP BY c.customer_unique_id, c.customer_zip_code_prefix
) AS base
GROUP BY base.customer_zip_code_prefix
HAVING total_customers >= 10
ORDER BY loyalty_percent DESC;


# Loyalty by State

DROP TABLE IF EXISTS state_customer_loyalty;
CREATE TABLE state_customer_loyalty AS
SELECT 
  c.customer_state,
  COUNT(DISTINCT c.customer_unique_id) AS total_customers,
  SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
  ROUND(100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(DISTINCT c.customer_unique_id), 2) AS loyalty_percent
FROM (
  SELECT 
    c.customer_unique_id,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS order_count
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  GROUP BY c.customer_unique_id, c.customer_state
) AS c
GROUP BY c.customer_state;

# Create repeat customer review scores per state

DROP TABLE IF EXISTS state_repeat_review_scores;
CREATE TABLE state_repeat_review_scores AS
SELECT 
  c.customer_state,
  ROUND(AVG(r.review_score), 2) AS avg_review_score_repeat_customers
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_reviews r ON o.order_id = r.order_id
WHERE c.customer_unique_id IN (
  SELECT customer_unique_id
  FROM (
    SELECT customer_unique_id
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY customer_unique_id
    HAVING COUNT(DISTINCT o.order_id) > 1
  ) AS repeaters
)
GROUP BY c.customer_state;

# Final joined result for state loyalty

DROP TABLE IF EXISTS state_loyalty_review_summary;
CREATE TABLE state_loyalty_review_summary AS
SELECT 
  l.customer_state,
  l.total_customers,
  l.repeat_customers,
  l.loyalty_percent,
  r.avg_review_score_repeat_customers
FROM state_customer_loyalty l
LEFT JOIN state_repeat_review_scores r 
  ON l.customer_state = r.customer_state
ORDER BY l.loyalty_percent DESC;

/* Observations: Overall loyalty is low. No strong correlation between loyalty % and satisfaction. 
Perhaps target states like RN, SE, PB for growth - happy customers but weak loyalty. 
Double down on RJ and SP - both are large enough to matter and have average scores to support retention efforts. */


# Products count in single-order customers orders

DROP TABLE IF EXISTS one_time_customer_product_distribution;
CREATE TABLE one_time_customer_product_distribution AS
SELECT 
  products_in_order,
  COUNT(*) AS customer_count
FROM (
  SELECT 
    c.customer_unique_id,
    COUNT(*) AS products_in_order
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  JOIN order_items oi ON o.order_id = oi.order_id
  WHERE c.customer_unique_id IN (
    SELECT customer_unique_id
    FROM customers c2
    JOIN orders o2 ON c2.customer_id = o2.customer_id
    GROUP BY c2.customer_unique_id
    HAVING COUNT(DISTINCT o2.order_id) = 1
  )
  GROUP BY c.customer_unique_id
) AS product_counts
GROUP BY products_in_order
ORDER BY products_in_order;

# So 89% of customers who ordered just one time only bought a single product. And they also never returned. 
 
/* -------------------------------------
 CHAPTER 6: PRODUCT ANALYSIS
-- -----------------------------------*/

# Most sold products

DROP TABLE IF EXISTS most_sold_products;
CREATE TABLE most_sold_products AS
SELECT 
  oi.product_id,
  t.product_category_name_english AS category_name,
  COUNT(*) AS total_units_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_name_translation t 
  ON p.product_category_name = t.product_category_name
GROUP BY oi.product_id, t.product_category_name_english
ORDER BY total_units_sold DESC;

/* average price and freight value by category
-- since some orders have more than one item, first I am going to create with single product orders only. */

DROP TABLE IF EXISTS single_item_orders;
CREATE TABLE single_item_orders AS
SELECT 
    oi.order_id,
    oi.product_id,
    p.product_category_name,
    t.product_category_name_english,
    oi.price,
    oi.freight_value
FROM order_items oi
JOIN (
    SELECT order_id
    FROM order_items
    GROUP BY order_id
    HAVING COUNT(*) = 1
) single_orders ON oi.order_id = single_orders.order_id
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_name_translation t 
    ON p.product_category_name = t.product_category_name
WHERE o.order_status IN ('delivered', 'shipped');

# average price and freight value by category for single product orders

DROP TABLE IF EXISTS avg_price_freight_by_category;
CREATE TABLE avg_price_freight_by_category AS
SELECT 
  product_category_name_english AS category_name,
  ROUND(AVG(price), 2) AS avg_price,
  ROUND(AVG(freight_value), 2) AS avg_freight
FROM single_item_orders
GROUP BY product_category_name_english
ORDER BY avg_freight DESC;

# Perhaps treat this as a baseline since freight is strongly influenced by distance, which varies by customer location

# I am going to analyse the same for the State which has the most orders. This will give a better benchmark.

SELECT 
  c.customer_state,
  COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_orders DESC;

# Its SP

DROP TABLE IF EXISTS avg_price_freight_by_category_sp;
CREATE TABLE avg_price_freight_by_category_sp AS
SELECT 
  sio.product_category_name_english AS category_name,
  ROUND(AVG(sio.price), 2) AS avg_price,
  ROUND(AVG(sio.freight_value), 2) AS avg_freight
FROM single_item_orders sio
JOIN orders o ON sio.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_state = 'SP'
GROUP BY sio.product_category_name_english
ORDER BY avg_freight DESC;


# Checking order cancellations by product category, along with avg price and avg freight

DROP TABLE IF EXISTS cancelled_orders_by_category;
CREATE TABLE cancelled_orders_by_category AS
SELECT 
  t.product_category_name_english AS category_name,
  COUNT(*) AS cancelled_order_count,
  ROUND(AVG(oi.price), 2) AS avg_price,
  ROUND(AVG(oi.freight_value), 2) AS avg_freight
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_name_translation t 
  ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'canceled'
GROUP BY t.product_category_name_english
ORDER BY cancelled_order_count DESC;

# This makes me wonder, how many repeat customers cancelled an order

SELECT 
  COUNT(DISTINCT c.customer_unique_id) AS repeat_customers_with_cancellations
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE c.customer_unique_id IN (
  SELECT customer_unique_id
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  GROUP BY customer_unique_id
  HAVING COUNT(DISTINCT o.order_id) > 1
)
AND o.order_status = 'canceled';

# 82 - not that much considering theres almost 6000 repeat orders

# Check cancelled orders by ZIP code

DROP TABLE IF EXISTS cancelled_orders_by_zip;
CREATE TABLE cancelled_orders_by_zip AS
SELECT 
  c.customer_zip_code_prefix,
  COUNT(*) AS cancelled_order_count
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'canceled'
GROUP BY c.customer_zip_code_prefix
ORDER BY cancelled_order_count DESC;


# Lets check cancellation as a % of orders per each state

DROP TABLE IF EXISTS cancelled_orders_by_state;
CREATE TABLE cancelled_orders_by_state AS
SELECT 
  c.customer_state,
  COUNT(*) AS cancelled_order_count,
  (
    SELECT COUNT(*) 
    FROM orders o2 
    JOIN customers c2 ON o2.customer_id = c2.customer_id 
    WHERE c2.customer_state = c.customer_state
  ) AS total_orders,
  ROUND(
    100.0 * COUNT(*) / (
      SELECT COUNT(*) 
      FROM orders o2 
      JOIN customers c2 ON o2.customer_id = c2.customer_id 
      WHERE c2.customer_state = c.customer_state
    ), 
    2
  ) AS cancellation_rate_percent
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'canceled'
GROUP BY c.customer_state
ORDER BY cancellation_rate_percent DESC;

# Interesting; cancellations higher in North, lowest in Southeast despite volume.

