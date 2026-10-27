-- ============================================================================
-- FILE: 03_transactions_and_crud.sql
-- ASSIGNED ROLE: F4 (Data & Transaction Manager)
-- REQUIREMENT:
--   1. At least one INSERT, one UPDATE, and one DELETE for each main table.
--   2. At least one multi-table operation inside START TRANSACTION with
--      COMMIT and ROLLBACK.
-- NOTE: Test rows use IDs 901+ / 950+ and are cleaned up at the end, so the
--       script can be re-run. If a run is aborted, re-run 01_schema_and_data.sql.
-- ============================================================================

USE automotive_parts_db;
SET NAMES utf8mb4;

-- =====================================================================
-- PART A - STANDARD CRUD (one INSERT, UPDATE, DELETE for every table)
-- =====================================================================

-- ---------- A1. INSERT (parents first, FK-safe order) ----------
INSERT INTO CUSTOMER (CustomerID, Name) VALUES (901, 'Nguyễn Khách Thử Nghiệm');
INSERT INTO CATEGORY (CategoryID, CategoryName, ParentCategoryID) VALUES (901, 'Test Category', 7);
INSERT INTO VEHICLE_MODEL (ModelID, Make, ModelName, YearRange) VALUES (901, 'Mitsubishi', 'Xpander', '2019');
INSERT INTO PART (Code, Name, Brand, CurrentStockLevel, UnitPrice, CategoryID)
  VALUES ('TST-001', 'Test Part Bosch Demo', 'Bosch', 10, 9.99, 901);
INSERT INTO PART_COMPATIBILITY (Code, ModelID, Note) VALUES ('TST-001', 901, 'Demo compatibility');
INSERT INTO CUSTOMER_ADDRESS (CustomerID, Address) VALUES (901, '1 Đường Thử Nghiệm, TP. Hồ Chí Minh');
INSERT INTO ORDERS (OrderID, OrderDate, OrderStatus, CustomerID) VALUES (901, CURDATE(), 'Pending', 901);
INSERT INTO ORDER_LINE (OrderID, LineNumber, Quantity, Price, Code) VALUES (901, 1, 2, 9.99, 'TST-001');
INSERT INTO SHIPMENT (ShipmentID, ShippingAddress, ShippingDate, DeliveryStatus, OrderID)
  VALUES (901, '1 Đường Thử Nghiệm, TP. Hồ Chí Minh', CURDATE(), 'Preparing', 901);
INSERT INTO PAYMENT (PaymentID, PaymentMethod, PaymentStatus, Amount, OrderID)
  VALUES (901, 'Cash on Delivery', 'Pending', 19.98, 901);

-- ---------- A2. UPDATE (one per table, always filtered by primary key) ----------
UPDATE CUSTOMER           SET Name = 'Nguyễn Khách Đã Sửa'                     WHERE CustomerID = 901;
UPDATE CATEGORY           SET CategoryName = 'Test Category (renamed)'         WHERE CategoryID = 901;
UPDATE VEHICLE_MODEL      SET YearRange = '2020'                               WHERE ModelID = 901;
UPDATE PART               SET UnitPrice = 11.50, CurrentStockLevel = 25        WHERE Code = 'TST-001';
UPDATE PART_COMPATIBILITY SET Note = 'Updated compatibility note'              WHERE Code = 'TST-001' AND ModelID = 901;
UPDATE CUSTOMER_ADDRESS   SET Address = '2 Đường Thử Nghiệm, TP. Hồ Chí Minh'
                          WHERE CustomerID = 901 AND Address = '1 Đường Thử Nghiệm, TP. Hồ Chí Minh';
UPDATE ORDERS             SET OrderStatus = 'Confirmed'                       WHERE OrderID = 901;
UPDATE ORDER_LINE         SET Quantity = 3                                     WHERE OrderID = 901 AND LineNumber = 1;
UPDATE SHIPMENT           SET DeliveryStatus = 'Shipped'                    WHERE ShipmentID = 901;
UPDATE PAYMENT            SET PaymentStatus = 'Paid', Amount = 34.50           WHERE PaymentID = 901;

-- Quick look at the edited rows
SELECT * FROM PART     WHERE Code = 'TST-001';
SELECT * FROM ORDERS   WHERE OrderID = 901;
SELECT * FROM PAYMENT  WHERE PaymentID = 901;

-- ---------- A3. DELETE (children first, reverse of the INSERT order) ----------
DELETE FROM PAYMENT            WHERE PaymentID = 901;
DELETE FROM SHIPMENT           WHERE ShipmentID = 901;
DELETE FROM ORDER_LINE         WHERE OrderID = 901 AND LineNumber = 1;
DELETE FROM ORDERS             WHERE OrderID = 901;
DELETE FROM CUSTOMER_ADDRESS   WHERE CustomerID = 901 AND Address = '2 Đường Thử Nghiệm, TP. Hồ Chí Minh';
DELETE FROM PART_COMPATIBILITY WHERE Code = 'TST-001' AND ModelID = 901;
DELETE FROM PART               WHERE Code = 'TST-001';
DELETE FROM VEHICLE_MODEL      WHERE ModelID = 901;
DELETE FROM CATEGORY           WHERE CategoryID = 901;
DELETE FROM CUSTOMER           WHERE CustomerID = 901;

-- Check: every test row is gone (all ten counts must be 0)
SELECT
  (SELECT COUNT(*) FROM CUSTOMER           WHERE CustomerID = 901) +
  (SELECT COUNT(*) FROM CATEGORY           WHERE CategoryID = 901) +
  (SELECT COUNT(*) FROM VEHICLE_MODEL      WHERE ModelID = 901) +
  (SELECT COUNT(*) FROM PART               WHERE Code = 'TST-001') +
  (SELECT COUNT(*) FROM PART_COMPATIBILITY WHERE Code = 'TST-001') +
  (SELECT COUNT(*) FROM CUSTOMER_ADDRESS   WHERE CustomerID = 901) +
  (SELECT COUNT(*) FROM ORDERS             WHERE OrderID = 901) +
  (SELECT COUNT(*) FROM ORDER_LINE         WHERE OrderID = 901) +
  (SELECT COUNT(*) FROM SHIPMENT           WHERE ShipmentID = 901) +
  (SELECT COUNT(*) FROM PAYMENT            WHERE PaymentID = 901) AS leftover_test_rows;


-- =====================================================================
-- PART B - MULTI-TABLE TRANSACTIONS
-- Business operation "place an order": three tables change together
--   ORDERS (new header) + ORDER_LINE (new item) + PART (stock reduced).
-- All three changes must succeed together or none of them may remain.
-- Demo part: BOS-WB-002 (Bosch Wiper Blade Set Toyota Vios), seed stock = 55.
-- =====================================================================

-- ---------- B1. COMMIT path: customer 1 orders 2 units ----------
SELECT Code, CurrentStockLevel AS stock_before FROM PART WHERE Code = 'BOS-WB-002';   -- 55

START TRANSACTION;
  INSERT INTO ORDERS (OrderID, OrderDate, OrderStatus, CustomerID)
    VALUES (950, CURDATE(), 'Pending', 1);
  INSERT INTO ORDER_LINE (OrderID, LineNumber, Quantity, Price, Code)
    SELECT 950, 1, 2, UnitPrice, Code FROM PART WHERE Code = 'BOS-WB-002';
  UPDATE PART
     SET CurrentStockLevel = CurrentStockLevel - 2
   WHERE Code = 'BOS-WB-002' AND CurrentStockLevel >= 2;      -- guard: never go below 0
  SELECT ROW_COUNT() AS stock_rows_updated;                   -- must be 1; if 0 -> use ROLLBACK instead
COMMIT;

SELECT Code, CurrentStockLevel AS stock_after_commit FROM PART WHERE Code = 'BOS-WB-002';  -- 53
SELECT o.OrderID, o.OrderStatus, l.LineNumber, l.Code, l.Quantity, l.Price
  FROM ORDERS o JOIN ORDER_LINE l ON l.OrderID = o.OrderID WHERE o.OrderID = 950;

-- ---------- B2. ROLLBACK path: customer cancels before confirming ----------
START TRANSACTION;
  INSERT INTO ORDERS (OrderID, OrderDate, OrderStatus, CustomerID)
    VALUES (951, CURDATE(), 'Pending', 1);
  INSERT INTO ORDER_LINE (OrderID, LineNumber, Quantity, Price, Code)
    SELECT 951, 1, 3, UnitPrice, Code FROM PART WHERE Code = 'BOS-WB-002';
  UPDATE PART SET CurrentStockLevel = CurrentStockLevel - 3 WHERE Code = 'BOS-WB-002';
  -- Inside the transaction the changes are visible to this session only:
  SELECT CurrentStockLevel AS stock_inside_transaction FROM PART WHERE Code = 'BOS-WB-002';  -- 50
  SELECT COUNT(*) AS order_951_inside FROM ORDERS WHERE OrderID = 951;                       -- 1
ROLLBACK;

SELECT CurrentStockLevel AS stock_after_rollback FROM PART WHERE Code = 'BOS-WB-002';        -- 53 (unchanged)
SELECT COUNT(*) AS order_951_after_rollback FROM ORDERS WHERE OrderID = 951;                 -- 0

-- ---------- B3. Same operation as a stored procedure (automatic ROLLBACK on error) ----------
-- This is exactly what the Java app does with con.setAutoCommit(false) / commit() / rollback().
DROP PROCEDURE IF EXISTS sp_place_order;
DELIMITER $$
CREATE PROCEDURE sp_place_order(
  IN p_order_id    INT,
  IN p_customer_id INT,
  IN p_code        VARCHAR(20),
  IN p_qty         INT)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;      -- any error (CHECK, FK, duplicate key...) undoes all three changes
    RESIGNAL;      -- and the error is still reported to the caller
  END;

  START TRANSACTION;
    INSERT INTO ORDERS (OrderID, OrderDate, OrderStatus, CustomerID)
      VALUES (p_order_id, CURDATE(), 'Pending', p_customer_id);

    INSERT INTO ORDER_LINE (OrderID, LineNumber, Quantity, Price, Code)
      SELECT p_order_id, 1, p_qty, UnitPrice, Code FROM PART WHERE Code = p_code;
    IF ROW_COUNT() = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Part code does not exist';
    END IF;

    -- CHECK (CurrentStockLevel >= 0) rejects this when stock is insufficient
    UPDATE PART SET CurrentStockLevel = CurrentStockLevel - p_qty WHERE Code = p_code;
  COMMIT;
END$$
DELIMITER ;

CALL sp_place_order(960, 7, 'BOS-WB-002', 1);                  -- succeeds: stock 53 -> 52
SELECT CurrentStockLevel AS stock_after_call FROM PART WHERE Code = 'BOS-WB-002';   -- 52

-- ---------- B4. CLEAN-UP: undo the demo orders and restore stock (net change = 0) ----------
START TRANSACTION;
  UPDATE PART SET CurrentStockLevel = CurrentStockLevel + 2 WHERE Code = 'BOS-WB-002';   -- order 950
  UPDATE PART SET CurrentStockLevel = CurrentStockLevel + 1 WHERE Code = 'BOS-WB-002';   -- order 960
  DELETE FROM ORDERS WHERE OrderID = 950;      -- ORDER_LINE rows follow (ON DELETE CASCADE)
  DELETE FROM ORDERS WHERE OrderID = 960;
COMMIT;
SELECT CurrentStockLevel AS stock_restored FROM PART WHERE Code = 'BOS-WB-002';          -- 55

-- ---------- B5. FAILURE demo - run these two lines ONE AT A TIME (after everything above) ----------
-- CAS-EO-004 has stock 0, so the UPDATE violates CHECK (CurrentStockLevel >= 0).
-- The procedure's handler rolls back; the second SELECT proves no order 961 was left behind.
-- CALL sp_place_order(961, 1, 'CAS-EO-004', 1);                  -- Error 3819 (CHECK constraint violated)
-- SELECT COUNT(*) AS order_961_exists FROM ORDERS WHERE OrderID = 961;   -- 0