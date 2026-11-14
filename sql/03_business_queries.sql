-- Olist E-commerce Analysis : January 2017 through August 2018

-- Requires MySQL 8.0+.
-- Import the raw Olist data, then run 02_prepare_analysis.sql.
-- The analysis database contains purchases from January 2017 through
-- August 2018, retaining all order statuses.

USE olist_analysis;

-- Questions:
-- A. Revenue and Growth
-- 1. What is monthly revenue over time?
-- 2. What is month-over-month revenue growth?
-- 3. What are total orders and average order value for the analysis period?
-- 4. Which months show the strongest and weakest business performance?
-- B. Product/Category Performance
-- 5. Which product categories generate the most revenue?
-- 6. Which categories have the highest order volume?
-- 7. Are the highest-volume categories also the highest-revenue categories?
-- 8. Which categories appear most important for management attention based on both scale and performance?
-- C. Delivery Performance
-- 9. What is the average delivery time?
-- 10. What percentage of delivered orders are late relative to the promised/estimated delivery date?


-- Answers:

-- A. Revenue and Growth
-- Q1. What is monthly revenue over time?
SELECT 	YEAR(o.order_purchase_timestamp) AS year, MONTH(o.order_purchase_timestamp) AS month,
        SUM(p.payment_value) AS gross_consumer_payment_value
FROM 	orders o LEFT JOIN payments p
			   ON o.order_id=p.order_id
GROUP BY year, month
ORDER BY year, month;

-- Note 1: This is not Olist's actual recognized revenue, as the gross consumer payment value is including shipping charges, 
-- from which Olist may or may not take a cut. Current data is insufficient to tell the exact revenue.

-- Note 2: This calculation uses all order statuses including cancelled orders (if any). Refunds cannot be determined from the data.


-- Q2. What is month-over-month revenue growth?

WITH RECURSIVE cte_1 AS	(SELECT 	YEAR(o.order_purchase_timestamp) AS year, MONTH(o.order_purchase_timestamp) AS month,
									SUM(p.payment_value) AS gross_consumer_payment_value
						 FROM 		orders o LEFT JOIN payments p
									ON o.order_id=p.order_id
						 GROUP BY year, month),
                 
			   months AS	(SELECT CAST(DATE_FORMAT(MIN(order_purchase_timestamp),'%y-%m-01') AS DATE) AS month_start
						 FROM orders
                         UNION ALL
                         SELECT month_start+ INTERVAL 1 MONTH
                         FROM months
                         WHERE month_start< (SELECT CAST(DATE_FORMAT(Max(order_purchase_timestamp),'%y-%m-01') AS DATE)
											FROM orders)),

				months_sep	AS (SELECT YEAR(month_start) AS year, MONTH(month_start) AS month
								FROM months),
                                
				cte_2 AS	(SELECT	ms.year, ms.month, cte_1.gross_consumer_payment_value, 
									cte_1.gross_consumer_payment_value AS gross_consumer_payment_value1, 
									LAG(cte_1.gross_consumer_payment_value) OVER(ORDER BY ms.year, ms.month) AS prev_month_gcpv,
									cte_1.gross_consumer_payment_value-LAG(cte_1.gross_consumer_payment_value) OVER(ORDER BY ms.year, ms.month) AS gross_consumer_payment_value_diff, 
									((cte_1.gross_consumer_payment_value)-LAG(cte_1.gross_consumer_payment_value) OVER(ORDER BY ms.year, ms.month))/LAG(cte_1.gross_consumer_payment_value) OVER(ORDER BY ms.year, ms.month)*100 AS mom_growth_pct
							FROM 	months_sep ms LEFT JOIN cte_1
									ON ms.year=cte_1.year AND ms.month=cte_1.month)

SELECT year, month, gross_consumer_payment_value1 AS gross_payments, ROUND(mom_growth_pct, 2) AS mom_growth_pct
FROM cte_2
ORDER BY year, month;


-- 3. What are total orders and average order value for the analysis period?
WITH cte1 AS 	(SELECT 	order_id, SUM(price) AS total_price
			 	 FROM 	order_items
				 GROUP BY order_id),

	 cte2 AS 	(SELECT	o.order_id, cte1.total_price
				 FROM 	orders o LEFT JOIN cte1
						ON o.order_id=cte1.order_id)
                        
SELECT COUNT(order_id) AS total_orders, ROUND(AVG(total_price),2) AS AOV
FROM cte2;

-- Note 1: This is AOV excluding shipping costs. For including shipping costs,
-- we would calculate the gross-payment based AOV as 
-- average payment value per order which is total payments value divided by total number of orders.

-- Note 2: This AOV is calculated using only initially placed orders
-- that have available corresponding records in the order_items table,
-- irrespective of their final statuses (delivered, canceled, etc.).

-- Another AOV KPI could be calculating AOV from initially placed orders that have available corresponding
-- records in payments table, and it would be inclusive of shipping charges and wouldn't depend on missing
-- orders in order_items table.

-- 4. Which months show the strongest and weakest business performance?
WITH RECURSIVE cte_1 AS	(SELECT 	YEAR(o.order_purchase_timestamp) AS year, MONTH(o.order_purchase_timestamp) AS month,
									SUM(p.payment_value) AS gross_consumer_payment_value
						 FROM 		orders o LEFT JOIN payments p
									ON o.order_id=p.order_id
						 GROUP BY year, month),
                 
			   months AS	(SELECT CAST(DATE_FORMAT(MIN(order_purchase_timestamp),'%y-%m-01') AS DATE) AS month_start
						 FROM orders
                         UNION ALL
                         SELECT month_start+ INTERVAL 1 MONTH
                         FROM months
                         WHERE month_start< (SELECT CAST(DATE_FORMAT(Max(order_purchase_timestamp),'%y-%m-01') AS DATE)
											FROM orders)),

				months_sep	AS (SELECT YEAR(month_start) AS year, MONTH(month_start) AS month
								FROM months),
                                
				cte_2 AS	(SELECT	ms.year, ms.month, cte_1.gross_consumer_payment_value, 
									LAG(cte_1.gross_consumer_payment_value) OVER(ORDER BY ms.year, ms.month) AS prev_month_gcpv,
									cte_1.gross_consumer_payment_value-LAG(cte_1.gross_consumer_payment_value) OVER(ORDER BY ms.year, ms.month) AS gross_consumer_payment_value_diff, 
									(cte_1.gross_consumer_payment_value-LAG(cte_1.gross_consumer_payment_value) OVER(ORDER BY ms.year, ms.month))/LAG(cte_1.gross_consumer_payment_value) OVER(ORDER BY ms.year, ms.month)*100 AS mom_growth_pct
							FROM 	months_sep ms LEFT JOIN cte_1
									ON ms.year=cte_1.year AND ms.month=cte_1.month),

				cte_3 AS	(SELECT year, month, gross_consumer_payment_value AS gross_payments, ROUND(mom_growth_pct, 2) AS mom_growth_pct
							FROM cte_2)
                            
SELECT year, month, gross_payments AS metric_value, 'max_gross_payment' AS type
FROM cte_3
WHERE gross_payments=(SELECT MAX(gross_payments) FROM cte_3)

UNION ALL

SELECT year, month, mom_growth_pct AS metric_value, 'max_mom_growth_pct' AS type
FROM cte_3
WHERE mom_growth_pct=(SELECT MAX(mom_growth_pct) FROM cte_3)

UNION ALL

SELECT year, month, gross_payments AS metric_value, 'min_gross_payment' AS type
FROM cte_3
WHERE gross_payments=(SELECT MIN(gross_payments) FROM cte_3)

UNION ALL

SELECT year, month, mom_growth_pct AS metric_value, 'min_mom_growth_pct' AS type
FROM cte_3
WHERE mom_growth_pct=(SELECT MIN(mom_growth_pct) FROM cte_3);

-- B. Product/Category Performance
-- 5. Which product categories generate the most revenue?
SELECT	p.product_category_name, SUM(oi.price) AS total_price
FROM	order_items oi LEFT JOIN products p
		ON oi.product_id=p.product_id
GROUP BY product_category_name
ORDER BY total_price DESC;

-- 6. Which categories have the highest order volume?
SELECT 	p.product_category_name, COUNT(DISTINCT order_id) AS num_orders
FROM 	order_items oi LEFT JOIN products p
		ON oi.product_id = p.product_id
GROUP BY product_category_name
ORDER BY num_orders DESC;

-- 7. Are the highest-volume categories also the highest-revenue categories?
WITH 	highest_rev_catg	AS	(SELECT	p.product_category_name, SUM(oi.price) AS total_price
								 FROM	order_items oi LEFT JOIN products p
										ON oi.product_id=p.product_id
								 GROUP BY product_category_name
                                 ORDER BY total_price DESC),

		highest_vol_catg	AS	(SELECT 	p.product_category_name, COUNT(DISTINCT order_id) AS num_orders
								 FROM 		order_items oi LEFT JOIN products p
											ON oi.product_id = p.product_id
								 GROUP BY 	product_category_name
								 ORDER BY	num_orders DESC),
		
        highest_rev_ntile10	AS	(SELECT	product_category_name, total_price, NTILE(10) OVER(ORDER BY total_price DESC) AS n_tile
								 FROM	highest_rev_catg),
                                
		highest_rev_top_10_pct	AS	(SELECT	product_category_name, total_price
									 FROM	highest_rev_ntile10
                                     WHERE 	n_tile=1),
                                     
        highest_vol_ntile10	AS	(SELECT	product_category_name, num_orders, NTILE(10) OVER(ORDER BY num_orders DESC) AS n_tile
								 FROM	highest_vol_catg),
                                 
		highest_vol_top_10_pct	AS	(SELECT	product_category_name, num_orders
									 FROM	highest_vol_ntile10
                                     WHERE 	n_tile=1)
        
SELECT	hr10p.product_category_name, hr10p.total_price AS revenue, hv10p.num_orders
FROM	highest_rev_top_10_pct hr10p INNER JOIN highest_vol_top_10_pct hv10p
		ON hr10p.product_category_name=hv10p.product_category_name;
        
-- 7 out of top 8 product categories by revenue and num_orders are common / overlap.

SELECT (7/8)*100;

-- So, 87.5% of top 10% highest revenue product categories are also in top 10% of highest order volume categories.

-- Conclusion :
-- Seven of the eight categories in the top revenue decile also appear
-- in the top order-volume decile: an overlap of 87.5%.
-- This indicates substantial overlap among the leading categories.

-- 8. Which categories appear most important for management attention based on both scale and performance?
WITH cte_total_price AS 		(SELECT	p.product_category_name, SUM(oi.price) AS total_price
								 FROM	order_items oi LEFT JOIN products p
										ON oi.product_id=p.product_id
								 GROUP BY product_category_name),
                
     cte_total_price_ntile AS	(SELECT product_category_name AS top20_pct_products_by_price, 
										total_price,
                                        NTILE(5) OVER(ORDER BY total_price DESC) AS nt,
                                        RANK() OVER(ORDER BY total_price DESC) AS revenue_rank
								 FROM 	cte_total_price),
                 
	 top20_pct_products_by_price_table AS 	(SELECT top20_pct_products_by_price, 
													total_price,
                                                    revenue_rank
											 FROM cte_total_price_ntile
											 WHERE nt=1),
                                             
	 cte_orders AS 				(SELECT 	p.product_category_name, COUNT(DISTINCT order_id) AS num_orders
								 FROM 		order_items oi LEFT JOIN products p
											ON oi.product_id = p.product_id
								 GROUP BY 	product_category_name),

     cte_orders_ntile AS		(SELECT product_category_name AS top20_pct_orders, 
										num_orders,
                                        NTILE(5) OVER(ORDER BY num_orders DESC) AS nt2,
                                        RANK() OVER(ORDER BY num_orders DESC) AS order_rank
								 FROM 	cte_orders),

	 top20_pct_orders_table AS 	(SELECT top20_pct_orders,
										num_orders,
                                        order_rank
								 FROM 	cte_orders_ntile
								 WHERE nt2=1)

SELECT 	t1.top20_pct_products_by_price AS common_categories_in_top_20_pct_revenue_and_ordersnum, 
		t1.total_price AS revenue,
		t1.revenue_rank,
        t2.num_orders,
        t2.order_rank
FROM 	top20_pct_products_by_price_table t1 INNER JOIN top20_pct_orders_table t2
		ON t1.top20_pct_products_by_price=t2.top20_pct_orders
ORDER BY revenue DESC;

-- Categories most important for management attention based on both scale and performance:
-- beleza_saude, relogios_presentes, cama_mesa_banho, esporte_lazer, 
-- informatica_acessorios, moveis_decoracao, cool_stuff, utilidades_domesticas,
-- automotivo, ferramentas_jardim, brinquedos, bebes, perfumaria, telefonia.

        
-- C. Delivery Performance
-- 9. What is the average delivery time?
SELECT 	AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)) AS avg_delivery_time_in_days
FROM 	orders;

-- 10. What percentage of delivered orders are late relative to the promised/estimated delivery date?
WITH delv_orders AS 	(SELECT 	*
						 FROM	 	orders
						 WHERE 		order_status='delivered'),

	 late_orders AS 	(SELECT		COUNT(order_id) AS total_delivered_orders, 
									(SELECT	COUNT(order_id)
									 FROM 	delv_orders
									 WHERE 	DATE(order_estimated_delivery_date)<DATE(order_delivered_customer_date)) AS late_orders
									 FROM	delv_orders)
                                     
SELECT 	total_delivered_orders, late_orders,
		ROUND((late_orders/total_delivered_orders)*100,2) AS pct_late_orders
FROM 	late_orders;

-- Note: The calculated 6.79% represents the minimum
-- confirmed late-delivery rate among all delivered orders.
-- Orders with missing delivery dates cannot be classified
-- and could increase the actual late-delivery rate.