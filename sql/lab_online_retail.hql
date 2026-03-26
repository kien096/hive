-- Lab: Online Retail with Hive
-- Run: /opt/hive/bin/hive -f /opt/hive/scripts/lab_online_retail.hql
-- Or copy this file into container then run with hive -f

CREATE DATABASE IF NOT EXISTS retail_db;
USE retail_db;

DROP TABLE IF EXISTS online_retail;

CREATE TABLE online_retail (
  InvoiceNo STRING,
  StockCode STRING,
  Description STRING,
  Quantity INT,
  InvoiceDate STRING,
  UnitPrice DOUBLE,
  CustomerID STRING,
  Country STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
  "separatorChar" = ",",
  "quoteChar" = "\"",
  "escapeChar" = "\\"
)
STORED AS TEXTFILE
TBLPROPERTIES ("skip.header.line.count" = "1");

LOAD DATA INPATH '/data/online_retail/online_retail.csv'
OVERWRITE INTO TABLE online_retail;

-- 1) Verify load
SELECT COUNT(*) AS total_rows FROM online_retail;
SELECT * FROM online_retail LIMIT 10;

-- 2) Total invoices
SELECT COUNT(DISTINCT InvoiceNo) AS total_invoices
FROM online_retail;

-- 3) Revenue by country (exclude canceled invoices)
SELECT
  Country,
  ROUND(SUM(Quantity * UnitPrice), 2) AS revenue
FROM online_retail
WHERE InvoiceNo NOT LIKE 'C%'
GROUP BY Country
ORDER BY revenue DESC
LIMIT 10;

-- 4) Top products by quantity
SELECT
  StockCode,
  Description,
  SUM(Quantity) AS total_qty
FROM online_retail
GROUP BY StockCode, Description
ORDER BY total_qty DESC
LIMIT 10;

-- 5) Top customers by revenue
SELECT
  CustomerID,
  ROUND(SUM(Quantity * UnitPrice), 2) AS revenue
FROM online_retail
WHERE CustomerID IS NOT NULL
  AND InvoiceNo NOT LIKE 'C%'
GROUP BY CustomerID
ORDER BY revenue DESC
LIMIT 10;
