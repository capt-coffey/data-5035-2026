USE ROLE DOG_DATA5035_ROLE; 
USE DATABASE DATA5035;
USE SCHEMA DOG;

-- Customers
CREATE OR REPLACE TABLE DATA5035.DOG.customers (
    customer_id INT,
    name VARCHAR(100),
    state CHAR(2)
);

INSERT INTO DATA5035.DOG.customers (customer_id, name, state)
VALUES
    (1, 'Alice', 'MO'),
    (2, 'Bob',   'IL'),
    (3, 'Carol', 'TX');

-- Orders
CREATE TABLE orders (
    order_id    INT,
    customer_id INT,
    order_date  DATE,
    amount      DECIMAL(10, 2)
);

INSERT INTO orders (order_id, customer_id, order_date, amount)
VALUES
    (101, 1, '2024-01-01', 100),
    (102, 1, '2024-01-05',  50),
    (103, 2, '2024-01-03',  75);

-- Returns
CREATE TABLE returns (
    return_id   INT,
    order_id    INT,
    return_date DATE
);

INSERT INTO returns (return_id, order_id, return_date)
VALUES
    (9001, 102, '2024-01-10');

--Q1    
SELECT 
    c.name, 
    o.order_id, 
    o.amount
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id;

--Q2
SELECT 
    c.name, 
    o.order_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;

--Q3
SELECT 
    o.order_id,
    IFF(r.order_id IS NOT NULL, TRUE, FALSE) AS is_returned
FROM orders o
LEFT JOIN returns r ON o.order_id = r.order_id;

--Q4
SELECT 
    c.name,
    o.order_id,
    r.return_date
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN returns r ON o.order_id = r.order_id;

--Q5
SELECT
    c.name
FROM customers c
 LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE order_id IS NULL;