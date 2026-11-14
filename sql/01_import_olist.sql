-- Olist nine-CSV loader for MySQL 8 / MySQL Workbench on Windows.
-- Download and extract all nine source CSVs into C:/olist/.
-- Replace that generic folder path if your files are stored elsewhere.
-- Workbench connection: Advanced > Others > OPT_LOCAL_INFILE=1; then reconnect.
-- Use a trusted local MySQL server. Creates a new database: olist_bulk.
-- Run once; if that database already exists, stop and inspect before rerunning.
-- If import stops early, run SET GLOBAL local_infile = OFF;
-- See README.md for the complete execution order.

SET GLOBAL local_infile = ON;
CREATE DATABASE olist_bulk CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE olist_bulk;


CREATE TABLE `customers` (
    `customer_id` VARCHAR(32) NOT NULL,
    `customer_unique_id` VARCHAR(32) NULL,
    `customer_zip_code_prefix` VARCHAR(5) NULL,
    `customer_city` VARCHAR(120) NULL,
    `customer_state` VARCHAR(2) NULL,
    PRIMARY KEY (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Import olist_customers_dataset.csv
LOAD DATA LOCAL INFILE 'C:/olist/olist_customers_dataset.csv'
INTO TABLE `customers`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@c0, @c1, @c2, @c3, @c4)
SET
  `customer_id` = NULLIF(TRIM(TRAILING '\r' FROM @c0), ''),
  `customer_unique_id` = NULLIF(TRIM(TRAILING '\r' FROM @c1), ''),
  `customer_zip_code_prefix` = NULLIF(TRIM(TRAILING '\r' FROM @c2), ''),
  `customer_city` = NULLIF(TRIM(TRAILING '\r' FROM @c3), ''),
  `customer_state` = NULLIF(TRIM(TRAILING '\r' FROM @c4), '');

SELECT 'customers' AS imported_table, COUNT(*) AS rows_imported FROM `customers`;

CREATE TABLE `orders` (
    `order_id` VARCHAR(32) NOT NULL,
    `customer_id` VARCHAR(32) NULL,
    `order_status` VARCHAR(24) NULL,
    `order_purchase_timestamp` DATETIME NULL,
    `order_approved_at` DATETIME NULL,
    `order_delivered_carrier_date` DATETIME NULL,
    `order_delivered_customer_date` DATETIME NULL,
    `order_estimated_delivery_date` DATETIME NULL,
    PRIMARY KEY (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Import olist_orders_dataset.csv
LOAD DATA LOCAL INFILE 'C:/olist/olist_orders_dataset.csv'
INTO TABLE `orders`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@c0, @c1, @c2, @c3, @c4, @c5, @c6, @c7)
SET
  `order_id` = NULLIF(TRIM(TRAILING '\r' FROM @c0), ''),
  `customer_id` = NULLIF(TRIM(TRAILING '\r' FROM @c1), ''),
  `order_status` = NULLIF(TRIM(TRAILING '\r' FROM @c2), ''),
  `order_purchase_timestamp` = NULLIF(TRIM(TRAILING '\r' FROM @c3), ''),
  `order_approved_at` = NULLIF(TRIM(TRAILING '\r' FROM @c4), ''),
  `order_delivered_carrier_date` = NULLIF(TRIM(TRAILING '\r' FROM @c5), ''),
  `order_delivered_customer_date` = NULLIF(TRIM(TRAILING '\r' FROM @c6), ''),
  `order_estimated_delivery_date` = NULLIF(TRIM(TRAILING '\r' FROM @c7), '');

SELECT 'orders' AS imported_table, COUNT(*) AS rows_imported FROM `orders`;

CREATE TABLE `products` (
    `product_id` VARCHAR(32) NOT NULL,
    `product_category_name` VARCHAR(120) NULL,
    `product_name_lenght` INT NULL,
    `product_description_lenght` INT NULL,
    `product_photos_qty` INT NULL,
    `product_weight_g` INT NULL,
    `product_length_cm` INT NULL,
    `product_height_cm` INT NULL,
    `product_width_cm` INT NULL,
    PRIMARY KEY (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Import olist_products_dataset.csv
LOAD DATA LOCAL INFILE 'C:/olist/olist_products_dataset.csv'
INTO TABLE `products`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@c0, @c1, @c2, @c3, @c4, @c5, @c6, @c7, @c8)
SET
  `product_id` = NULLIF(TRIM(TRAILING '\r' FROM @c0), ''),
  `product_category_name` = NULLIF(TRIM(TRAILING '\r' FROM @c1), ''),
  `product_name_lenght` = NULLIF(TRIM(TRAILING '\r' FROM @c2), ''),
  `product_description_lenght` = NULLIF(TRIM(TRAILING '\r' FROM @c3), ''),
  `product_photos_qty` = NULLIF(TRIM(TRAILING '\r' FROM @c4), ''),
  `product_weight_g` = NULLIF(TRIM(TRAILING '\r' FROM @c5), ''),
  `product_length_cm` = NULLIF(TRIM(TRAILING '\r' FROM @c6), ''),
  `product_height_cm` = NULLIF(TRIM(TRAILING '\r' FROM @c7), ''),
  `product_width_cm` = NULLIF(TRIM(TRAILING '\r' FROM @c8), '');

SELECT 'products' AS imported_table, COUNT(*) AS rows_imported FROM `products`;

CREATE TABLE `sellers` (
    `seller_id` VARCHAR(32) NOT NULL,
    `seller_zip_code_prefix` VARCHAR(5) NULL,
    `seller_city` VARCHAR(120) NULL,
    `seller_state` VARCHAR(2) NULL,
    PRIMARY KEY (`seller_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Import olist_sellers_dataset.csv
LOAD DATA LOCAL INFILE 'C:/olist/olist_sellers_dataset.csv'
INTO TABLE `sellers`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@c0, @c1, @c2, @c3)
SET
  `seller_id` = NULLIF(TRIM(TRAILING '\r' FROM @c0), ''),
  `seller_zip_code_prefix` = NULLIF(TRIM(TRAILING '\r' FROM @c1), ''),
  `seller_city` = NULLIF(TRIM(TRAILING '\r' FROM @c2), ''),
  `seller_state` = NULLIF(TRIM(TRAILING '\r' FROM @c3), '');

SELECT 'sellers' AS imported_table, COUNT(*) AS rows_imported FROM `sellers`;

CREATE TABLE `order_items` (
    `order_id` VARCHAR(32) NOT NULL,
    `order_item_id` INT NOT NULL,
    `product_id` VARCHAR(32) NULL,
    `seller_id` VARCHAR(32) NULL,
    `shipping_limit_date` DATETIME NULL,
    `price` DECIMAL(12,2) NULL,
    `freight_value` DECIMAL(12,2) NULL,
    PRIMARY KEY (`order_id`, `order_item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Import olist_order_items_dataset.csv
LOAD DATA LOCAL INFILE 'C:/olist/olist_order_items_dataset.csv'
INTO TABLE `order_items`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@c0, @c1, @c2, @c3, @c4, @c5, @c6)
SET
  `order_id` = NULLIF(TRIM(TRAILING '\r' FROM @c0), ''),
  `order_item_id` = NULLIF(TRIM(TRAILING '\r' FROM @c1), ''),
  `product_id` = NULLIF(TRIM(TRAILING '\r' FROM @c2), ''),
  `seller_id` = NULLIF(TRIM(TRAILING '\r' FROM @c3), ''),
  `shipping_limit_date` = NULLIF(TRIM(TRAILING '\r' FROM @c4), ''),
  `price` = NULLIF(TRIM(TRAILING '\r' FROM @c5), ''),
  `freight_value` = NULLIF(TRIM(TRAILING '\r' FROM @c6), '');

SELECT 'order_items' AS imported_table, COUNT(*) AS rows_imported FROM `order_items`;

CREATE TABLE `payments` (
    `order_id` VARCHAR(32) NOT NULL,
    `payment_sequential` INT NOT NULL,
    `payment_type` VARCHAR(30) NULL,
    `payment_installments` INT NULL,
    `payment_value` DECIMAL(12,2) NULL,
    PRIMARY KEY (`order_id`, `payment_sequential`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Import olist_order_payments_dataset.csv
LOAD DATA LOCAL INFILE 'C:/olist/olist_order_payments_dataset.csv'
INTO TABLE `payments`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@c0, @c1, @c2, @c3, @c4)
SET
  `order_id` = NULLIF(TRIM(TRAILING '\r' FROM @c0), ''),
  `payment_sequential` = NULLIF(TRIM(TRAILING '\r' FROM @c1), ''),
  `payment_type` = NULLIF(TRIM(TRAILING '\r' FROM @c2), ''),
  `payment_installments` = NULLIF(TRIM(TRAILING '\r' FROM @c3), ''),
  `payment_value` = NULLIF(TRIM(TRAILING '\r' FROM @c4), '');

SELECT 'payments' AS imported_table, COUNT(*) AS rows_imported FROM `payments`;

CREATE TABLE `reviews` (
    `review_id` VARCHAR(32) NULL,
    `order_id` VARCHAR(32) NULL,
    `review_score` INT NULL,
    `review_comment_title` TEXT NULL,
    `review_comment_message` TEXT NULL,
    `review_creation_date` DATETIME NULL,
    `review_answer_timestamp` DATETIME NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Import olist_order_reviews_dataset.csv
LOAD DATA LOCAL INFILE 'C:/olist/olist_order_reviews_dataset.csv'
INTO TABLE `reviews`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@c0, @c1, @c2, @c3, @c4, @c5, @c6)
SET
  `review_id` = NULLIF(TRIM(TRAILING '\r' FROM @c0), ''),
  `order_id` = NULLIF(TRIM(TRAILING '\r' FROM @c1), ''),
  `review_score` = NULLIF(TRIM(TRAILING '\r' FROM @c2), ''),
  `review_comment_title` = NULLIF(TRIM(TRAILING '\r' FROM @c3), ''),
  `review_comment_message` = NULLIF(TRIM(TRAILING '\r' FROM @c4), ''),
  `review_creation_date` = NULLIF(TRIM(TRAILING '\r' FROM @c5), ''),
  `review_answer_timestamp` = NULLIF(TRIM(TRAILING '\r' FROM @c6), '');

SELECT 'reviews' AS imported_table, COUNT(*) AS rows_imported FROM `reviews`;

CREATE TABLE `category_translation` (
    `product_category_name` VARCHAR(120) NOT NULL,
    `product_category_name_english` VARCHAR(120) NULL,
    PRIMARY KEY (`product_category_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Import product_category_name_translation.csv
LOAD DATA LOCAL INFILE 'C:/olist/product_category_name_translation.csv'
INTO TABLE `category_translation`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@c0, @c1)
SET
  `product_category_name` = NULLIF(TRIM(TRAILING '\r' FROM @c0), ''),
  `product_category_name_english` = NULLIF(TRIM(TRAILING '\r' FROM @c1), '');

SELECT 'category_translation' AS imported_table, COUNT(*) AS rows_imported FROM `category_translation`;

CREATE TABLE `geolocation` (
    `geolocation_zip_code_prefix` VARCHAR(5) NULL,
    `geolocation_lat` DOUBLE NULL,
    `geolocation_lng` DOUBLE NULL,
    `geolocation_city` VARCHAR(120) NULL,
    `geolocation_state` VARCHAR(2) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Import olist_geolocation_dataset.csv
LOAD DATA LOCAL INFILE 'C:/olist/olist_geolocation_dataset.csv'
INTO TABLE `geolocation`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@c0, @c1, @c2, @c3, @c4)
SET
  `geolocation_zip_code_prefix` = NULLIF(TRIM(TRAILING '\r' FROM @c0), ''),
  `geolocation_lat` = NULLIF(TRIM(TRAILING '\r' FROM @c1), ''),
  `geolocation_lng` = NULLIF(TRIM(TRAILING '\r' FROM @c2), ''),
  `geolocation_city` = NULLIF(TRIM(TRAILING '\r' FROM @c3), ''),
  `geolocation_state` = NULLIF(TRIM(TRAILING '\r' FROM @c4), '');

SELECT 'geolocation' AS imported_table, COUNT(*) AS rows_imported FROM `geolocation`;

-- Turn server-side local-loading capability OFF after import.
SET GLOBAL local_infile = OFF;
-- Disconnect this Workbench connection and remove OPT_LOCAL_INFILE=1 if no longer needed.
SELECT 'IMPORT FINISHED - check raw orders = 99441, then run 02_prepare_analysis.sql' AS next_step;
