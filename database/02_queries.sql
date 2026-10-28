-- ============================================================================
-- FILE: 02_queries.sql
-- ASSIGNED ROLE: F5 (Query & Algebra Specialist)
-- REQUIREMENT: At least 12 SQL queries, each preceded by the English question
--              it answers in a comment.
-- ============================================================================

USE automotive_parts_db;

-- Query 1 (Topic 4 - Multi-table Join): Every part that fits a Toyota Vios 2019.
SELECT p.Code, p.Name, p.Brand, p.UnitPrice
FROM PART p
INNER JOIN PART_COMPATIBILITY pc ON pc.Code = p.Code
INNER JOIN VEHICLE_MODEL vm ON vm.ModelID = pc.ModelID
WHERE vm.Make = 'Toyota'
  AND vm.ModelName = 'Vios'
  AND vm.YearRange = '2019';
-- Query 2 (Topic 4 - Grouping & Aggregation): The ten best-selling parts by revenue last quarter.
SELECT p.Code, p.Name, p.Brand, p.UnitPrice,
       SUM(ol.Quantity * ol.Price) AS TotalRevenue
FROM PART p
JOIN ORDER_LINE ol ON ol.Code = p.Code
JOIN ORDERS o ON o.OrderID = ol.OrderID
WHERE o.OrderDate BETWEEN '2026-07-01' AND '2026-09-30'
  AND o.OrderStatus != 'Cancelled'
GROUP BY p.Code, p.Name, p.Brand
ORDER BY TotalRevenue DESC
LIMIT 10;
-- Query 3 (Topic 4 - Nested IN/EXISTS): Orders that contain a part now out of stock.
SELECT o.OrderID, o.CustomerID, o.OrderDate
FROM ORDERS o
WHERE EXISTS (
    SELECT 1
    FROM ORDER_LINE ol
    JOIN PART p ON p.Code = ol.Code
    WHERE ol.OrderID = o.OrderID
      AND p.CurrentStockLevel = 0
);
-- Query 4 (Topic 4 - NOT EXISTS Division): Customers who bought parts from every brand the shop carries.
SELECT c.CustomerID, c.Name
FROM CUSTOMER c
WHERE NOT EXISTS (
    SELECT 1 FROM PART pb
    WHERE NOT EXISTS (
        SELECT 1
        FROM ORDERS o
        JOIN ORDER_LINE ol ON ol.OrderID = o.OrderID
        JOIN PART p ON p.Code = ol.Code
        WHERE o.CustomerID = c.CustomerID
          AND p.Brand = pb.Brand
    )
);
-- Query 5 (Topic 4 - Aggregation): For each category, the number of parts and the average price.
SELECT c.CategoryID, c.CategoryName,
       COUNT(p.Code) AS PartCount,
       ROUND(AVG(p.UnitPrice), 2) AS AvgPrice
FROM CATEGORY c
JOIN PART p ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryID, c.CategoryName;
-- Query 6 (Outer Join): Which customers exist, including those who have never placed an order?
SELECT c.CustomerID, c.Name, COUNT(o.OrderID) AS OrderCount
FROM CUSTOMER c
LEFT JOIN ORDERS o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.Name
ORDER BY OrderCount, c.CustomerID;
-- Query 7 (GROUP BY with HAVING): Which customers have spent more than 150 in total?
SELECT c.CustomerID, c.Name,
       SUM(ol.Quantity * ol.Price) AS TotalSpent
FROM CUSTOMER c
JOIN ORDERS o ON o.CustomerID = c.CustomerID
JOIN ORDER_LINE ol ON ol.OrderID = o.OrderID
GROUP BY c.CustomerID, c.Name
HAVING SUM(ol.Quantity * ol.Price) > 150
ORDER BY TotalSpent DESC;
-- Query 8 (Set Operation - UNION): Which parts fit either a 2019 Toyota Vios or a 2020 Honda City?
SELECT p.Code, p.Name
FROM PART p
JOIN PART_COMPATIBILITY pc ON pc.Code = p.Code
JOIN VEHICLE_MODEL vm ON vm.ModelID = pc.ModelID
WHERE vm.Make = 'Toyota' AND vm.ModelName = 'Vios' AND vm.YearRange = '2019'
UNION
SELECT p.Code, p.Name
FROM PART p
JOIN PART_COMPATIBILITY pc ON pc.Code = p.Code
JOIN VEHICLE_MODEL vm ON vm.ModelID = pc.ModelID
WHERE vm.Make = 'Honda' AND vm.ModelName = 'City' AND vm.YearRange = '2020';
-- Query 9 (View Creation & Query): What is each order's line total and paid total?
CREATE OR REPLACE VIEW vw_order_financials AS
SELECT o.OrderID,
       (SELECT COALESCE(SUM(ol.Quantity * ol.Price), 0)
          FROM ORDER_LINE ol
          WHERE ol.OrderID = o.OrderID) AS OrderTotal,
       (SELECT COALESCE(SUM(pay.Amount), 0)
          FROM PAYMENT pay
          WHERE pay.OrderID = o.OrderID
            AND pay.PaymentStatus = 'Paid') AS PaidTotal
FROM ORDERS o;

SELECT * FROM vw_order_financials;
-- Query 10 (Recursive Category Self-Join): What is every sub-category and the name of its parent category?
SELECT c_sub.CategoryID,
       c_sub.CategoryName AS SubCategory,
       c_parent.CategoryName AS ParentCategory
FROM CATEGORY c_sub
JOIN CATEGORY c_parent ON c_sub.ParentCategoryID = c_parent.CategoryID
ORDER BY c_parent.CategoryName, c_sub.CategoryName;
-- Query 11 (Order Total vs Payment Total Check): Which orders are only partially paid or unpaid?
SELECT o.OrderID,
       SUM(ol.Quantity * ol.Price) AS OrderTotal,
       COALESCE(pay.PaidTotal, 0) AS PaidTotal
FROM ORDERS o
JOIN ORDER_LINE ol ON ol.OrderID = o.OrderID
LEFT JOIN (
    SELECT OrderID, SUM(Amount) AS PaidTotal
    FROM PAYMENT
    WHERE PaymentStatus = 'Paid'
    GROUP BY OrderID
) pay ON pay.OrderID = o.OrderID
GROUP BY o.OrderID, pay.PaidTotal
HAVING SUM(ol.Quantity * ol.Price) > COALESCE(pay.PaidTotal, 0);
-- Query 12 (Shipment Status Breakdown): How many shipments are in each delivery status, and what are their earliest and latest shipping dates?
SELECT DeliveryStatus,
       COUNT(*) AS ShipmentCount,
       MIN(ShippingDate) AS EarliestShipping,
       MAX(ShippingDate) AS LatestShipping
FROM SHIPMENT
GROUP BY DeliveryStatus;
