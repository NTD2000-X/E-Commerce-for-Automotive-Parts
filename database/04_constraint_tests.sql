-- ============================================================================
-- FILE: 04_constraint_tests.sql
-- ASSIGNED ROLE: F4 (Data & Transaction Manager)
-- REQUIREMENT: Test statements that intentionally fail to prove constraints work:
--   1. Duplicate Primary Key
--   2. Non-existent Foreign Key
--   3. Value breaking a CHECK constraint (e.g., negative price or stock)
--   4. Deleting a CUSTOMER who still has ORDERS (ON DELETE RESTRICT)
-- ============================================================================

USE automotive_parts_db;

-- [F4 TODO]: Write intentional failure test statements and screenshot the errors.
