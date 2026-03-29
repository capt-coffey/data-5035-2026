USE ROLE DOG_DATA5035_ROLE; 
USE DATABASE DATA5035;
USE SCHEMA DOG;

-- Batches
CREATE TABLE batches (
    batch_id  VARCHAR(10),
    product   VARCHAR(100),
    facility  VARCHAR(100)
);

INSERT INTO batches (batch_id, product, facility)
VALUES
    ('B1', 'DrugA', 'Plant1'),
    ('B2', 'DrugA', 'Plant2'),
    ('B3', 'DrugB', 'Plant1');

-- Quality Tests
CREATE TABLE quality_tests (
    test_id   VARCHAR(10),
    batch_id  VARCHAR(10),
    test_type VARCHAR(100),
    result    VARCHAR(10)
);

INSERT INTO tests (test_id, batch_id, test_type, result)
VALUES
    ('T1', 'B1', 'purity',    'pass'),
    ('T2', 'B1', 'stability', 'fail'),
    ('T3', 'B2', 'purity',    'pass');

-- Deviations
CREATE TABLE deviations (
    deviation_id VARCHAR(10),
    batch_id     VARCHAR(10),
    description  VARCHAR(255)
);

INSERT INTO deviations (deviation_id, batch_id, description)
VALUES
    ('D1', 'B1', 'temperature excursion');

-- Q1
SELECT
    b.batch_id,
    t.test_type,
    t.result
FROM batches b
INNER JOIN quality_tests t ON b.batch_id = t.batch_id;

-- Q2
SELECT
    b.batch_id,
    t.test_type,
    t.result
FROM batches b
LEFT JOIN quality_tests t ON b.batch_id = t.batch_id;

-- Q3
SELECT 
    b.batch_id
FROM batches b
INNER JOIN quality_tests t on b.batch_id = t.batch_id 
INNER JOIN deviations d on b.batch_id = d.batch_id
WHERE t.result = 'fail'
GROUP BY b.batch_id;

-- Q4
SELECT
    b.batch_id,
    COUNT(DISTINCT t.test_id) AS test_count,
    COUNT(DISTINCT d.deviation_id) AS deviation_count
FROM batches b
LEFT JOIN quality_tests t on b.batch_id = t.batch_id 
LEFT JOIN deviations d on b.batch_id = d.batch_id
GROUP BY b.batch_id;

-- Q5
SELECT
    b.batch_id
FROM batches b
LEFT JOIN deviations d ON b.batch_id = d.batch_id
WHERE d.deviation_id IS NULL;