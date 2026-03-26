USE retail_db;

-- 1) Thong ke so luong giao dich theo quoc gia
SELECT
  Country,
  COUNT(DISTINCT InvoiceNo) AS so_giao_dich
FROM online_retail
GROUP BY Country
ORDER BY so_giao_dich DESC;

-- 2) Tinh tong doanh thu theo quoc gia
SELECT
  Country,
  ROUND(SUM(Quantity * UnitPrice), 2) AS tong_doanh_thu
FROM online_retail
WHERE InvoiceNo NOT LIKE 'C%'
  AND Quantity > 0
  AND UnitPrice > 0
GROUP BY Country
ORDER BY tong_doanh_thu DESC;

-- 3) Tim 10 san pham ban nhieu nhat
SELECT
  StockCode,
  Description,
  SUM(Quantity) AS so_luong_ban
FROM online_retail
WHERE InvoiceNo NOT LIKE 'C%'
  AND Quantity > 0
GROUP BY StockCode, Description
ORDER BY so_luong_ban DESC
LIMIT 10;

-- 4) Tinh gia trung binh cua moi san pham
SELECT
  StockCode,
  Description,
  ROUND(AVG(UnitPrice), 2) AS gia_trung_binh
FROM online_retail
WHERE UnitPrice > 0
GROUP BY StockCode, Description
ORDER BY gia_trung_binh DESC
LIMIT 20;

-- 5) Tim 5 quoc gia co doanh thu cao nhat
SELECT
  Country,
  ROUND(SUM(Quantity * UnitPrice), 2) AS tong_doanh_thu
FROM online_retail
WHERE InvoiceNo NOT LIKE 'C%'
  AND Quantity > 0
  AND UnitPrice > 0
GROUP BY Country
ORDER BY tong_doanh_thu DESC
LIMIT 5;
