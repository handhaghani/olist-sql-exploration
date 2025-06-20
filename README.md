# olist-sql-exploration
Structured SQL analysis of the OLIST e-commerce dataset, covering revenue trends, customer behavior, shipping logistics, payment methods, and product performance. This project simulates real-world business analytics use cases using SQL queries on a cleaned dataset.

📊 OLIST SQL Data Exploration - README

Overview
This project documents a SQL-driven data exploration of the OLIST e-commerce dataset. The data was preprocessed and cleaned using Python, and then analyzed using SQL across various thematic areas—sales, payments, shipping, customer behavior, and products. The objective is to uncover business insights that support operational, financial, and customer-centric decision-making. The analysis also includes a Python notebook that performs text mining on customer reviews to identify word patterns across satisfaction levels.

💰 Chapter 1: Sales / Revenue Analysis
This chapter focuses on high-level revenue trends, regional sales distribution, and seller performance.
* monthly_orders_revenue_summary: Summarizes monthly total revenue, number of orders, and average revenue per order.
* monthly_category_revenue: Tracks how different product categories contribute to revenue over time.
* category_sales_summary: Shows total sales metrics per category.
* state_city_revenue: Breaks down revenue by state and city to identify regional hotspots.
* state_revenue_summary: Aggregates revenue performance at the state level.
* seller_total_revenue: Calculates total earnings per seller.
* seller_revenue_review_summary: Combines seller revenue metrics with their average review ratings.

🔍 Chapter 2: Payments Analysis
These queries examine customer payment behavior and its financial impact.
* payment_type_distribution: Analyzes frequency, revenue share, and popularity of different payment types.
* installment_distribution: Shows installment usage trends and distribution across completed orders.
* high_installment_revenue_share: Identifies revenue dependency on high-installment payments.
* state_payment_behavior: Examines regional variations in payment and installment preferences.

🚚 Chapter 3: Freight & Delivery Analysis
Evaluates shipping costs, delivery performance, and freight efficiency across the platform.
* order_freight_total: Lists total freight cost, actual weight, and dimensional weight per order.
* state_freight_bucket_summary: Groups states into freight cost bands for cost profiling.
* order_value_vs_freight: Compares total order value to shipping cost to flag unprofitable orders.
* freight_ratio_by_region / freight_ratio_by_state: Tracks shipping efficiency via cost ratios.
* freight_by_state: Freight cost vs delivery time on a state level.
* delivery_time_distribution: Distribution of delivery speed across predefined time bands.
* delivery_band_by_state: State-wise delivery time band performance.
* approval_to_shipping_bands: Time from order approval to shipping, used to gauge seller responsiveness.

😊 Chapter 4: Customer Experience & Feedback
Assesses customer sentiment, review scores, and related drivers like delivery speed.
* category_review_summary: Average review scores and counts by product category.
* seller_revenue_review_summary: Review performance and revenue metrics per seller.
* review_text_by_score: Stores raw review text, enabling sentiment or keyword analysis.
* delivery_time_vs_review_score: Tests the correlation between delivery performance and customer satisfaction.
* state_review_summary: Highlights best- and worst-rated states/cities in customer reviews.

👤 Chapter 5: Customer Behavior & Segmentation
Provides insight into user engagement, retention, and purchasing patterns.
* customer_order_frequency: Groups customers by how often they make purchases.
* customer_type_review_summary: Review performance by one-time vs repeat buyers.
* repeat_customer_order_stats: Analyzes time intervals between repeat purchases.
* zip_loyalty_summary / state_customer_loyalty: Geographic view of customer loyalty levels.
* state_repeat_review_scores: Review scores of repeat customers by state.
* state_loyalty_review_summary: Combines loyalty % with average review scores by region.
* one_time_customer_product_distribution: Analyzes order complexity for single-time buyers.

📦 Chapter 6: Product Analysis
Focuses on product-level performance, freight patterns, and cancellation trends.
* most_sold_products: Top-selling products by volume.
* single_item_orders: Frequency of single-item orders.
* avg_price_freight_by_category: Category-level analysis of average product price and freight cost.
* avg_price_freight_by_category_sp: Same as above, filtered for São Paulo.
* cancelled_orders_by_category / cancelled_orders_by_zip / cancelled_orders_by_state: Cancellation frequency and rates by category, zip, and state.

🛠️ Tools Used
* Python: Initial data cleaning and preprocessing.
* Jupyter Notebook: Used for word frequency analysis on review text data.
* SQL: Analytical querying and data aggregation.
* OLIST Dataset: Real-world data from a Brazilian marketplace, featuring sales, payments, reviews, logistics, and customer behavior.

🎯 Objective
This project simulates a business analyst’s approach to understanding marketplace performance using structured SQL queries. It is organized into thematic chapters to support stakeholder reporting, operational efficiency, marketing insights, and customer satisfaction initiatives.
