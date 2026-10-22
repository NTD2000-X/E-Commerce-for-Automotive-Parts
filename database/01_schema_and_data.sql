-- ============================================================================
-- FILE: 01_schema_and_data.sql
-- ASSIGNED ROLES:
--   Part 1 (DDL, Constraints, Indexes): F3 (DDL Engineer)
--   Part 2 (15+ Rows Sample Data per Table): F4 (Data & Transaction Manager)
-- REQUIREMENT: Must run top-to-bottom on an empty MySQL 8.0.46 server twice
--              in a row without manual repair.
-- ============================================================================

DROP DATABASE IF EXISTS automotive_parts_db;
CREATE DATABASE automotive_parts_db;
USE automotive_parts_db;

-- [F3 TODO]: Write CREATE TABLE statements in FK order:
-- 1. CUSTOMER
-- 2. CATEGORY
-- 3. VEHICLE_MODEL
-- 4. PART
-- 5. PART_COMPATIBILITY
-- 6. CUSTOMER_ADDRESS
-- 7. ORDERS
-- 8. ORDER_LINE
-- 9. SHIPMENT
-- 10. PAYMENT

-- [F3 TODO]: Add CREATE INDEX statement(s) here.

-- [F4 TODO]: Write INSERT INTO statements (>= 15 realistic rows per table) here.
