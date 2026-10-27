-- ============================================================================
-- FILE: 04_constraint_tests.sql
-- ASSIGNED ROLE: F4 (Data & Transaction Manager)
-- REQUIREMENT: Test statements that intentionally fail to prove constraints work:
--   1. Duplicate Primary Key
--   2. Non-existent Foreign Key
--   3. Value breaking a CHECK constraint (e.g., negative price or stock)
--   4. Deleting a CUSTOMER who still has ORDERS (ON DELETE RESTRICT)
-- HOW TO RUN: Workbench -> select ONE statement -> Ctrl+Enter -> screenshot the
--   Action Output (T01.png, T02.png ...) into /docs/screenshots/constraint_tests/.
--   Command line (all tests, continue after errors):
--     mysql --force -u root -p automotive_parts_db < 04_constraint_tests.sql
-- Sections 1-4 must FAIL. Section 5 must SUCCEED and is rolled back.
-- ============================================================================

USE automotive_parts_db;
SET NAMES utf8mb4;

-- ===================== 1. DUPLICATE PRIMARY KEY / UNIQUE =====================
-- T01  Duplicate PK in CUSTOMER                      -> ERROR 1062 Duplicate entry '1' for key 'customer.PRIMARY'
INSERT INTO CUSTOMER (CustomerID, Name) VALUES (1, 'Duplicate Customer');

-- T02  Duplicate PK in PART (Code is the key)         -> ERROR 1062 Duplicate entry 'NGK-SP-001'
INSERT INTO PART (Code, Name, Brand, CurrentStockLevel, UnitPrice, CategoryID)
  VALUES ('NGK-SP-001', 'Duplicate Spark Plug', 'NGK', 5, 8.00, 8);

-- T03  Duplicate composite PK in ORDER_LINE           -> ERROR 1062 Duplicate entry '1-1'
INSERT INTO ORDER_LINE (OrderID, LineNumber, Quantity, Price, Code)
  VALUES (1, 1, 1, 8.50, 'NGK-SP-001');

-- T04  UNIQUE(CategoryName) violated                  -> ERROR 1062 Duplicate entry 'Spark Plugs'
INSERT INTO CATEGORY (CategoryID, CategoryName, ParentCategoryID) VALUES (902, 'Spark Plugs', 1);

-- ===================== 2. FOREIGN KEY TO A ROW THAT DOES NOT EXIST =====================
-- T05  ORDERS -> CUSTOMER 99999 does not exist        -> ERROR 1452 Cannot add or update a child row
INSERT INTO ORDERS (OrderID, OrderDate, OrderStatus, CustomerID) VALUES (990, '2026-10-27', 'Pending', 99999);

-- T06  ORDER_LINE -> PART 'XXX-000' does not exist    -> ERROR 1452
INSERT INTO ORDER_LINE (OrderID, LineNumber, Quantity, Price, Code) VALUES (1, 9, 1, 5.00, 'XXX-000');

-- T07  PART -> CATEGORY 999 does not exist            -> ERROR 1452
INSERT INTO PART (Code, Name, Brand, CurrentStockLevel, UnitPrice, CategoryID)
  VALUES ('TST-900', 'Orphan Part', 'Bosch', 1, 5.00, 999);

-- T08  PART_COMPATIBILITY -> VEHICLE_MODEL 999        -> ERROR 1452
INSERT INTO PART_COMPATIBILITY (Code, ModelID, Note) VALUES ('NGK-SP-001', 999, 'No such model');

-- ===================== 3. CHECK CONSTRAINT VIOLATIONS =====================
-- T09  Negative price                                  -> ERROR 3819 Check constraint '...' is violated
INSERT INTO PART (Code, Name, Brand, CurrentStockLevel, UnitPrice, CategoryID)
  VALUES ('TST-901', 'Negative Price Part', 'Bosch', 5, -5.00, 8);

-- T10  Zero price (rule is UnitPrice > 0)              -> ERROR 3819
INSERT INTO PART (Code, Name, Brand, CurrentStockLevel, UnitPrice, CategoryID)
  VALUES ('TST-902', 'Free Part', 'Bosch', 5, 0.00, 8);

-- T11  Negative stock                                  -> ERROR 3819
INSERT INTO PART (Code, Name, Brand, CurrentStockLevel, UnitPrice, CategoryID)
  VALUES ('TST-903', 'Negative Stock Part', 'Bosch', -1, 5.00, 8);

-- T12  Quantity = 0 on an order line                   -> ERROR 3819
INSERT INTO ORDER_LINE (OrderID, LineNumber, Quantity, Price, Code) VALUES (1, 8, 0, 8.50, 'NGK-SP-001');

-- T13  Negative line price                             -> ERROR 3819
INSERT INTO ORDER_LINE (OrderID, LineNumber, Quantity, Price, Code) VALUES (1, 8, 1, -8.50, 'NGK-SP-001');

-- T14  Payment amount = 0                              -> ERROR 3819
INSERT INTO PAYMENT (PaymentID, PaymentMethod, PaymentStatus, Amount, OrderID)
  VALUES (990, 'Bank Transfer', 'Paid', 0, 1);

-- T15  Invalid status value                            -> ERROR 3819
INSERT INTO ORDERS (OrderID, OrderDate, OrderStatus, CustomerID) VALUES (991, '2026-10-27', 'Lost', 1);

-- T16  UPDATE that breaks a CHECK (stock below zero)   -> ERROR 3819
UPDATE PART SET CurrentStockLevel = CurrentStockLevel - 1 WHERE Code = 'CAS-EO-004';   -- stock is 0

-- ===================== 4. DELETE A PARENT THAT STILL HAS CHILDREN =====================
-- T17  Customer 1 still has orders (RESTRICT)          -> ERROR 1451 Cannot delete or update a parent row
DELETE FROM CUSTOMER WHERE CustomerID = 1;

-- T18  Part already sold on order lines (RESTRICT)     -> ERROR 1451
DELETE FROM PART WHERE Code = 'NGK-SP-001';

-- T19  Category that still contains parts (RESTRICT)   -> ERROR 1451
DELETE FROM CATEGORY WHERE CategoryID = 8;

-- ===================== 5. POSITIVE CONTROLS (must SUCCEED, then ROLLBACK) =====================
-- T20  Deleting a customer WITHOUT orders is allowed and removes the address rows (ON DELETE CASCADE)
SELECT COUNT(*) AS addresses_before FROM CUSTOMER_ADDRESS WHERE CustomerID = 16;       -- 1
START TRANSACTION;
  DELETE FROM CUSTOMER WHERE CustomerID = 16;                                          -- 1 row affected
  SELECT COUNT(*) AS addresses_after_delete FROM CUSTOMER_ADDRESS WHERE CustomerID = 16;   -- 0
ROLLBACK;
SELECT COUNT(*) AS addresses_after_rollback FROM CUSTOMER_ADDRESS WHERE CustomerID = 16; -- 1

-- T21  Apostrophe is stored as data, not as SQL (doubling the quote = same effect as PreparedStatement)
START TRANSACTION;
  INSERT INTO CUSTOMER (CustomerID, Name) VALUES (902, 'Nguyễn O''Brien');
  SELECT CustomerID, Name FROM CUSTOMER WHERE CustomerID = 902;                        -- Nguyễn O'Brien
ROLLBACK;