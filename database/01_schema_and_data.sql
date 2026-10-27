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

-- F4: SAMPLE DATA 
-- Money unit: USD, 2 decimals. Dates: ISO 'YYYY-MM-DD'.
-- "Last quarter" = Q3 2026 (2026-07-01 .. 2026-09-30).

SET NAMES utf8mb4;
 
-- 1/10 CUSTOMER
INSERT INTO CUSTOMER (CustomerID, Name) VALUES
  (1, 'Nguyễn Văn An'),
  (2, 'Trần Thị Bích Ngọc'),
  (3, 'Lê Hoàng Long'),
  (4, 'Phạm Minh Khoa'),
  (5, 'Võ Thị Thanh Hà'),
  (6, 'Đặng Quốc Bảo'),
  (7, 'Bùi Thị Mai'),
  (8, 'Hoàng Văn Tùng'),
  (9, 'Phan Thị Lan Anh'),
  (10, 'Huỳnh Gia Hưng'),
  (11, 'Ngô Thanh Tâm'),
  (12, 'Dương Minh Triết'),
  (13, 'Lý Thị Hồng Nhung'),
  (14, 'Đỗ Anh Tuấn'),
  (15, 'Vũ Thị Kim Chi'),
  (16, 'Trương Quốc Việt'),
  (17, 'Cao Thị Yến Nhi'),
  (18, 'Đinh Văn Phước'),
  (19, 'Auto Gara Sài Gòn'),
  (20, 'Gara Minh Phát');
 
-- 2/10 CATEGORY (parents first; recursive via ParentCategoryID)
INSERT INTO CATEGORY (CategoryID, CategoryName, ParentCategoryID) VALUES
  (1, 'Engine & Ignition', NULL),
  (2, 'Braking System', NULL),
  (3, 'Electrical & Sensors', NULL),
  (4, 'Filters', NULL),
  (5, 'Fluids & Lubricants', NULL),
  (6, 'Suspension & Steering', NULL),
  (7, 'Body & Lighting', NULL),
  (8, 'Spark Plugs', 1),
  (9, 'Ignition Coils', 1),
  (10, 'Brake Pads', 2),
  (11, 'Brake Discs', 2),
  (12, 'Batteries', 3),
  (13, 'Sensors', 3),
  (14, 'Alternators & Starters', 3),
  (15, 'Oil Filters', 4),
  (16, 'Air Filters', 4),
  (17, 'Engine Oil', 5),
  (18, 'Brake Fluid', 5),
  (19, 'Shock Absorbers', 6),
  (20, 'Wiper Blades', 7),
  (21, 'Headlight Bulbs', 7);
 
-- 3/10 VEHICLE_MODEL (includes Toyota / Vios / 2019)
INSERT INTO VEHICLE_MODEL (ModelID, Make, ModelName, YearRange) VALUES
  (1, 'Toyota', 'Vios', '2019'),
  (2, 'Toyota', 'Vios', '2014-2018'),
  (3, 'Toyota', 'Fortuner', '2020'),
  (4, 'Honda', 'City', '2020'),
  (5, 'Honda', 'Civic', '2018'),
  (6, 'Mazda', 'Mazda3', '2019'),
  (7, 'Hyundai', 'Accent', '2020'),
  (8, 'Ford', 'Ranger', '2019'),
  (9, 'Kia', 'Morning', '2018'),
  (10, 'VinFast', 'Fadil', '2020'),
  (11, 'Toyota', 'Camry', '2019'),
  (12, 'Honda', 'SH150i', '2020'),
  (13, 'Honda', 'Winner X', '2020'),
  (14, 'Yamaha', 'Exciter 155', '2021'),
  (15, 'Honda', 'Wave Alpha', '2019'),
  (16, 'Honda', 'Vision', '2021'),
  (17, 'Yamaha', 'Sirius', '2019'),
  (18, 'Suzuki', 'Raider R150', '2019');
 
-- 4/10 PART (5 brands: Bosch, Denso, NGK, Brembo, Castrol; 3 parts with stock = 0)
INSERT INTO PART (Code, Name, Brand, CurrentStockLevel, UnitPrice, CategoryID) VALUES
  ('NGK-SP-001', 'NGK Iridium IX Spark Plug BKR6EIX', 'NGK', 120, 8.50, 8),
  ('NGK-SP-002', 'NGK Standard Spark Plug CR7HSA (Motorbike)', 'NGK', 200, 2.80, 8),
  ('DEN-SP-001', 'Denso Iridium TT Spark Plug IK20TT', 'Denso', 90, 9.20, 8),
  ('BOS-SP-001', 'Bosch Platinum Spark Plug FR7DPP33+', 'Bosch', 75, 6.90, 8),
  ('NGK-IC-001', 'NGK Ignition Coil U5057', 'NGK', 30, 38.00, 9),
  ('DEN-IC-001', 'Denso Ignition Coil Toyota Vios', 'Denso', 0, 42.50, 9),
  ('BRE-BP-001', 'Brembo Front Brake Pads Toyota Vios', 'Brembo', 40, 46.00, 10),
  ('BRE-BP-002', 'Brembo Rear Brake Pads Honda City', 'Brembo', 25, 38.50, 10),
  ('BOS-BP-001', 'Bosch Front Brake Pads Mazda3', 'Bosch', 35, 41.00, 10),
  ('BRE-BP-003', 'Brembo Front Brake Pads Honda Winner X', 'Brembo', 60, 15.00, 10),
  ('BRE-BD-001', 'Brembo Front Brake Disc Toyota Vios', 'Brembo', 18, 72.00, 11),
  ('BRE-BD-002', 'Brembo Rear Brake Disc Honda City', 'Brembo', 0, 64.00, 11),
  ('BOS-BT-001', 'Bosch S4 Car Battery 12V 45Ah', 'Bosch', 22, 68.00, 12),
  ('BOS-BT-002', 'Bosch S5 Car Battery 12V 60Ah', 'Bosch', 15, 95.00, 12),
  ('DEN-OS-001', 'Denso Oxygen Sensor Toyota Vios', 'Denso', 28, 54.00, 13),
  ('NGK-OS-001', 'NGK Oxygen Sensor Honda City', 'NGK', 20, 49.00, 13),
  ('DEN-AL-001', 'Denso Alternator 12V 80A Toyota Vios', 'Denso', 8, 185.00, 14),
  ('BOS-ST-001', 'Bosch Starter Motor 12V Hyundai Accent', 'Bosch', 6, 160.00, 14),
  ('DEN-OF-001', 'Denso Oil Filter Toyota Vios', 'Denso', 150, 4.80, 15),
  ('DEN-OF-002', 'Denso Oil Filter Honda City', 'Denso', 110, 5.20, 15),
  ('BOS-OF-001', 'Bosch Oil Filter Ford Ranger 2.2L', 'Bosch', 70, 7.50, 15),
  ('DEN-AF-001', 'Denso Air Filter Toyota Vios', 'Denso', 85, 8.90, 16),
  ('BOS-AF-001', 'Bosch Air Filter Mazda3', 'Bosch', 40, 11.50, 16),
  ('BOS-AF-002', 'Bosch Cabin Air Filter Toyota Vios', 'Bosch', 60, 6.00, 16),
  ('CAS-EO-001', 'Castrol GTX 10W-40 Engine Oil 4L', 'Castrol', 100, 24.00, 17),
  ('CAS-EO-002', 'Castrol Magnatec 5W-30 Engine Oil 4L', 'Castrol', 80, 36.00, 17),
  ('CAS-EO-003', 'Castrol Power1 4T 10W-40 1L (Motorbike)', 'Castrol', 300, 6.50, 17),
  ('CAS-EO-004', 'Castrol Edge 0W-20 Engine Oil 4L', 'Castrol', 0, 52.00, 17),
  ('CAS-BF-001', 'Castrol React Performance DOT 4 500ml', 'Castrol', 110, 9.80, 18),
  ('BOS-WB-001', 'Bosch Aerotwin Wiper Blade 24 inch', 'Bosch', 45, 14.50, 20),
  ('BOS-WB-002', 'Bosch Wiper Blade Set Toyota Vios', 'Bosch', 55, 13.00, 20);
 
-- 5/10 PART_COMPATIBILITY (Vios 2019 = ModelID 1 has 12 parts)
INSERT INTO PART_COMPATIBILITY (Code, ModelID, Note) VALUES
  ('DEN-SP-001', 1, 'Fits 1.5L engine'),
  ('NGK-SP-001', 1, 'Fits 1.5L engine'),
  ('DEN-IC-001', 1, 'One coil per cylinder'),
  ('BRE-BP-001', 1, 'Front axle'),
  ('BRE-BD-001', 1, 'Front axle, 15 inch wheel'),
  ('DEN-OS-001', 1, 'Upstream sensor'),
  ('DEN-AL-001', 1, '12V 80A'),
  ('DEN-OF-001', 1, 'Spin-on filter'),
  ('DEN-AF-001', 1, 'Panel type'),
  ('BOS-AF-002', 1, 'Behind glove box'),
  ('BOS-WB-002', 1, 'Driver 26 inch, passenger 16 inch'),
  ('CAS-EO-001', 1, 'Recommended viscosity 10W-40'),
  ('DEN-OF-001', 2, 'Spin-on filter'),
  ('DEN-AF-001', 2, 'Panel type'),
  ('NGK-SP-001', 2, 'Fits 1.5L engine'),
  ('BRE-BP-001', 2, 'Front axle'),
  ('CAS-EO-002', 3, 'Diesel and petrol variants'),
  ('BOS-BT-002', 3, '60Ah, fits tray'),
  ('BRE-BP-002', 4, 'Rear axle'),
  ('BRE-BD-002', 4, 'Rear axle'),
  ('DEN-OF-002', 4, 'Spin-on filter'),
  ('NGK-OS-001', 4, 'Upstream sensor'),
  ('CAS-EO-002', 4, 'Recommended 5W-30'),
  ('DEN-OF-002', 5, 'Spin-on filter'),
  ('NGK-SP-001', 5, '1.8L engine'),
  ('BOS-BP-001', 6, 'Front axle'),
  ('BOS-AF-001', 6, 'Panel type'),
  ('BOS-BT-001', 6, '45Ah'),
  ('BOS-ST-001', 7, '1.4L engine'),
  ('BOS-SP-001', 7, '1.4L engine'),
  ('BOS-OF-001', 8, '2.2L diesel'),
  ('BOS-BT-002', 8, '60Ah'),
  ('NGK-SP-001', 9, '1.25L engine'),
  ('CAS-EO-001', 9, 'Recommended 10W-40'),
  ('BOS-BT-001', 10, '45Ah'),
  ('BOS-WB-001', 10, 'Driver side'),
  ('NGK-IC-001', 11, '2.0L / 2.5L engine'),
  ('BOS-WB-001', 11, 'Driver side'),
  ('CAS-EO-003', 12, 'JASO MA2'),
  ('NGK-SP-002', 12, 'CR7HSA'),
  ('CAS-EO-003', 13, 'JASO MA2'),
  ('BRE-BP-003', 13, 'Front caliper'),
  ('CAS-EO-003', 14, 'JASO MA2'),
  ('BRE-BP-003', 14, 'Front caliper'),
  ('NGK-SP-002', 15, 'CR7HSA'),
  ('CAS-EO-003', 15, 'JASO MA2'),
  ('NGK-SP-002', 16, 'CR7HSA'),
  ('CAS-EO-003', 16, 'JASO MA2'),
  ('NGK-SP-002', 17, 'CR7HSA'),
  ('CAS-EO-003', 17, 'JASO MA2'),
  ('CAS-BF-001', 18, 'DOT 4');
 
-- 6/10 CUSTOMER_ADDRESS
INSERT INTO CUSTOMER_ADDRESS (CustomerID, Address) VALUES
  (1, '12 Nguyễn Văn Linh, Quận 7, TP. Hồ Chí Minh'),
  (1, '45 Lê Văn Việt, Quận 9, TP. Hồ Chí Minh'),
  (2, '88 Cách Mạng Tháng Tám, Quận 3, TP. Hồ Chí Minh'),
  (3, '210 Quang Trung, Quận Gò Vấp, TP. Hồ Chí Minh'),
  (4, '15 Trần Hưng Đạo, Quận 1, TP. Hồ Chí Minh'),
  (5, '67 Phạm Văn Đồng, TP. Thủ Đức, TP. Hồ Chí Minh'),
  (6, '134 Lý Thường Kiệt, Quận 10, TP. Hồ Chí Minh'),
  (7, '9 Võ Văn Tần, Quận 3, TP. Hồ Chí Minh'),
  (7, '302 Nguyễn Thị Minh Khai, Quận 1, TP. Hồ Chí Minh'),
  (8, '56 Hoàng Văn Thụ, Quận Phú Nhuận, TP. Hồ Chí Minh'),
  (9, '23 Nguyễn Huệ, TP. Biên Hòa, Đồng Nai'),
  (10, '101 Lê Lợi, Quận Hải Châu, Đà Nẵng'),
  (11, '78 Nguyễn Trãi, Quận Thanh Xuân, Hà Nội'),
  (12, '5 Đường 3 Tháng 2, Quận Ninh Kiều, Cần Thơ'),
  (13, '160 Phan Văn Trị, Quận Bình Thạnh, TP. Hồ Chí Minh'),
  (14, '39 Hùng Vương, TP. Thủ Dầu Một, Bình Dương'),
  (15, '92 Tô Hiến Thành, Quận 10, TP. Hồ Chí Minh'),
  (16, '14 Nguyễn Oanh, Quận Gò Vấp, TP. Hồ Chí Minh'),
  (17, '250 Lê Duẩn, Quận Đống Đa, Hà Nội'),
  (18, '33 Trường Chinh, Quận Tân Bình, TP. Hồ Chí Minh'),
  (19, '400 Xô Viết Nghệ Tĩnh, Quận Bình Thạnh, TP. Hồ Chí Minh'),
  (19, '18 Quốc lộ 1A, TP. Biên Hòa, Đồng Nai'),
  (20, '72 Lạc Long Quân, Quận 11, TP. Hồ Chí Minh'),
  (20, '11 Tân Kỳ Tân Quý, Quận Tân Phú, TP. Hồ Chí Minh');
 
-- 7/10 ORDERS (4 in Q2, 18 in Q3 = last quarter, 10 in Q4)
INSERT INTO ORDERS (OrderID, OrderDate, OrderStatus, CustomerID) VALUES
  (1, '2026-04-08', 'Delivered', 2),
  (2, '2026-04-22', 'Delivered', 3),
  (3, '2026-05-15', 'Delivered', 5),
  (4, '2026-06-10', 'Delivered', 8),
  (5, '2026-07-02', 'Delivered', 1),
  (6, '2026-07-05', 'Delivered', 4),
  (7, '2026-07-09', 'Delivered', 7),
  (8, '2026-07-14', 'Delivered', 6),
  (9, '2026-07-18', 'Delivered', 19),
  (10, '2026-07-22', 'Delivered', 9),
  (11, '2026-07-27', 'Delivered', 2),
  (12, '2026-08-01', 'Delivered', 3),
  (13, '2026-08-06', 'Delivered', 10),
  (14, '2026-08-11', 'Delivered', 1),
  (15, '2026-08-16', 'Delivered', 5),
  (16, '2026-08-21', 'Delivered', 7),
  (17, '2026-08-25', 'Delivered', 20),
  (18, '2026-08-30', 'Delivered', 19),
  (19, '2026-09-05', 'Delivered', 11),
  (20, '2026-09-12', 'Cancelled', 12),
  (21, '2026-09-18', 'Delivered', 13),
  (22, '2026-09-24', 'Cancelled', 14),
  (23, '2026-10-01', 'Delivered', 4),
  (24, '2026-10-03', 'Delivered', 2),
  (25, '2026-10-06', 'Delivered', 7),
  (26, '2026-10-09', 'Shipped', 15),
  (27, '2026-10-12', 'Delivered', 1),
  (28, '2026-10-15', 'Confirmed', 8),
  (29, '2026-10-18', 'Shipped', 10),
  (30, '2026-10-21', 'Shipped', 19),
  (31, '2026-10-24', 'Confirmed', 6),
  (32, '2026-10-26', 'Pending', 11);
 
-- 8/10 ORDER_LINE (Price = unit price at time of purchase)
INSERT INTO ORDER_LINE (OrderID, LineNumber, Quantity, Price, Code) VALUES
  (1, 1, 4, 2.80, 'NGK-SP-002'),
  (1, 2, 2, 6.50, 'CAS-EO-003'),
  (2, 1, 1, 15.00, 'BRE-BP-003'),
  (2, 2, 1, 6.50, 'CAS-EO-003'),
  (3, 1, 1, 68.00, 'BOS-BT-001'),
  (4, 1, 2, 4.80, 'DEN-OF-001'),
  (4, 2, 1, 8.90, 'DEN-AF-001'),
  (5, 1, 1, 4.80, 'DEN-OF-001'),
  (5, 2, 1, 24.00, 'CAS-EO-001'),
  (5, 3, 1, 8.90, 'DEN-AF-001'),
  (6, 1, 1, 46.00, 'BRE-BP-001'),
  (6, 2, 2, 72.00, 'BRE-BD-001'),
  (7, 1, 1, 68.00, 'BOS-BT-001'),
  (7, 2, 4, 8.50, 'NGK-SP-001'),
  (8, 1, 2, 38.00, 'NGK-IC-001'),
  (8, 2, 1, 42.50, 'DEN-IC-001'),
  (9, 1, 1, 160.00, 'BOS-ST-001'),
  (9, 2, 4, 7.50, 'BOS-OF-001'),
  (9, 3, 2, 36.00, 'CAS-EO-002'),
  (10, 1, 1, 185.00, 'DEN-AL-001'),
  (10, 2, 1, 54.00, 'DEN-OS-001'),
  (11, 1, 2, 14.50, 'BOS-WB-001'),
  (11, 2, 4, 8.50, 'NGK-SP-001'),
  (11, 3, 1, 9.80, 'CAS-BF-001'),
  (12, 1, 1, 41.00, 'BOS-BP-001'),
  (12, 2, 4, 9.20, 'DEN-SP-001'),
  (13, 1, 1, 64.00, 'BRE-BD-002'),
  (13, 2, 1, 38.50, 'BRE-BP-002'),
  (14, 1, 4, 8.50, 'NGK-SP-001'),
  (14, 2, 1, 46.00, 'BRE-BP-001'),
  (14, 3, 1, 6.00, 'BOS-AF-002'),
  (15, 1, 4, 9.20, 'DEN-SP-001'),
  (15, 2, 1, 49.00, 'NGK-OS-001'),
  (15, 3, 1, 36.00, 'CAS-EO-002'),
  (16, 1, 1, 72.00, 'BRE-BD-001'),
  (16, 2, 1, 36.00, 'CAS-EO-002'),
  (16, 3, 1, 54.00, 'DEN-OS-001'),
  (17, 1, 1, 95.00, 'BOS-BT-002'),
  (17, 2, 1, 185.00, 'DEN-AL-001'),
  (18, 1, 6, 5.20, 'DEN-OF-002'),
  (18, 2, 8, 8.50, 'NGK-SP-001'),
  (18, 3, 2, 38.50, 'BRE-BP-002'),
  (19, 1, 2, 15.00, 'BRE-BP-003'),
  (19, 2, 4, 6.50, 'CAS-EO-003'),
  (20, 1, 1, 95.00, 'BOS-BT-002'),
  (21, 1, 1, 8.90, 'DEN-AF-001'),
  (21, 2, 1, 4.80, 'DEN-OF-001'),
  (21, 3, 1, 13.00, 'BOS-WB-002'),
  (22, 1, 2, 72.00, 'BRE-BD-001'),
  (23, 1, 1, 11.50, 'BOS-AF-001'),
  (23, 2, 1, 5.20, 'DEN-OF-002'),
  (23, 3, 1, 24.00, 'CAS-EO-001'),
  (24, 1, 1, 54.00, 'DEN-OS-001'),
  (24, 2, 4, 6.90, 'BOS-SP-001'),
  (25, 1, 4, 2.80, 'NGK-SP-002'),
  (25, 2, 2, 6.50, 'CAS-EO-003'),
  (26, 1, 1, 72.00, 'BRE-BD-001'),
  (26, 2, 1, 46.00, 'BRE-BP-001'),
  (27, 1, 2, 9.80, 'CAS-BF-001'),
  (27, 2, 1, 13.00, 'BOS-WB-002'),
  (28, 1, 1, 95.00, 'BOS-BT-002'),
  (28, 2, 1, 38.00, 'NGK-IC-001'),
  (29, 1, 4, 9.20, 'DEN-SP-001'),
  (29, 2, 1, 4.80, 'DEN-OF-001'),
  (30, 1, 6, 7.50, 'BOS-OF-001'),
  (30, 2, 3, 24.00, 'CAS-EO-001'),
  (31, 1, 1, 15.00, 'BRE-BP-003'),
  (31, 2, 4, 2.80, 'NGK-SP-002'),
  (32, 1, 3, 6.50, 'CAS-EO-003'),
  (32, 2, 1, 14.50, 'BOS-WB-001');
 
-- 9/10 SHIPMENT
INSERT INTO SHIPMENT (ShipmentID, ShippingAddress, ShippingDate, DeliveryStatus, OrderID) VALUES
  (1, '88 Cách Mạng Tháng Tám, Quận 3, TP. Hồ Chí Minh', '2026-04-09', 'Delivered', 1),
  (2, '210 Quang Trung, Quận Gò Vấp, TP. Hồ Chí Minh', '2026-04-24', 'Delivered', 2),
  (3, '67 Phạm Văn Đồng, TP. Thủ Đức, TP. Hồ Chí Minh', '2026-05-16', 'Delivered', 3),
  (4, '56 Hoàng Văn Thụ, Quận Phú Nhuận, TP. Hồ Chí Minh', '2026-06-12', 'Delivered', 4),
  (5, '12 Nguyễn Văn Linh, Quận 7, TP. Hồ Chí Minh', '2026-07-03', 'Delivered', 5),
  (6, '15 Trần Hưng Đạo, Quận 1, TP. Hồ Chí Minh', '2026-07-07', 'Delivered', 6),
  (7, '9 Võ Văn Tần, Quận 3, TP. Hồ Chí Minh', '2026-07-10', 'Delivered', 7),
  (8, '134 Lý Thường Kiệt, Quận 10, TP. Hồ Chí Minh', '2026-07-16', 'Delivered', 8),
  (9, '400 Xô Viết Nghệ Tĩnh, Quận Bình Thạnh, TP. Hồ Chí Minh', '2026-07-19', 'Delivered', 9),
  (10, '23 Nguyễn Huệ, TP. Biên Hòa, Đồng Nai', '2026-07-24', 'Delivered', 10),
  (11, '88 Cách Mạng Tháng Tám, Quận 3, TP. Hồ Chí Minh', '2026-07-28', 'Delivered', 11),
  (12, '210 Quang Trung, Quận Gò Vấp, TP. Hồ Chí Minh', '2026-08-03', 'Delivered', 12),
  (13, '101 Lê Lợi, Quận Hải Châu, Đà Nẵng', '2026-08-07', 'Delivered', 13),
  (14, '12 Nguyễn Văn Linh, Quận 7, TP. Hồ Chí Minh', '2026-08-13', 'Delivered', 14),
  (15, '67 Phạm Văn Đồng, TP. Thủ Đức, TP. Hồ Chí Minh', '2026-08-17', 'Delivered', 15),
  (16, '9 Võ Văn Tần, Quận 3, TP. Hồ Chí Minh', '2026-08-23', 'Delivered', 16),
  (17, '72 Lạc Long Quân, Quận 11, TP. Hồ Chí Minh', '2026-08-26', 'Delivered', 17),
  (18, '400 Xô Viết Nghệ Tĩnh, Quận Bình Thạnh, TP. Hồ Chí Minh', '2026-09-01', 'Delivered', 18),
  (19, '78 Nguyễn Trãi, Quận Thanh Xuân, Hà Nội', '2026-09-06', 'Delivered', 19),
  (20, '160 Phan Văn Trị, Quận Bình Thạnh, TP. Hồ Chí Minh', '2026-09-19', 'Delivered', 21),
  (21, '39 Hùng Vương, TP. Thủ Dầu Một, Bình Dương', '2026-09-26', 'Cancelled', 22),
  (22, '15 Trần Hưng Đạo, Quận 1, TP. Hồ Chí Minh', '2026-10-02', 'Delivered', 23),
  (23, '88 Cách Mạng Tháng Tám, Quận 3, TP. Hồ Chí Minh', '2026-10-05', 'Delivered', 24),
  (24, '9 Võ Văn Tần, Quận 3, TP. Hồ Chí Minh', '2026-10-07', 'Delivered', 25),
  (25, '92 Tô Hiến Thành, Quận 10, TP. Hồ Chí Minh', '2026-10-11', 'Shipped', 26),
  (26, '12 Nguyễn Văn Linh, Quận 7, TP. Hồ Chí Minh', '2026-10-13', 'Delivered', 27),
  (27, '56 Hoàng Văn Thụ, Quận Phú Nhuận, TP. Hồ Chí Minh', '2026-10-17', 'Preparing', 28),
  (28, '101 Lê Lợi, Quận Hải Châu, Đà Nẵng', '2026-10-19', 'Shipped', 29),
  (29, '400 Xô Viết Nghệ Tĩnh, Quận Bình Thạnh, TP. Hồ Chí Minh', '2026-10-23', 'Shipped', 30),
  (30, '134 Lý Thường Kiệt, Quận 10, TP. Hồ Chí Minh', '2026-10-25', 'Preparing', 31);
 
-- 10/10 PAYMENT (orders 17, 26, 28, 31 are only partly paid -> Query 11)
INSERT INTO PAYMENT (PaymentID, PaymentMethod, PaymentStatus, Amount, OrderID) VALUES
  (1, 'Credit Card', 'Paid', 24.20, 1),
  (2, 'E-Wallet', 'Paid', 21.50, 2),
  (3, 'Cash on Delivery', 'Paid', 68.00, 3),
  (4, 'Bank Transfer', 'Paid', 18.50, 4),
  (5, 'Credit Card', 'Paid', 37.70, 5),
  (6, 'E-Wallet', 'Paid', 190.00, 6),
  (7, 'Cash on Delivery', 'Paid', 102.00, 7),
  (8, 'Bank Transfer', 'Paid', 118.50, 8),
  (9, 'Credit Card', 'Paid', 262.00, 9),
  (10, 'E-Wallet', 'Paid', 239.00, 10),
  (11, 'Cash on Delivery', 'Paid', 72.80, 11),
  (12, 'Bank Transfer', 'Paid', 77.80, 12),
  (13, 'Credit Card', 'Paid', 102.50, 13),
  (14, 'E-Wallet', 'Paid', 86.00, 14),
  (15, 'Cash on Delivery', 'Paid', 121.80, 15),
  (16, 'Bank Transfer', 'Paid', 162.00, 16),
  (17, 'Credit Card', 'Paid', 196.00, 17),
  (18, 'E-Wallet', 'Paid', 176.20, 18),
  (19, 'Cash on Delivery', 'Paid', 56.00, 19),
  (20, 'Credit Card', 'Failed', 95.00, 20),
  (21, 'Credit Card', 'Paid', 26.70, 21),
  (22, 'Credit Card', 'Refunded', 144.00, 22),
  (23, 'Cash on Delivery', 'Paid', 40.70, 23),
  (24, 'Bank Transfer', 'Paid', 81.60, 24),
  (25, 'Credit Card', 'Paid', 24.20, 25),
  (26, 'Bank Transfer', 'Paid', 59.00, 26),
  (27, 'Cash on Delivery', 'Paid', 32.60, 27),
  (28, 'Bank Transfer', 'Paid', 66.50, 28),
  (29, 'Credit Card', 'Paid', 41.60, 29),
  (30, 'Cash on Delivery', 'Pending', 117.00, 30),
  (31, 'Bank Transfer', 'Paid', 13.10, 31),
  (32, 'Bank Transfer', 'Pending', 34.00, 32);