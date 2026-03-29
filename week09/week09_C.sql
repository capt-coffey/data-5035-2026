USE ROLE DOG_DATA5035_ROLE; 
USE DATABASE DATA5035;
USE SCHEMA DOG;

-- ============================================================
-- Scenario C: Batch Quality & Deviations
-- Approach: Uses INNER JOINs and LEFT JOINs to analyze batch
-- quality test results and deviations. Includes aggregation to
-- count tests and deviations per batch, and an anti-join to
-- identify batches with no deviations.
-- Tables: batches, quality_tests, deviations
-- ============================================================

-- Create and populate base tables

CREATE OR REPLACE TABLE DATA5035.DOG.batches (
    batch_id  VARCHAR(10),
    product   VARCHAR(100),
    facility  VARCHAR(100)
);

INSERT INTO DATA5035.DOG.batches (batch_id, product, facility)
VALUES
    ('B1', 'DrugA', 'Plant1'),
    ('B2', 'DrugA', 'Plant2'),
    ('B3', 'DrugB', 'Plant1');

CREATE OR REPLACE TABLE DATA5035.DOG.quality_tests (
    test_id   VARCHAR(10),
    batch_id  VARCHAR(10),
    test_type VARCHAR(100),
    result    VARCHAR(10)
);

INSERT INTO DATA5035.DOG.quality_tests (test_id, batch_id, test_type, result)
VALUES
    ('T1', 'B1', 'purity',    'pass'),
    ('T2', 'B1', 'stability', 'fail'),
    ('T3', 'B2', 'purity',    'pass');

CREATE OR REPLACE TABLE DATA5035.DOG.deviations (
    deviation_id VARCHAR(10),
    batch_id     VARCHAR(10),
    description  VARCHAR(255)
);

INSERT INTO DATA5035.DOG.deviations (deviation_id, batch_id, description)
VALUES
    ('D1', 'B1', 'temperature excursion');

-- ============================================================
-- Q1: Show all batches and their quality test results
-- Join type: INNER JOIN
-- Assumption: Only batches with at least one quality test are
-- returned; B3 which has no tests will be excluded
-- ============================================================
SELECT
    b.batch_id,
    t.test_type,
    t.result
FROM batches b
INNER JOIN quality_tests t ON b.batch_id = t.batch_id;

-- ============================================================
-- Q2: Show all batches, including those without tests
-- Join type: LEFT JOIN
-- Assumption: All batches are returned; B3 will appear with
-- NULL values for test_type and result
-- ============================================================
SELECT
    b.batch_id,
    t.test_type,
    t.result
FROM batches b
LEFT JOIN quality_tests t ON b.batch_id = t.batch_id;

-- ============================================================
-- Q3: Find batches with both failed tests and deviations
-- Join type: INNER JOIN x2
-- Assumption: Only batches with at least one failed test AND
-- at least one deviation are returned; GROUP BY deduplicates
-- batches that may have multiple failed tests
-- ============================================================
SELECT 
    b.batch_id
FROM batches b
INNER JOIN quality_tests t ON b.batch_id = t.batch_id 
INNER JOIN deviations d    ON b.batch_id = d.batch_id
WHERE t.result = 'fail'
GROUP BY b.batch_id;

-- ============================================================
-- Q4: Show batch-level counts of tests and deviations
-- Join type: LEFT JOIN x2
-- Assumption: All batches are returned; COUNT DISTINCT is used
-- to avoid inflated counts caused by row multiplication when
-- joining two tables to the same base table simultaneously
-- ============================================================
SELECT
    b.batch_id,
    COUNT(DISTINCT t.test_id)      AS test_count,
    COUNT(DISTINCT d.deviation_id) AS deviation_count
FROM batches b
LEFT JOIN quality_tests t ON b.batch_id = t.batch_id 
LEFT JOIN deviations d    ON b.batch_id = d.batch_id
GROUP BY b.batch_id;

-- ============================================================
-- Q5: Find batches with no deviations
-- Join type: LEFT JOIN (anti-join pattern)
-- Assumption: Batches with no matching record in deviations are
-- returned; NULL in d.deviation_id indicates no deviation on record
-- ============================================================
SELECT
    b.batch_id
FROM batches b
LEFT JOIN deviations d ON b.batch_id = d.batch_id
WHERE d.deviation_id IS NULL;