/*
================================================================================
ARR SEMANTIC MODEL - SAMPLE DATA
================================================================================
Realistic SaaS ARR data: 20 customers, 8 products, 14 months of activity.
Period: Feb 2025 - Mar 2026
Author: Abhishek Suwalka
================================================================================
*/

USE DATABASE ARR_WAREHOUSE;
USE SCHEMA ARR_ANALYTICS;

-- ============================================================================
-- DIM_CUSTOMER (20 customers)
-- ============================================================================
INSERT INTO DIM_CUSTOMER (CUSTOMER_ID, CUSTOMER_NAME, INDUSTRY, SEGMENT, REGION, COUNTRY, ACCOUNT_OWNER, CUSTOMER_SINCE, CUSTOMER_STATUS) VALUES
('C001', 'Acme Corporation', 'Technology', 'Enterprise', 'North America', 'United States', 'James Carter', '2022-03-15', 'Active'),
('C002', 'GlobalTech Industries', 'Manufacturing', 'Enterprise', 'EMEA', 'Germany', 'Maria Lopez', '2021-08-01', 'Active'),
('C003', 'Pacific Digital Solutions', 'Technology', 'Mid-Market', 'APAC', 'Japan', 'Chen Wei', '2023-01-10', 'Active'),
('C004', 'Northwind Traders', 'Retail', 'SMB', 'North America', 'Canada', 'Sarah Johnson', '2023-06-20', 'Active'),
('C005', 'EuroFinance Group', 'Financial Services', 'Enterprise', 'EMEA', 'United Kingdom', 'Raj Patel', '2022-01-05', 'Active'),
('C006', 'Summit Healthcare', 'Healthcare', 'Enterprise', 'North America', 'United States', 'Emily Davis', '2021-11-15', 'Active'),
('C007', 'Tokyo Dynamics', 'Manufacturing', 'Mid-Market', 'APAC', 'Japan', 'Kenji Tanaka', '2023-09-01', 'Active'),
('C008', 'Berlin Analytics GmbH', 'Technology', 'Mid-Market', 'EMEA', 'Germany', 'Lisa Mueller', '2022-07-12', 'Active'),
('C009', 'CloudFirst Singapore', 'Technology', 'Enterprise', 'APAC', 'Singapore', 'David Kim', '2022-04-20', 'Active'),
('C010', 'Rio Commerce', 'Retail', 'SMB', 'LATAM', 'Brazil', 'Ana Silva', '2024-01-15', 'Active'),
('C011', 'MedTech Innovations', 'Healthcare', 'Mid-Market', 'North America', 'United States', 'James Carter', '2023-03-10', 'Active'),
('C012', 'Nordic Energy AS', 'Energy', 'Enterprise', 'EMEA', 'Norway', 'Maria Lopez', '2022-09-01', 'Active'),
('C013', 'Quantum Labs', 'Technology', 'SMB', 'North America', 'United States', 'Sarah Johnson', '2024-03-01', 'Active'),
('C014', 'Atlas Logistics', 'Transportation', 'Mid-Market', 'EMEA', 'Netherlands', 'Raj Patel', '2023-07-15', 'Active'),
('C015', 'Sydney FinTech', 'Financial Services', 'Mid-Market', 'APAC', 'Australia', 'Chen Wei', '2023-11-01', 'Active'),
('C016', 'Maple Retail Co', 'Retail', 'SMB', 'North America', 'Canada', 'Emily Davis', '2024-05-10', 'Active'),
('C017', 'SafeGuard Security', 'Technology', 'Enterprise', 'North America', 'United States', 'James Carter', '2021-06-01', 'Churned'),
('C018', 'Mumbai DataWorks', 'Technology', 'SMB', 'APAC', 'India', 'David Kim', '2024-02-15', 'Active'),
('C019', 'Paris Consulting', 'Professional Services', 'Mid-Market', 'EMEA', 'France', 'Lisa Mueller', '2023-05-20', 'Active'),
('C020', 'Santiago Mining Corp', 'Energy', 'Enterprise', 'LATAM', 'Chile', 'Ana Silva', '2022-11-01', 'Active');


-- ============================================================================
-- DIM_PRODUCT (8 products)
-- ============================================================================
INSERT INTO DIM_PRODUCT (PRODUCT_ID, PRODUCT_NAME, PRODUCT_FAMILY, PRODUCT_TIER, LIST_PRICE_ANNUAL, IS_ACTIVE, LAUNCH_DATE) VALUES
('P001', 'DataPlatform Starter', 'Platform', 'Starter', 24000.00, TRUE, '2020-01-15'),
('P002', 'DataPlatform Professional', 'Platform', 'Professional', 72000.00, TRUE, '2020-01-15'),
('P003', 'DataPlatform Enterprise', 'Platform', 'Enterprise', 180000.00, TRUE, '2020-06-01'),
('P004', 'Analytics Suite', 'Analytics', 'Professional', 48000.00, TRUE, '2021-03-01'),
('P005', 'Analytics Suite Advanced', 'Analytics', 'Enterprise', 96000.00, TRUE, '2021-09-01'),
('P006', 'SecureConnect', 'Security', 'Professional', 36000.00, TRUE, '2022-01-15'),
('P007', 'IntegrationHub', 'Integration', 'Professional', 30000.00, TRUE, '2022-06-01'),
('P008', 'IntegrationHub Enterprise', 'Integration', 'Enterprise', 60000.00, TRUE, '2023-01-01');


-- ============================================================================
-- DIM_TIME (Calendar: Jan 2024 - Dec 2026)
-- Generated for all months in range; showing key month-end dates
-- ============================================================================
INSERT INTO DIM_TIME (DATE_KEY, FULL_DATE, DAY_OF_MONTH, DAY_OF_WEEK, DAY_NAME, MONTH_NUM, MONTH_NAME, MONTH_SHORT, QUARTER_NUM, QUARTER_NAME, YEAR_NUM, YEAR_MONTH, YEAR_QUARTER, FISCAL_YEAR, FISCAL_QUARTER, IS_MONTH_END, IS_QUARTER_END, IS_YEAR_END) VALUES
-- 2025 month-end dates
(20250131, '2025-01-31', 31, 5, 'Friday', 1, 'January', 'Jan', 1, 'Q1', 2025, '2025-01', '2025-Q1', 2025, 4, TRUE, FALSE, FALSE),
(20250228, '2025-02-28', 28, 5, 'Friday', 2, 'February', 'Feb', 1, 'Q1', 2025, '2025-02', '2025-Q1', 2025, 4, TRUE, FALSE, FALSE),
(20250331, '2025-03-31', 31, 1, 'Monday', 3, 'March', 'Mar', 1, 'Q1', 2025, '2025-03', '2025-Q1', 2025, 4, TRUE, TRUE, FALSE),
(20250430, '2025-04-30', 30, 3, 'Wednesday', 4, 'April', 'Apr', 2, 'Q2', 2025, '2025-04', '2025-Q2', 2025, 1, TRUE, FALSE, FALSE),
(20250531, '2025-05-31', 31, 6, 'Saturday', 5, 'May', 'May', 2, 'Q2', 2025, '2025-05', '2025-Q2', 2025, 1, TRUE, FALSE, FALSE),
(20250630, '2025-06-30', 30, 1, 'Monday', 6, 'June', 'Jun', 2, 'Q2', 2025, '2025-06', '2025-Q2', 2025, 1, TRUE, TRUE, FALSE),
(20250731, '2025-07-31', 31, 4, 'Thursday', 7, 'July', 'Jul', 3, 'Q3', 2025, '2025-07', '2025-Q3', 2025, 2, TRUE, FALSE, FALSE),
(20250831, '2025-08-31', 31, 7, 'Sunday', 8, 'August', 'Aug', 3, 'Q3', 2025, '2025-08', '2025-Q3', 2025, 2, TRUE, FALSE, FALSE),
(20250930, '2025-09-30', 30, 2, 'Tuesday', 9, 'September', 'Sep', 3, 'Q3', 2025, '2025-09', '2025-Q3', 2025, 2, TRUE, TRUE, FALSE),
(20251031, '2025-10-31', 31, 5, 'Friday', 10, 'October', 'Oct', 4, 'Q4', 2025, '2025-10', '2025-Q4', 2025, 3, TRUE, FALSE, FALSE),
(20251130, '2025-11-30', 30, 7, 'Sunday', 11, 'November', 'Nov', 4, 'Q4', 2025, '2025-11', '2025-Q4', 2025, 3, TRUE, FALSE, FALSE),
(20251231, '2025-12-31', 31, 3, 'Wednesday', 12, 'December', 'Dec', 4, 'Q4', 2025, '2025-12', '2025-Q4', 2025, 3, TRUE, TRUE, TRUE),
-- 2026 month-end dates
(20260131, '2026-01-31', 31, 6, 'Saturday', 1, 'January', 'Jan', 1, 'Q1', 2026, '2026-01', '2026-Q1', 2026, 4, TRUE, FALSE, FALSE),
(20260228, '2026-02-28', 28, 6, 'Saturday', 2, 'February', 'Feb', 1, 'Q1', 2026, '2026-02', '2026-Q1', 2026, 4, TRUE, FALSE, FALSE),
(20260331, '2026-03-31', 31, 2, 'Tuesday', 3, 'March', 'Mar', 1, 'Q1', 2026, '2026-03', '2026-Q1', 2026, 4, TRUE, TRUE, FALSE),
-- 2025 first-of-month dates (for MOVEMENT_MONTH joins)
(20250201, '2025-02-01', 1, 6, 'Saturday', 2, 'February', 'Feb', 1, 'Q1', 2025, '2025-02', '2025-Q1', 2025, 4, FALSE, FALSE, FALSE),
(20250301, '2025-03-01', 1, 6, 'Saturday', 3, 'March', 'Mar', 1, 'Q1', 2025, '2025-03', '2025-Q1', 2025, 4, FALSE, FALSE, FALSE),
(20250401, '2025-04-01', 1, 2, 'Tuesday', 4, 'April', 'Apr', 2, 'Q2', 2025, '2025-04', '2025-Q2', 2025, 1, FALSE, FALSE, FALSE),
(20250501, '2025-05-01', 1, 4, 'Thursday', 5, 'May', 'May', 2, 'Q2', 2025, '2025-05', '2025-Q2', 2025, 1, FALSE, FALSE, FALSE),
(20250601, '2025-06-01', 1, 7, 'Sunday', 6, 'June', 'Jun', 2, 'Q2', 2025, '2025-06', '2025-Q2', 2025, 1, FALSE, FALSE, FALSE),
(20250701, '2025-07-01', 1, 2, 'Tuesday', 7, 'July', 'Jul', 3, 'Q3', 2025, '2025-07', '2025-Q3', 2025, 2, FALSE, FALSE, FALSE),
(20250801, '2025-08-01', 1, 5, 'Friday', 8, 'August', 'Aug', 3, 'Q3', 2025, '2025-08', '2025-Q3', 2025, 2, FALSE, FALSE, FALSE),
(20250901, '2025-09-01', 1, 1, 'Monday', 9, 'September', 'Sep', 3, 'Q3', 2025, '2025-09', '2025-Q3', 2025, 2, FALSE, FALSE, FALSE),
(20251001, '2025-10-01', 1, 3, 'Wednesday', 10, 'October', 'Oct', 4, 'Q4', 2025, '2025-10', '2025-Q4', 2025, 3, FALSE, FALSE, FALSE),
(20251101, '2025-11-01', 1, 6, 'Saturday', 11, 'November', 'Nov', 4, 'Q4', 2025, '2025-11', '2025-Q4', 2025, 3, FALSE, FALSE, FALSE),
(20251201, '2025-12-01', 1, 1, 'Monday', 12, 'December', 'Dec', 4, 'Q4', 2025, '2025-12', '2025-Q4', 2025, 3, FALSE, FALSE, FALSE),
(20260101, '2026-01-01', 1, 4, 'Thursday', 1, 'January', 'Jan', 1, 'Q1', 2026, '2026-01', '2026-Q1', 2026, 4, FALSE, FALSE, FALSE),
(20260201, '2026-02-01', 1, 7, 'Sunday', 2, 'February', 'Feb', 1, 'Q1', 2026, '2026-02', '2026-Q1', 2026, 4, FALSE, FALSE, FALSE),
(20260301, '2026-03-01', 1, 7, 'Sunday', 3, 'March', 'Mar', 1, 'Q1', 2026, '2026-03', '2026-Q1', 2026, 4, FALSE, FALSE, FALSE);


-- ============================================================================
-- DIM_ARR_CLASSIFICATION (6 movement types)
-- ============================================================================
INSERT INTO DIM_ARR_CLASSIFICATION (CLASSIFICATION_ID, CLASSIFICATION_NAME, CLASSIFICATION_GROUP, IMPACT_SIGN, SORT_ORDER, DESCRIPTION) VALUES
('CL01', 'New Business', 'Growth', 1, 1, 'ARR from brand new customers (first contract)'),
('CL02', 'Expansion', 'Growth', 1, 2, 'ARR increase from existing customers (upsell, cross-sell, seat expansion)'),
('CL03', 'Contraction', 'Contraction', -1, 3, 'ARR decrease from existing customers (downsell, seat reduction)'),
('CL04', 'Churn', 'Contraction', -1, 4, 'Complete ARR loss - customer cancelled all subscriptions'),
('CL05', 'Resurrection', 'Growth', 1, 5, 'ARR from previously churned customers returning'),
('CL06', 'FX Adjustment', 'Adjustment', 0, 6, 'Currency exchange rate impact on non-USD denominated ARR');


-- ============================================================================
-- FACT_CONTRACT (30 contracts)
-- ============================================================================
INSERT INTO FACT_CONTRACT (CONTRACT_ID, CUSTOMER_ID, CONTRACT_NAME, CONTRACT_STATUS, CONTRACT_START_DATE, CONTRACT_END_DATE, CONTRACT_TERM_MONTHS, TOTAL_CONTRACT_VALUE, ANNUAL_CONTRACT_VALUE, PAYMENT_FREQUENCY, SIGNED_DATE, RENEWAL_TYPE, SALES_REP) VALUES
('CON001', 'C001', 'Acme Platform Deal', 'Active', '2024-03-01', '2027-02-28', 36, 540000.00, 180000.00, 'Annual', '2024-02-15', 'Auto', 'James Carter'),
('CON002', 'C002', 'GlobalTech Enterprise', 'Active', '2024-08-01', '2026-07-31', 24, 384000.00, 192000.00, 'Annual', '2024-07-20', 'Auto', 'Maria Lopez'),
('CON003', 'C003', 'Pacific Digital Pro', 'Active', '2025-01-01', '2025-12-31', 12, 120000.00, 120000.00, 'Annual', '2024-12-10', 'Manual', 'Chen Wei'),
('CON004', 'C004', 'Northwind Starter', 'Active', '2024-07-01', '2025-06-30', 12, 54000.00, 54000.00, 'Quarterly', '2024-06-15', 'Auto', 'Sarah Johnson'),
('CON005', 'C005', 'EuroFinance Enterprise', 'Active', '2024-01-01', '2026-12-31', 36, 864000.00, 288000.00, 'Annual', '2023-12-01', 'Auto', 'Raj Patel'),
('CON006', 'C006', 'Summit HC Platform', 'Active', '2024-11-01', '2026-10-31', 24, 420000.00, 210000.00, 'Annual', '2024-10-15', 'Auto', 'Emily Davis'),
('CON007', 'C007', 'Tokyo Dynamics Pro', 'Active', '2025-03-01', '2026-02-28', 12, 78000.00, 78000.00, 'Monthly', '2025-02-20', 'Manual', 'Kenji Tanaka'),
('CON008', 'C008', 'Berlin Analytics Suite', 'Active', '2024-07-01', '2025-06-30', 12, 96000.00, 96000.00, 'Annual', '2024-06-20', 'Auto', 'Lisa Mueller'),
('CON009', 'C009', 'CloudFirst Enterprise', 'Active', '2024-04-01', '2027-03-31', 36, 720000.00, 240000.00, 'Annual', '2024-03-15', 'Auto', 'David Kim'),
('CON010', 'C010', 'Rio Commerce Starter', 'Active', '2025-01-01', '2025-12-31', 12, 24000.00, 24000.00, 'Monthly', '2024-12-20', 'Auto', 'Ana Silva'),
('CON011', 'C011', 'MedTech Analytics', 'Active', '2024-06-01', '2025-05-31', 12, 144000.00, 144000.00, 'Annual', '2024-05-10', 'Auto', 'James Carter'),
('CON012', 'C012', 'Nordic Energy Platform', 'Active', '2024-09-01', '2026-08-31', 24, 360000.00, 180000.00, 'Annual', '2024-08-15', 'Auto', 'Maria Lopez'),
('CON013', 'C013', 'Quantum Labs Starter', 'Active', '2025-03-01', '2026-02-28', 12, 24000.00, 24000.00, 'Monthly', '2025-02-25', 'Manual', 'Sarah Johnson'),
('CON014', 'C014', 'Atlas Integration', 'Active', '2024-08-01', '2025-07-31', 12, 90000.00, 90000.00, 'Annual', '2024-07-15', 'Auto', 'Raj Patel'),
('CON015', 'C015', 'Sydney FinTech Pro', 'Active', '2025-01-01', '2025-12-31', 12, 108000.00, 108000.00, 'Annual', '2024-12-01', 'Auto', 'Chen Wei'),
('CON016', 'C016', 'Maple Retail Package', 'Active', '2025-05-01', '2026-04-30', 12, 54000.00, 54000.00, 'Quarterly', '2025-04-20', 'Auto', 'Emily Davis'),
('CON017', 'C017', 'SafeGuard Enterprise', 'Terminated', '2023-06-01', '2025-05-31', 24, 480000.00, 240000.00, 'Annual', '2023-05-15', 'None', 'James Carter'),
('CON018', 'C018', 'Mumbai DataWorks SMB', 'Active', '2025-02-01', '2026-01-31', 12, 30000.00, 30000.00, 'Monthly', '2025-01-20', 'Auto', 'David Kim'),
('CON019', 'C019', 'Paris Consulting Suite', 'Active', '2024-06-01', '2025-05-31', 12, 78000.00, 78000.00, 'Annual', '2024-05-20', 'Auto', 'Lisa Mueller'),
('CON020', 'C020', 'Santiago Mining Corp', 'Active', '2024-11-01', '2026-10-31', 24, 336000.00, 168000.00, 'Annual', '2024-10-10', 'Auto', 'Ana Silva'),
-- Expansion/renewal contracts
('CON021', 'C001', 'Acme Analytics Add-on', 'Active', '2025-06-01', '2027-02-28', 21, 168000.00, 96000.00, 'Annual', '2025-05-15', 'Auto', 'James Carter'),
('CON022', 'C005', 'EuroFinance Security', 'Active', '2025-04-01', '2026-12-31', 21, 63000.00, 36000.00, 'Annual', '2025-03-20', 'Auto', 'Raj Patel'),
('CON023', 'C008', 'Berlin Upgrade to Enterprise', 'Active', '2025-07-01', '2026-06-30', 12, 180000.00, 180000.00, 'Annual', '2025-06-15', 'Auto', 'Lisa Mueller'),
('CON024', 'C003', 'Pacific Expansion', 'Active', '2025-07-01', '2026-06-30', 12, 48000.00, 48000.00, 'Annual', '2025-06-20', 'Auto', 'Chen Wei'),
('CON025', 'C009', 'CloudFirst Integration', 'Active', '2025-09-01', '2027-03-31', 19, 95000.00, 60000.00, 'Annual', '2025-08-20', 'Auto', 'David Kim'),
('CON026', 'C012', 'Nordic Security Add-on', 'Active', '2025-10-01', '2026-08-31', 11, 33000.00, 36000.00, 'Annual', '2025-09-15', 'Auto', 'Maria Lopez'),
('CON027', 'C004', 'Northwind Upgrade', 'Active', '2025-07-01', '2026-06-30', 12, 72000.00, 72000.00, 'Quarterly', '2025-06-10', 'Auto', 'Sarah Johnson'),
('CON028', 'C011', 'MedTech Renewal + Expand', 'Active', '2025-06-01', '2026-05-31', 12, 192000.00, 192000.00, 'Annual', '2025-05-20', 'Auto', 'James Carter'),
('CON029', 'C019', 'Paris Consulting Renewal', 'Active', '2025-06-01', '2026-05-31', 12, 78000.00, 78000.00, 'Annual', '2025-05-25', 'Auto', 'Lisa Mueller'),
('CON030', 'C015', 'Sydney Expansion', 'Active', '2025-08-01', '2026-07-31', 12, 48000.00, 48000.00, 'Annual', '2025-07-15', 'Auto', 'Chen Wei');


-- ============================================================================
-- FACT_CONTRACT_LINE (35 line items)
-- ============================================================================
INSERT INTO FACT_CONTRACT_LINE (CONTRACT_LINE_ID, CONTRACT_ID, PRODUCT_ID, LINE_STATUS, QUANTITY, UNIT_PRICE_ANNUAL, DISCOUNT_PERCENT, LINE_ARR, LINE_START_DATE, LINE_END_DATE) VALUES
('CL001', 'CON001', 'P003', 'Active', 1, 180000.00, 0, 180000.00, '2024-03-01', '2027-02-28'),
('CL002', 'CON002', 'P003', 'Active', 1, 180000.00, 0, 180000.00, '2024-08-01', '2026-07-31'),
('CL003', 'CON002', 'P006', 'Active', 1, 36000.00, 16.67, 30000.00, '2024-08-01', '2026-07-31'),
('CL004', 'CON003', 'P002', 'Active', 1, 72000.00, 0, 72000.00, '2025-01-01', '2025-12-31'),
('CL005', 'CON003', 'P004', 'Active', 1, 48000.00, 0, 48000.00, '2025-01-01', '2025-12-31'),
('CL006', 'CON004', 'P001', 'Upgraded', 1, 24000.00, 0, 24000.00, '2024-07-01', '2025-06-30'),
('CL007', 'CON004', 'P007', 'Active', 1, 30000.00, 0, 30000.00, '2024-07-01', '2025-06-30'),
('CL008', 'CON005', 'P003', 'Active', 1, 180000.00, 0, 180000.00, '2024-01-01', '2026-12-31'),
('CL009', 'CON005', 'P005', 'Active', 1, 96000.00, 0, 96000.00, '2024-01-01', '2026-12-31'),
('CL010', 'CON006', 'P003', 'Active', 1, 180000.00, 16.67, 150000.00, '2024-11-01', '2026-10-31'),
('CL011', 'CON006', 'P008', 'Active', 1, 60000.00, 0, 60000.00, '2024-11-01', '2026-10-31'),
('CL012', 'CON007', 'P002', 'Active', 1, 72000.00, 0, 72000.00, '2025-03-01', '2026-02-28'),
('CL013', 'CON008', 'P005', 'Upgraded', 1, 96000.00, 0, 96000.00, '2024-07-01', '2025-06-30'),
('CL014', 'CON009', 'P003', 'Active', 1, 180000.00, 0, 180000.00, '2024-04-01', '2027-03-31'),
('CL015', 'CON009', 'P008', 'Active', 1, 60000.00, 0, 60000.00, '2024-04-01', '2027-03-31'),
('CL016', 'CON010', 'P001', 'Active', 1, 24000.00, 0, 24000.00, '2025-01-01', '2025-12-31'),
('CL017', 'CON011', 'P005', 'Active', 1, 96000.00, 0, 96000.00, '2024-06-01', '2025-05-31'),
('CL018', 'CON011', 'P004', 'Active', 1, 48000.00, 0, 48000.00, '2024-06-01', '2025-05-31'),
('CL019', 'CON012', 'P003', 'Active', 1, 180000.00, 0, 180000.00, '2024-09-01', '2026-08-31'),
('CL020', 'CON013', 'P001', 'Active', 1, 24000.00, 0, 24000.00, '2025-03-01', '2026-02-28'),
('CL021', 'CON014', 'P008', 'Active', 1, 60000.00, 0, 60000.00, '2024-08-01', '2025-07-31'),
('CL022', 'CON014', 'P007', 'Active', 1, 30000.00, 0, 30000.00, '2024-08-01', '2025-07-31'),
('CL023', 'CON015', 'P002', 'Active', 1, 72000.00, 0, 72000.00, '2025-01-01', '2025-12-31'),
('CL024', 'CON015', 'P006', 'Active', 1, 36000.00, 0, 36000.00, '2025-01-01', '2025-12-31'),
('CL025', 'CON017', 'P003', 'Cancelled', 1, 180000.00, 0, 180000.00, '2023-06-01', '2025-05-31'),
('CL026', 'CON017', 'P008', 'Cancelled', 1, 60000.00, 0, 60000.00, '2023-06-01', '2025-05-31'),
('CL027', 'CON018', 'P007', 'Active', 1, 30000.00, 0, 30000.00, '2025-02-01', '2026-01-31'),
('CL028', 'CON019', 'P002', 'Active', 1, 72000.00, 0, 72000.00, '2024-06-01', '2025-05-31'),
('CL029', 'CON020', 'P003', 'Active', 1, 180000.00, 6.67, 168000.00, '2024-11-01', '2026-10-31'),
('CL030', 'CON021', 'P005', 'Active', 1, 96000.00, 0, 96000.00, '2025-06-01', '2027-02-28'),
('CL031', 'CON022', 'P006', 'Active', 1, 36000.00, 0, 36000.00, '2025-04-01', '2026-12-31'),
('CL032', 'CON023', 'P003', 'Active', 1, 180000.00, 0, 180000.00, '2025-07-01', '2026-06-30'),
('CL033', 'CON024', 'P004', 'Active', 1, 48000.00, 0, 48000.00, '2025-07-01', '2026-06-30'),
('CL034', 'CON025', 'P008', 'Active', 1, 60000.00, 0, 60000.00, '2025-09-01', '2027-03-31'),
('CL035', 'CON027', 'P002', 'Active', 1, 72000.00, 0, 72000.00, '2025-07-01', '2026-06-30');


-- ============================================================================
-- FACT_SUBSCRIPTION (35 subscriptions matching contract lines)
-- ============================================================================
INSERT INTO FACT_SUBSCRIPTION (SUBSCRIPTION_ID, CUSTOMER_ID, CONTRACT_LINE_ID, PRODUCT_ID, SUBSCRIPTION_STATUS, START_DATE, END_DATE, MRR, ARR, QUANTITY, AUTO_RENEW, CANCELLATION_DATE, CANCELLATION_REASON) VALUES
('SUB001', 'C001', 'CL001', 'P003', 'Active', '2024-03-01', '2027-02-28', 15000.00, 180000.00, 1, TRUE, NULL, NULL),
('SUB002', 'C002', 'CL002', 'P003', 'Active', '2024-08-01', '2026-07-31', 15000.00, 180000.00, 1, TRUE, NULL, NULL),
('SUB003', 'C002', 'CL003', 'P006', 'Active', '2024-08-01', '2026-07-31', 2500.00, 30000.00, 1, TRUE, NULL, NULL),
('SUB004', 'C003', 'CL004', 'P002', 'Active', '2025-01-01', '2025-12-31', 6000.00, 72000.00, 1, FALSE, NULL, NULL),
('SUB005', 'C003', 'CL005', 'P004', 'Active', '2025-01-01', '2025-12-31', 4000.00, 48000.00, 1, FALSE, NULL, NULL),
('SUB006', 'C004', 'CL006', 'P001', 'Cancelled', '2024-07-01', '2025-06-30', 2000.00, 24000.00, 1, TRUE, '2025-06-30', 'Upgraded to Professional'),
('SUB007', 'C004', 'CL007', 'P007', 'Active', '2024-07-01', '2025-06-30', 2500.00, 30000.00, 1, TRUE, NULL, NULL),
('SUB008', 'C005', 'CL008', 'P003', 'Active', '2024-01-01', '2026-12-31', 15000.00, 180000.00, 1, TRUE, NULL, NULL),
('SUB009', 'C005', 'CL009', 'P005', 'Active', '2024-01-01', '2026-12-31', 8000.00, 96000.00, 1, TRUE, NULL, NULL),
('SUB010', 'C006', 'CL010', 'P003', 'Active', '2024-11-01', '2026-10-31', 12500.00, 150000.00, 1, TRUE, NULL, NULL),
('SUB011', 'C006', 'CL011', 'P008', 'Active', '2024-11-01', '2026-10-31', 5000.00, 60000.00, 1, TRUE, NULL, NULL),
('SUB012', 'C007', 'CL012', 'P002', 'Active', '2025-03-01', '2026-02-28', 6000.00, 72000.00, 1, FALSE, NULL, NULL),
('SUB013', 'C008', 'CL013', 'P005', 'Cancelled', '2024-07-01', '2025-06-30', 8000.00, 96000.00, 1, TRUE, '2025-06-30', 'Upgraded to Enterprise Platform'),
('SUB014', 'C009', 'CL014', 'P003', 'Active', '2024-04-01', '2027-03-31', 15000.00, 180000.00, 1, TRUE, NULL, NULL),
('SUB015', 'C009', 'CL015', 'P008', 'Active', '2024-04-01', '2027-03-31', 5000.00, 60000.00, 1, TRUE, NULL, NULL),
('SUB016', 'C010', 'CL016', 'P001', 'Active', '2025-01-01', '2025-12-31', 2000.00, 24000.00, 1, TRUE, NULL, NULL),
('SUB017', 'C011', 'CL017', 'P005', 'Active', '2024-06-01', '2025-05-31', 8000.00, 96000.00, 1, TRUE, NULL, NULL),
('SUB018', 'C011', 'CL018', 'P004', 'Active', '2024-06-01', '2025-05-31', 4000.00, 48000.00, 1, TRUE, NULL, NULL),
('SUB019', 'C012', 'CL019', 'P003', 'Active', '2024-09-01', '2026-08-31', 15000.00, 180000.00, 1, TRUE, NULL, NULL),
('SUB020', 'C013', 'CL020', 'P001', 'Active', '2025-03-01', '2026-02-28', 2000.00, 24000.00, 1, FALSE, NULL, NULL),
('SUB021', 'C014', 'CL021', 'P008', 'Active', '2024-08-01', '2025-07-31', 5000.00, 60000.00, 1, TRUE, NULL, NULL),
('SUB022', 'C014', 'CL022', 'P007', 'Active', '2024-08-01', '2025-07-31', 2500.00, 30000.00, 1, TRUE, NULL, NULL),
('SUB023', 'C015', 'CL023', 'P002', 'Active', '2025-01-01', '2025-12-31', 6000.00, 72000.00, 1, TRUE, NULL, NULL),
('SUB024', 'C015', 'CL024', 'P006', 'Active', '2025-01-01', '2025-12-31', 3000.00, 36000.00, 1, TRUE, NULL, NULL),
('SUB025', 'C017', 'CL025', 'P003', 'Cancelled', '2023-06-01', '2025-05-31', 15000.00, 180000.00, 1, FALSE, '2025-05-31', 'Customer churned - budget cuts'),
('SUB026', 'C017', 'CL026', 'P008', 'Cancelled', '2023-06-01', '2025-05-31', 5000.00, 60000.00, 1, FALSE, '2025-05-31', 'Customer churned - budget cuts'),
('SUB027', 'C018', 'CL027', 'P007', 'Active', '2025-02-01', '2026-01-31', 2500.00, 30000.00, 1, TRUE, NULL, NULL),
('SUB028', 'C019', 'CL028', 'P002', 'Active', '2024-06-01', '2025-05-31', 6000.00, 72000.00, 1, TRUE, NULL, NULL),
('SUB029', 'C020', 'CL029', 'P003', 'Active', '2024-11-01', '2026-10-31', 14000.00, 168000.00, 1, TRUE, NULL, NULL),
('SUB030', 'C001', 'CL030', 'P005', 'Active', '2025-06-01', '2027-02-28', 8000.00, 96000.00, 1, TRUE, NULL, NULL),
('SUB031', 'C005', 'CL031', 'P006', 'Active', '2025-04-01', '2026-12-31', 3000.00, 36000.00, 1, TRUE, NULL, NULL),
('SUB032', 'C008', 'CL032', 'P003', 'Active', '2025-07-01', '2026-06-30', 15000.00, 180000.00, 1, TRUE, NULL, NULL),
('SUB033', 'C003', 'CL033', 'P004', 'Active', '2025-07-01', '2026-06-30', 4000.00, 48000.00, 1, TRUE, NULL, NULL),
('SUB034', 'C009', 'CL034', 'P008', 'Active', '2025-09-01', '2027-03-31', 5000.00, 60000.00, 1, TRUE, NULL, NULL),
('SUB035', 'C004', 'CL035', 'P002', 'Active', '2025-07-01', '2026-06-30', 6000.00, 72000.00, 1, TRUE, NULL, NULL);


-- ============================================================================
-- FACT_ARR_MONTHLY_SNAPSHOT (14 months: Feb 2025 - Mar 2026)
-- Showing customer-level monthly ARR state
-- ============================================================================
INSERT INTO FACT_ARR_MONTHLY_SNAPSHOT (SNAPSHOT_ID, SNAPSHOT_DATE, DATE_KEY, CUSTOMER_ID, PRODUCT_ID, SUBSCRIPTION_ID, ARR_AMOUNT, MRR_AMOUNT, QUANTITY, CURRENCY_CODE) VALUES
-- Feb 2025
('SNAP-202502-C001', '2025-02-28', 20250228, 'C001', 'P003', 'SUB001', 180000.00, 15000.00, 1, 'USD'),
('SNAP-202502-C002', '2025-02-28', 20250228, 'C002', 'P003', 'SUB002', 180000.00, 15000.00, 1, 'USD'),
('SNAP-202502-C002B', '2025-02-28', 20250228, 'C002', 'P006', 'SUB003', 30000.00, 2500.00, 1, 'USD'),
('SNAP-202502-C003', '2025-02-28', 20250228, 'C003', 'P002', 'SUB004', 72000.00, 6000.00, 1, 'USD'),
('SNAP-202502-C003B', '2025-02-28', 20250228, 'C003', 'P004', 'SUB005', 48000.00, 4000.00, 1, 'USD'),
('SNAP-202502-C004', '2025-02-28', 20250228, 'C004', 'P001', 'SUB006', 24000.00, 2000.00, 1, 'USD'),
('SNAP-202502-C004B', '2025-02-28', 20250228, 'C004', 'P007', 'SUB007', 30000.00, 2500.00, 1, 'USD'),
('SNAP-202502-C005', '2025-02-28', 20250228, 'C005', 'P003', 'SUB008', 180000.00, 15000.00, 1, 'USD'),
('SNAP-202502-C005B', '2025-02-28', 20250228, 'C005', 'P005', 'SUB009', 96000.00, 8000.00, 1, 'USD'),
('SNAP-202502-C006', '2025-02-28', 20250228, 'C006', 'P003', 'SUB010', 150000.00, 12500.00, 1, 'USD'),
('SNAP-202502-C006B', '2025-02-28', 20250228, 'C006', 'P008', 'SUB011', 60000.00, 5000.00, 1, 'USD'),
('SNAP-202502-C008', '2025-02-28', 20250228, 'C008', 'P005', 'SUB013', 96000.00, 8000.00, 1, 'USD'),
('SNAP-202502-C009', '2025-02-28', 20250228, 'C009', 'P003', 'SUB014', 180000.00, 15000.00, 1, 'USD'),
('SNAP-202502-C009B', '2025-02-28', 20250228, 'C009', 'P008', 'SUB015', 60000.00, 5000.00, 1, 'USD'),
('SNAP-202502-C010', '2025-02-28', 20250228, 'C010', 'P001', 'SUB016', 24000.00, 2000.00, 1, 'USD'),
('SNAP-202502-C011', '2025-02-28', 20250228, 'C011', 'P005', 'SUB017', 96000.00, 8000.00, 1, 'USD'),
('SNAP-202502-C011B', '2025-02-28', 20250228, 'C011', 'P004', 'SUB018', 48000.00, 4000.00, 1, 'USD'),
('SNAP-202502-C012', '2025-02-28', 20250228, 'C012', 'P003', 'SUB019', 180000.00, 15000.00, 1, 'USD'),
('SNAP-202502-C014', '2025-02-28', 20250228, 'C014', 'P008', 'SUB021', 60000.00, 5000.00, 1, 'USD'),
('SNAP-202502-C014B', '2025-02-28', 20250228, 'C014', 'P007', 'SUB022', 30000.00, 2500.00, 1, 'USD'),
('SNAP-202502-C015', '2025-02-28', 20250228, 'C015', 'P002', 'SUB023', 72000.00, 6000.00, 1, 'USD'),
('SNAP-202502-C015B', '2025-02-28', 20250228, 'C015', 'P006', 'SUB024', 36000.00, 3000.00, 1, 'USD'),
('SNAP-202502-C017', '2025-02-28', 20250228, 'C017', 'P003', 'SUB025', 180000.00, 15000.00, 1, 'USD'),
('SNAP-202502-C017B', '2025-02-28', 20250228, 'C017', 'P008', 'SUB026', 60000.00, 5000.00, 1, 'USD'),
('SNAP-202502-C018', '2025-02-28', 20250228, 'C018', 'P007', 'SUB027', 30000.00, 2500.00, 1, 'USD'),
('SNAP-202502-C019', '2025-02-28', 20250228, 'C019', 'P002', 'SUB028', 72000.00, 6000.00, 1, 'USD'),
('SNAP-202502-C020', '2025-02-28', 20250228, 'C020', 'P003', 'SUB029', 168000.00, 14000.00, 1, 'USD');


-- ============================================================================
-- FACT_ARR_MOVEMENT (ARR changes Feb 2025 - Mar 2026)
-- ============================================================================
INSERT INTO FACT_ARR_MOVEMENT (MOVEMENT_ID, MOVEMENT_MONTH, DATE_KEY, CUSTOMER_ID, PRODUCT_ID, CLASSIFICATION_ID, PRIOR_ARR, CURRENT_ARR, ARR_DELTA, MOVEMENT_REASON) VALUES
-- Mar 2025: New customers + expansion
('MOV-202503-001', '2025-03-01', 20250301, 'C007', 'P002', 'CL01', 0, 72000.00, 72000.00, 'New customer - Tokyo Dynamics'),
('MOV-202503-002', '2025-03-01', 20250301, 'C013', 'P001', 'CL01', 0, 24000.00, 24000.00, 'New customer - Quantum Labs'),
-- Apr 2025: Expansion
('MOV-202504-001', '2025-04-01', 20250401, 'C005', 'P006', 'CL02', 276000.00, 312000.00, 36000.00, 'Added SecureConnect'),
-- May 2025: Contraction + New
('MOV-202505-001', '2025-05-01', 20250501, 'C016', 'P001', 'CL01', 0, 24000.00, 24000.00, 'New customer - Maple Retail'),
('MOV-202505-002', '2025-05-01', 20250501, 'C016', 'P007', 'CL01', 0, 30000.00, 30000.00, 'New customer - Maple Retail IntegrationHub'),
-- Jun 2025: Churn + Expansion
('MOV-202506-001', '2025-06-01', 20250601, 'C017', 'P003', 'CL04', 180000.00, 0, -180000.00, 'Customer churned - budget cuts'),
('MOV-202506-002', '2025-06-01', 20250601, 'C017', 'P008', 'CL04', 60000.00, 0, -60000.00, 'Customer churned - budget cuts'),
('MOV-202506-003', '2025-06-01', 20250601, 'C001', 'P005', 'CL02', 180000.00, 276000.00, 96000.00, 'Added Analytics Suite Advanced'),
('MOV-202506-004', '2025-06-01', 20250601, 'C011', 'P005', 'CL02', 144000.00, 192000.00, 48000.00, 'MedTech renewal with expansion'),
-- Jul 2025: Upgrades + Expansion
('MOV-202507-001', '2025-07-01', 20250701, 'C008', 'P003', 'CL02', 96000.00, 180000.00, 84000.00, 'Upgraded from Analytics to Enterprise Platform'),
('MOV-202507-002', '2025-07-01', 20250701, 'C003', 'P004', 'CL02', 120000.00, 168000.00, 48000.00, 'Added Analytics Suite'),
('MOV-202507-003', '2025-07-01', 20250701, 'C004', 'P002', 'CL02', 54000.00, 102000.00, 48000.00, 'Upgraded Starter to Professional'),
('MOV-202507-004', '2025-07-01', 20250701, 'C004', 'P001', 'CL03', 24000.00, 0, -24000.00, 'Starter cancelled (upgrade)'),
-- Aug 2025: Contraction
('MOV-202508-001', '2025-08-01', 20250801, 'C015', 'P006', 'CL03', 108000.00, 72000.00, -36000.00, 'Dropped SecureConnect'),
('MOV-202508-002', '2025-08-01', 20250801, 'C015', 'P004', 'CL02', 72000.00, 120000.00, 48000.00, 'Added Analytics Suite'),
-- Sep 2025: Expansion
('MOV-202509-001', '2025-09-01', 20250901, 'C009', 'P008', 'CL02', 240000.00, 300000.00, 60000.00, 'Added IntegrationHub Enterprise'),
-- Oct 2025: Expansion + FX
('MOV-202510-001', '2025-10-01', 20251001, 'C012', 'P006', 'CL02', 180000.00, 216000.00, 36000.00, 'Added SecureConnect'),
('MOV-202510-002', '2025-10-01', 20251001, 'C020', 'P003', 'CL06', 168000.00, 162000.00, -6000.00, 'FX adjustment - BRL weakening'),
-- Nov 2025: Contraction
('MOV-202511-001', '2025-11-01', 20251101, 'C014', 'P007', 'CL03', 90000.00, 60000.00, -30000.00, 'Dropped IntegrationHub - consolidated to Enterprise'),
-- Dec 2025: FX + Expansion
('MOV-202512-001', '2025-12-01', 20251201, 'C002', 'P003', 'CL06', 210000.00, 207000.00, -3000.00, 'FX adjustment - EUR movement'),
('MOV-202512-002', '2025-12-01', 20251201, 'C006', 'P003', 'CL02', 210000.00, 246000.00, 36000.00, 'Added seats to Platform'),
-- Jan 2026: New + Contraction
('MOV-202601-001', '2026-01-01', 20260101, 'C010', 'P001', 'CL03', 24000.00, 18000.00, -6000.00, 'Reduced seats'),
('MOV-202601-002', '2026-01-01', 20260101, 'C019', 'P004', 'CL02', 72000.00, 120000.00, 48000.00, 'Added Analytics Suite'),
-- Feb 2026: Resurrection
('MOV-202602-001', '2026-02-01', 20260201, 'C017', 'P002', 'CL05', 0, 72000.00, 72000.00, 'Customer returned - new budget approved'),
-- Mar 2026: Growth
('MOV-202603-001', '2026-03-01', 20260301, 'C009', 'P005', 'CL02', 300000.00, 396000.00, 96000.00, 'Added Analytics Suite Advanced'),
('MOV-202603-002', '2026-03-01', 20260301, 'C018', 'P001', 'CL02', 30000.00, 54000.00, 24000.00, 'Added DataPlatform Starter (2nd unit)');


-- ============================================================================
-- FACT_ARR_ADJUSTMENT
-- ============================================================================
INSERT INTO FACT_ARR_ADJUSTMENT (ADJUSTMENT_ID, ADJUSTMENT_DATE, DATE_KEY, CUSTOMER_ID, ADJUSTMENT_TYPE, ADJUSTMENT_REASON, ARR_AMOUNT, APPROVED_BY) VALUES
('ADJ001', '2025-06-15', 20250601, 'C002', 'FX', 'EUR/USD rate adjustment Q2', -5000.00, 'Finance Team'),
('ADJ002', '2025-09-30', 20250901, 'C020', 'FX', 'BRL/USD rate adjustment Q3', -8000.00, 'Finance Team'),
('ADJ003', '2025-10-15', 20251001, 'C003', 'Credit', 'Service credit applied for downtime', -12000.00, 'VP Customer Success'),
('ADJ004', '2025-12-31', 20251201, 'C012', 'FX', 'NOK/USD year-end adjustment', 4000.00, 'Finance Team'),
('ADJ005', '2026-01-15', 20260101, 'C005', 'Correction', 'Billing error correction from Q3', 15000.00, 'Revenue Operations'),
('ADJ006', '2026-03-01', 20260301, 'C007', 'FX', 'JPY/USD adjustment', -3000.00, 'Finance Team');


-- ============================================================================
-- FACT_ARR_METRICS (Monthly pre-aggregated: Feb 2025 - Mar 2026)
-- ============================================================================
INSERT INTO FACT_ARR_METRICS (METRIC_MONTH, DATE_KEY, BEGINNING_ARR, NEW_BUSINESS_ARR, EXPANSION_ARR, CONTRACTION_ARR, CHURN_ARR, RESURRECTION_ARR, FX_ADJUSTMENT_ARR, NET_NEW_ARR, ENDING_ARR, GROSS_RETENTION_RATE, NET_RETENTION_RATE, CUSTOMER_COUNT, NEW_CUSTOMERS, CHURNED_CUSTOMERS, LOGO_RETENTION_RATE) VALUES
('2025-02-01', 20250201, 2376000.00, 0, 0, 0, 0, 0, 0, 0, 2376000.00, 1.0000, 1.0000, 17, 0, 0, 1.0000),
('2025-03-01', 20250301, 2376000.00, 96000.00, 0, 0, 0, 0, 0, 96000.00, 2472000.00, 1.0000, 1.0000, 19, 2, 0, 1.0000),
('2025-04-01', 20250401, 2472000.00, 0, 36000.00, 0, 0, 0, 0, 36000.00, 2508000.00, 1.0000, 1.0146, 19, 0, 0, 1.0000),
('2025-05-01', 20250501, 2508000.00, 54000.00, 0, 0, 0, 0, 0, 54000.00, 2562000.00, 1.0000, 1.0000, 20, 1, 0, 1.0000),
('2025-06-01', 20250601, 2562000.00, 0, 144000.00, 0, -240000.00, 0, -5000.00, -101000.00, 2461000.00, 0.9063, 0.9625, 19, 0, 1, 0.9500),
('2025-07-01', 20250701, 2461000.00, 0, 180000.00, -24000.00, 0, 0, 0, 156000.00, 2617000.00, 0.9902, 1.0634, 19, 0, 0, 1.0000),
('2025-08-01', 20250801, 2617000.00, 0, 48000.00, -36000.00, 0, 0, 0, 12000.00, 2629000.00, 0.9862, 1.0046, 19, 0, 0, 1.0000),
('2025-09-01', 20250901, 2629000.00, 0, 60000.00, 0, 0, 0, -8000.00, 52000.00, 2681000.00, 0.9970, 1.0198, 19, 0, 0, 1.0000),
('2025-10-01', 20251001, 2681000.00, 0, 36000.00, 0, 0, 0, -6000.00, 30000.00, 2711000.00, 0.9978, 1.0112, 19, 0, 0, 1.0000),
('2025-11-01', 20251101, 2711000.00, 0, 0, -30000.00, 0, 0, 0, -30000.00, 2681000.00, 0.9889, 0.9889, 19, 0, 0, 1.0000),
('2025-12-01', 20251201, 2681000.00, 0, 36000.00, 0, 0, 0, -3000.00, 33000.00, 2714000.00, 0.9989, 1.0123, 19, 0, 0, 1.0000),
('2026-01-01', 20260101, 2714000.00, 0, 48000.00, -6000.00, 0, 0, 0, 42000.00, 2756000.00, 0.9978, 1.0155, 19, 0, 0, 1.0000),
('2026-02-01', 20260201, 2756000.00, 0, 0, 0, 0, 72000.00, 0, 72000.00, 2828000.00, 1.0000, 1.0261, 20, 0, 0, 1.0000),
('2026-03-01', 20260301, 2828000.00, 0, 120000.00, 0, 0, 0, -3000.00, 117000.00, 2945000.00, 0.9989, 1.0414, 20, 0, 0, 1.0000);


-- ============================================================================
-- FACT_ARR_FINAL_METRICS (Quarterly + Annual rollups)
-- ============================================================================
INSERT INTO FACT_ARR_FINAL_METRICS (PERIOD_KEY, PERIOD_TYPE, PERIOD_START_DATE, PERIOD_END_DATE, BEGINNING_ARR, ENDING_ARR, NET_NEW_ARR, ARR_GROWTH_RATE, GROSS_RETENTION_RATE, NET_RETENTION_RATE, LOGO_RETENTION_RATE, AVG_ARR_PER_CUSTOMER, TOTAL_CUSTOMERS, NEW_LOGOS, CHURNED_LOGOS, QUICK_RATIO) VALUES
('2025-Q1', 'Quarter', '2025-01-01', '2025-03-31', 2376000.00, 2472000.00, 96000.00, 0.0404, 1.0000, 1.0404, 1.0000, 130105.00, 19, 2, 0, NULL),
('2025-Q2', 'Quarter', '2025-04-01', '2025-06-30', 2472000.00, 2461000.00, -11000.00, -0.0044, 0.9028, 0.9955, 0.9500, 129526.00, 19, 1, 1, 0.8163),
('2025-Q3', 'Quarter', '2025-07-01', '2025-09-30', 2461000.00, 2681000.00, 220000.00, 0.0894, 0.9770, 1.0894, 1.0000, 141105.00, 19, 0, 0, 4.8000),
('2025-Q4', 'Quarter', '2025-10-01', '2025-12-31', 2681000.00, 2714000.00, 33000.00, 0.0123, 0.9877, 1.0123, 1.0000, 142842.00, 19, 0, 0, 2.4000),
('2026-Q1', 'Quarter', '2026-01-01', '2026-03-31', 2714000.00, 2945000.00, 231000.00, 0.0851, 0.9978, 1.0851, 1.0000, 147250.00, 20, 0, 0, 40.0000),
('2025', 'Annual', '2025-01-01', '2025-12-31', 2376000.00, 2714000.00, 338000.00, 0.1423, 0.9494, 1.1423, 0.9500, 142842.00, 19, 3, 1, 2.5238);
