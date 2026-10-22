-- ============================================================================
-- FILE: 03_transactions_and_crud.sql
-- ASSIGNED ROLE: F4 (Data & Transaction Manager)
-- REQUIREMENT:
--   1. At least one INSERT, one UPDATE, and one DELETE for each main table.
--   2. At least one multi-table operation inside START TRANSACTION with
--      COMMIT and ROLLBACK.
-- ============================================================================

USE automotive_parts_db;

-- [F4 TODO]: Add standard INSERT / UPDATE / DELETE statements here.

-- [F4 TODO]: Add multi-table transaction (e.g., inserting ORDER_LINE and updating PART.CurrentStockLevel).
START TRANSACTION;
-- SQL statements here
COMMIT;
