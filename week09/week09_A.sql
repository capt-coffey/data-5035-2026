USE ROLE DOG_DATA5035_ROLE; 
USE DATABASE DATA5035;
USE SCHEMA DOG;

-- ============================================================
-- Scenario A: Customer Orders & Returns
-- Approach: Uses a combination of INNER JOINs, LEFT JOINs, and
-- an anti-join pattern to analyze customer purchasing behavior.
-- Tables: customers, orders, returns
-- ============================================================

-- Create and populate base tables

CREATE OR REPLACE TABLE DATA5035.DOG.customers (
    customer_id INT,
    name        VARCHAR(100),
    state       CHAR(2)
);

INSERT INTO DATA5035.DOG.customers (customer_id, name, state)
VALUES
    (1, 'Alice', 'MO'),
    (2, 'Bob',   'IL'),
    (3, 'Carol', 'TX');

CREATE OR REPLACE TABLE DATA5035.DOG.orders (
    order_id    INT,
    customer_id INT,
    order_date  DATE,
    amount      DECIMAL(10, 2)
);

INSERT INTO DATA5035.DOG.orders (order_id, customer_id, order_date, amount)
VALUES
    (101, 1, '2024-01-01', 100),
    (102, 1, '2024-01-05',  50),
    (103, 2, '2024-01-03',  75);

CREATE OR REPLACE TABLE DATA5035.DOG.returns (
    return_id   INT,
    order_id    INT,
    return_date DATE
);

INSERT INTO DATA5035.DOG.returns (return_id, order_id, return_date)
VALUES
    (9001, 102, '2024-01-10');

-- ============================================================
-- Q1: Show all purchases with the customer who made them
-- Join type: INNER JOIN
-- Assumption: Only customers with at least one order are returned
-- ============================================================
SELECT 
    c.name, 
    o.order_id, 
    o.amount
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id;

-- ============================================================
-- Q2: Show all customers and any orders they may have placed
-- Join type: LEFT JOIN
-- Assumption: All customers are returned, even those without orders
-- ============================================================
SELECT 
    c.name, 
    o.order_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;

-- ============================================================
-- Q3: Identify whether each order was returned
-- Join type: LEFT JOIN
-- Assumption: All orders are included; flagged TRUE if a matching
-- return exists, FALSE if not
-- ============================================================
SELECT 
    o.order_id,
    IFF(r.order_id IS NOT NULL, TRUE, FALSE) AS is_returned
FROM orders o
LEFT JOIN returns r ON o.order_id = r.order_id;

-- ============================================================
-- Q4: Show only orders that were returned and who made them
-- Join type: INNER JOIN
-- Assumption: Only orders with a matching return record are included
-- ============================================================
SELECT 
    c.name,
    o.order_id,
    r.return_date
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN returns r ON o.order_id = r.order_id;

-- ============================================================
-- Q5: Find customers who have never made a purchase
-- Join type: LEFT JOIN (anti-join pattern)
-- Assumption: Customers with no matching order_id in orders are
-- returned; NULL in order_id indicates no purchase was made
-- ============================================================
SELECT
    c.name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;