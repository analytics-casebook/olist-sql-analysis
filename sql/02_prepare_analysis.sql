-- OLIST: ANALYSIS COPY FOR JANUARY 2017 THROUGH AUGUST 2018
-- MySQL 8 / MySQL Workbench.
--
-- HOW TO RUN:
-- 1. Double-click your ORIGINAL Olist database in Workbench so it is the
--    default schema (for example, olist_fast).
-- 2. Open this file and run the ENTIRE script once, from the top.
-- 3. Refresh SCHEMAS, then double-click olist_analysis for future query tabs.
--
-- Creates a separate database with the same nine table names.
-- The source database is read only by this script.
-- The database olist_analysis must not already exist. Stop on any error;
-- do not rerun against an existing or partially created analysis database.
--
-- Inclusion rule:
--   order_purchase_timestamp >= '2017-01-01'
--   order_purchase_timestamp <  '2018-09-01'
-- The exclusive end includes every time on 31 August 2018.
-- All order statuses are retained.
-- Items, payments and reviews follow their order_id, regardless of their
-- own dates. Deliveries or reviews after August 2018 are retained if their
-- order was purchased in the selected period.
-- Customers, products, sellers and reference rows follow those retained orders.
-- This selects recorded data; it does not establish complete market coverage.

SELECT DATABASE() AS source_database;

CREATE DATABASE `olist_analysis`
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- Keep the ORIGINAL database selected until the final USE statement.
-- LIKE copies the source columns and indexes.

CREATE TABLE `olist_analysis`.`orders` LIKE `orders`;

INSERT INTO `olist_analysis`.`orders`
SELECT o.*
FROM `orders` AS o
WHERE o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01';


CREATE TABLE `olist_analysis`.`customers` LIKE `customers`;

INSERT INTO `olist_analysis`.`customers`
SELECT c.*
FROM `customers` AS c
WHERE EXISTS (
    SELECT 1
    FROM `olist_analysis`.`orders` AS o
    WHERE o.customer_id = c.customer_id
);


CREATE TABLE `olist_analysis`.`payments` LIKE `payments`;

INSERT INTO `olist_analysis`.`payments`
SELECT p.*
FROM `payments` AS p
WHERE EXISTS (
    SELECT 1
    FROM `olist_analysis`.`orders` AS o
    WHERE o.order_id = p.order_id
);


CREATE TABLE `olist_analysis`.`order_items` LIKE `order_items`;

INSERT INTO `olist_analysis`.`order_items`
SELECT i.*
FROM `order_items` AS i
WHERE EXISTS (
    SELECT 1
    FROM `olist_analysis`.`orders` AS o
    WHERE o.order_id = i.order_id
);


CREATE TABLE `olist_analysis`.`reviews` LIKE `reviews`;

INSERT INTO `olist_analysis`.`reviews`
SELECT r.*
FROM `reviews` AS r
WHERE EXISTS (
    SELECT 1
    FROM `olist_analysis`.`orders` AS o
    WHERE o.order_id = r.order_id
);


CREATE TABLE `olist_analysis`.`products` LIKE `products`;

INSERT INTO `olist_analysis`.`products`
SELECT p.*
FROM `products` AS p
WHERE EXISTS (
    SELECT 1
    FROM `olist_analysis`.`order_items` AS i
    WHERE i.product_id = p.product_id
);


CREATE TABLE `olist_analysis`.`sellers` LIKE `sellers`;

INSERT INTO `olist_analysis`.`sellers`
SELECT s.*
FROM `sellers` AS s
WHERE EXISTS (
    SELECT 1
    FROM `olist_analysis`.`order_items` AS i
    WHERE i.seller_id = s.seller_id
);


CREATE TABLE `olist_analysis`.`category_translation` LIKE `category_translation`;

INSERT INTO `olist_analysis`.`category_translation`
SELECT t.*
FROM `category_translation` AS t
WHERE EXISTS (
    SELECT 1
    FROM `olist_analysis`.`products` AS p
    WHERE p.product_category_name = t.product_category_name
);


CREATE TABLE `olist_analysis`.`geolocation` LIKE `geolocation`;

-- UNION deduplicates the retained ZIP prefixes, so the join does not
-- multiply geolocation rows. Original coordinate rows are preserved.
INSERT INTO `olist_analysis`.`geolocation`
SELECT g.*
FROM `geolocation` AS g
JOIN (
    SELECT customer_zip_code_prefix AS zip_code_prefix
    FROM `olist_analysis`.`customers`
    WHERE customer_zip_code_prefix IS NOT NULL

    UNION

    SELECT seller_zip_code_prefix AS zip_code_prefix
    FROM `olist_analysis`.`sellers`
    WHERE seller_zip_code_prefix IS NOT NULL
) AS retained_zip
    ON retained_zip.zip_code_prefix = g.geolocation_zip_code_prefix;


-- Switch this query tab to the filtered database.
USE `olist_analysis`;

-- Verification: orders_outside_period must be 0.
-- The standard Olist data should have orders in all 20 selected months.
-- First/last recorded purchase timestamps need not equal the date limits.
SELECT
    COUNT(*) AS retained_orders,
    MIN(order_purchase_timestamp) AS first_recorded_purchase,
    MAX(order_purchase_timestamp) AS last_recorded_purchase,
    COUNT(DISTINCT EXTRACT(YEAR_MONTH FROM order_purchase_timestamp))
        AS months_with_orders,
    COALESCE(SUM(
        order_purchase_timestamp IS NULL
        OR order_purchase_timestamp < '2017-01-01'
        OR order_purchase_timestamp >= '2018-09-01'
    ), 0) AS orders_outside_period
FROM `orders`;

SELECT
    YEAR(order_purchase_timestamp) AS purchase_year,
    MONTH(order_purchase_timestamp) AS purchase_month,
    COUNT(*) AS recorded_orders
FROM `orders`
GROUP BY purchase_year, purchase_month
ORDER BY purchase_year, purchase_month;

