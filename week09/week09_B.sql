USE ROLE DOG_DATA5035_ROLE; 
USE DATABASE DATA5035;
USE SCHEMA DOG;

-- ============================================================
-- Scenario B: Patient Visits & Providers
-- Approach: Uses INNER JOINs and LEFT JOINs to analyze patient
-- visit history and provider coverage, including an anti-join 
-- to identify patients with no visits and a filtered join to
-- isolate visits by specialty.
-- Tables: patients, visits, providers
-- ============================================================

-- Create and populate base tables

CREATE OR REPLACE TABLE DATA5035.DOG.patients (
    patient_id  INT,
    name        VARCHAR(100),
    birth_year  VARCHAR(4)
);

INSERT INTO DATA5035.DOG.patients (patient_id, name, birth_year)
VALUES
    (1, 'John', '1980'),
    (2, 'Mary', '1975'),
    (3, 'Sam',  '1990');

CREATE OR REPLACE TABLE DATA5035.DOG.visits (
    visit_id    INT,
    patient_id  INT,
    visit_date  DATE,
    provider_id INT
);

INSERT INTO DATA5035.DOG.visits (visit_id, patient_id, visit_date, provider_id)
VALUES
    (2001, 1, '2024-02-01', 10),
    (2002, 2, '2024-02-03', 11);

CREATE OR REPLACE TABLE DATA5035.DOG.providers (
    provider_id   INT,
    provider_name VARCHAR(100),
    specialty     VARCHAR(100)
);

INSERT INTO DATA5035.DOG.providers (provider_id, provider_name, specialty)
VALUES
    (10, 'Dr. Smith', 'Cardiology'),
    (11, 'Dr. Lee',   'Primary Care'),
    (12, 'Dr. Patel', 'Oncology');

-- ============================================================
-- Q1: Show each visit with patient and provider details
-- Join type: INNER JOIN x2
-- Assumption: Only visits with a matching patient and provider
-- are returned; excludes any unmatched records
-- ============================================================
SELECT
    pat.name, 
    pro.provider_name, 
    v.visit_date
FROM patients pat
INNER JOIN visits v   ON pat.patient_id  = v.patient_id
INNER JOIN providers pro ON v.provider_id = pro.provider_id;

-- ============================================================
-- Q2: Show all patients and any visits they may have had
-- Join type: LEFT JOIN
-- Assumption: All patients are returned, even those without
-- visits; visit_id will be NULL for patients with no visits
-- ============================================================
SELECT
    pat.name,
    v.visit_id
FROM patients pat
LEFT JOIN visits v ON pat.patient_id = v.patient_id;

-- ============================================================
-- Q3: Show all providers and any visits they handled
-- Join type: LEFT JOIN
-- Assumption: All providers are returned, even those without
-- visits; Dr. Patel will appear with a NULL visit_id
-- ============================================================
SELECT 
    pro.provider_name,
    v.visit_id
FROM providers pro
LEFT JOIN visits v ON pro.provider_id = v.provider_id;

-- ============================================================
-- Q4: Find patients who have never had a visit
-- Join type: LEFT JOIN (anti-join pattern)
-- Assumption: Patients with no matching record in visits are
-- returned; NULL in v.patient_id indicates no visit on record
-- ============================================================
SELECT 
    pat.name
FROM patients pat
LEFT JOIN visits v ON pat.patient_id = v.patient_id
WHERE v.patient_id IS NULL;

-- ============================================================
-- Q5: Show visits handled by cardiology providers
-- Join type: INNER JOIN x2
-- Assumption: Only visits matched to a provider with specialty
-- 'Cardiology' are returned; filter applied after join
-- ============================================================
SELECT
    pat.name,
    pro.provider_name,
    v.visit_date
FROM patients pat
INNER JOIN visits v      ON pat.patient_id  = v.patient_id
INNER JOIN providers pro ON v.provider_id   = pro.provider_id
WHERE pro.specialty = 'Cardiology';