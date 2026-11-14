# Olist E-commerce SQL Analysis

An analysis of customer payments, category sales and delivery performance using MySQL 8. The project answers ten business questions using SQL and documents the definitions behind each metric.

**Current milestone:** ten SQL business questions answered. Purchase period: **January 2017–August 2018**. The analysis retains **99,092 orders** across all order statuses.

The business queries were executed in MySQL 8.0.46 and their outputs cross-checked against the original source CSVs.



[View all question results and screenshots](screenshots/README.md)



## Main findings

|Metric|Result|
|-|-:|
|Recorded customer payments, including shipping|BRL 15,944,480.57|
|Merchandise sales value, excluding shipping|BRL 13,541,712.78|
|Merchandise average order value|BRL 137.68|
|Categories shared by the first revenue and order-volume deciles|7 of 8 — 87.5%|
|Categories shared by the first revenue and order-volume quintiles|14|
|Average purchase-to-delivery calendar days, where dates are available|12.48|
|Confirmed late deliveries among all delivered orders|6,531 / 96,211 — 6.79%|

November 2017 had the highest recorded monthly customer payments: **BRL 1,194,882.80**. The largest monthly increase was **110.78% in February 2017**; the largest decline was **26.49% in December 2017**.

The category overlap provides a practical shortlist for reviewing inventory and service capacity across the largest categories. Profit margins, stock availability and customer demand forecasts would be needed before deciding how much to invest in each category.

## Business questions

1. How do monthly customer payments change over time?
2. What is month-over-month payment growth?
3. How many orders were placed, and what is merchandise AOV?
4. Which months have the highest and lowest payments and MoM growth?
5. Which categories have the highest merchandise sales value?
6. Which categories have the highest distinct order volume?
7. How much do the leading sales and order-volume categories overlap?
8. Which categories rank highly on both sales value and order volume?
9. What is the average purchase-to-customer-delivery time?
10. What proportion of delivered orders are confirmed late?

## Files

|File or folder|Purpose|
|-|-|
|[sql/01\_import\_olist.sql](sql/01_import_olist.sql)|Create the source tables and import the nine original CSVs|
|[sql/02\_prepare\_analysis.sql](sql/02_prepare_analysis.sql)|Create the filtered `olist\_analysis` database|
|[sql/03\_business\_queries.sql](sql/03_business_queries.sql)|Ten business questions and SQL answers|
|[results/](results/)|Query outputs, available without running MySQL|

The source CSVs are downloaded separately. They are not required to read the findings and result files in this repository.

## Data and analysis scope

Source: [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), published by Olist on Kaggle. The included results use dataset version 2. Data attribution and source licensing information are available on that page.

Orders are included when `order\_purchase\_timestamp >= '2017-01-01' AND order\_purchase\_timestamp < '2018-09-01'`. Their related items, payments and reviews follow the retained order IDs. A delivery or review can occur after August 2018 and still belong to an included purchase. The setup script also retains the related customers, products, sellers, category translations and geolocation rows.

## Metric definitions and limitations

|Metric|Definition|
|-|-|
|Customer payments|Sum of recorded `payment\_value`, including shipping and all order statuses. This is not Olist's recognized company revenue; refunds cannot be determined from the available data.|
|Merchandise sales|Sum of `order\_items.price`, excluding shipping and retaining all scoped order statuses.|
|Merchandise AOV|Average item-price total per order among the **98,353 orders with item records**. The 739 orders without items are excluded from this average.|
|Category order volume|Distinct orders within each category. A multi-category order can count once in several categories.|
|Top decile / quintile|First `NTILE(10)` / `NTILE(5)` bucket over 74 category groups, including one unclassified group. Buckets contain 8 and 15 groups, respectively; the percentages are approximate.|
|Average delivery time|`AVG(DATEDIFF(customer\_delivery, purchase))`: calendar-day differences across 96,204 available date pairs, regardless of status. Includes one canceled order with a delivery timestamp.|
|Confirmed late rate|Actual delivery date after estimated delivery date, divided by all **96,211 delivered orders**. Eight lack actual delivery dates, so 6.79% is a minimum confirmed rate.|
|MoM growth|Change from the preceding calendar month's payment total. Missing totals remain NULL. A missing or zero prior total produces NULL growth in these MySQL SELECT queries.|

All 20 months in the selected window have recorded payments. Category prioritization uses sales and volume; profitability and causality are outside the analysis.

## How to reproduce

The supplied loader is written for **MySQL 8 and MySQL Workbench on Windows**. Other systems can use the same table definitions and adjust the CSV folder path.

1. Download and extract all nine source CSVs from the linked dataset. For the supplied import script, put them directly in `C:/olist/`, or replace every occurrence of that generic folder path in `sql/01\_import\_olist.sql` with your CSV folder.
2. Connect Workbench to a trusted local MySQL server. In the connection settings, open **Advanced > Others**, add `OPT\_LOCAL\_INFILE=1`, save, and reconnect. The loader uses `LOAD DATA LOCAL INFILE` and requires permission to temporarily change `local\_infile` on this local server.
3. Run the entire `sql/01\_import\_olist.sql` once. It creates `olist\_bulk`. Check the reported raw order count is **99,441**. The script disables server-side local loading at the end. Remove `OPT\_LOCAL\_INFILE=1` and reconnect after loading. If an error stopped the loader early, run `SET GLOBAL local\_infile = OFF;` before troubleshooting.
4. Select `olist\_bulk` as the default schema, then run the entire `sql/02\_prepare\_analysis.sql` once. It creates `olist\_analysis`; it does not change the source tables. Check **99,092 retained orders**, **20 months** and **0 orders outside the period**.
5. Run `sql/03\_business\_queries.sql`. Its `USE olist\_analysis;` selects the filtered database. Compare the outputs with `results/`.

Both setup scripts create new databases and are intended for a first run. If either target database already exists, stop and inspect it before running that setup script again. Different dataset versions or incomplete imports can produce different counts. Empty cells in the result CSVs represent SQL NULL rather than zero.

## SQL techniques

Joins, aggregations, distinct counts, CTEs and recursive CTEs, a monthly date calendar, date functions, `LAG`, `NTILE`, `RANK`, and `UNION ALL`.

