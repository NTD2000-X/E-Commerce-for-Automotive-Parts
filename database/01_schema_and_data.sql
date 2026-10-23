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

CREATE TABLE CUSTOMER (
    CustomerID INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL
);

CREATE TABLE CATEGORY (
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL,
    ParentCategoryID INT NULL,

    CONSTRAINT uq_category_name
        UNIQUE (CategoryName),

    CONSTRAINT fk_category_parent
        FOREIGN KEY (ParentCategoryID)
        REFERENCES CATEGORY(CategoryID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE TABLE VEHICLE_MODEL (
    ModelID INT PRIMARY KEY,
    Make VARCHAR(100) NOT NULL,
    ModelName VARCHAR(100) NOT NULL,
    YearRange VARCHAR(50) NOT NULL
);

CREATE TABLE PART (
    Code VARCHAR(20) PRIMARY KEY,
    Name VARCHAR(150) NOT NULL,
    Brand VARCHAR(100) NOT NULL,
    CurrentStockLevel INT NOT NULL DEFAULT 0,
    UnitPrice DECIMAL(10,2) NOT NULL,
    CategoryID INT NOT NULL,

    CONSTRAINT fk_part_category
        FOREIGN KEY (CategoryID)
        REFERENCES CATEGORY(CategoryID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT chk_part_stock
        CHECK (CurrentStockLevel >= 0),

    CONSTRAINT chk_part_price
        CHECK (UnitPrice > 0)
);

CREATE TABLE PART_COMPATIBILITY (
    Code VARCHAR(20) NOT NULL,
    ModelID INT NOT NULL,
    Note VARCHAR(255),

    PRIMARY KEY (Code, ModelID),

    CONSTRAINT fk_compatibility_part
        FOREIGN KEY (Code)
        REFERENCES PART(Code)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_compatibility_vehicle
        FOREIGN KEY (ModelID)
        REFERENCES VEHICLE_MODEL(ModelID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE CUSTOMER_ADDRESS (
    CustomerID INT NOT NULL,
    Address VARCHAR(255) NOT NULL,

    PRIMARY KEY (CustomerID, Address),

    CONSTRAINT fk_address_customer
        FOREIGN KEY (CustomerID)
        REFERENCES CUSTOMER(CustomerID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE ORDERS (
    OrderID INT PRIMARY KEY,
    OrderDate DATE NOT NULL,
    OrderStatus VARCHAR(30) NOT NULL,
    CustomerID INT NOT NULL,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (CustomerID)
        REFERENCES CUSTOMER(CustomerID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT chk_order_status
        CHECK (OrderStatus IN ('Pending', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled'))
);

CREATE TABLE ORDER_LINE (
    OrderID INT NOT NULL,
    LineNumber INT NOT NULL,
    Quantity INT NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    Code VARCHAR(20) NOT NULL,

    PRIMARY KEY (OrderID, LineNumber),

    CONSTRAINT fk_orderline_order
        FOREIGN KEY (OrderID)
        REFERENCES ORDERS(OrderID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_orderline_part
        FOREIGN KEY (Code)
        REFERENCES PART(Code)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT chk_orderline_quantity
        CHECK (Quantity > 0),

    CONSTRAINT chk_orderline_price
        CHECK (Price >= 0)
);

CREATE TABLE SHIPMENT (
    ShipmentID INT PRIMARY KEY,
    ShippingAddress VARCHAR(255) NOT NULL,
    ShippingDate DATE NOT NULL,
    DeliveryStatus VARCHAR(30) NOT NULL,
    OrderID INT NOT NULL,

    CONSTRAINT fk_shipment_order
        FOREIGN KEY (OrderID)
        REFERENCES ORDERS(OrderID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_delivery_status
        CHECK (DeliveryStatus IN ('Preparing', 'Shipped', 'Delivered', 'Cancelled'))
);

CREATE TABLE PAYMENT (
    PaymentID INT PRIMARY KEY,
    PaymentMethod VARCHAR(50) NOT NULL,
    PaymentStatus VARCHAR(30) NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    OrderID INT NOT NULL,

    CONSTRAINT fk_payment_order
        FOREIGN KEY (OrderID)
        REFERENCES ORDERS(OrderID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_payment_amount
        CHECK (Amount > 0),

    CONSTRAINT chk_payment_status
        CHECK (PaymentStatus IN ('Pending', 'Paid', 'Failed', 'Refunded'))
);

CREATE INDEX idx_part_brand
ON PART(Brand);

-- [F4 TODO]: Write INSERT INTO statements (>= 15 realistic rows per table) here.
