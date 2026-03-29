USE ROLE DOG_DATA5035_ROLE; 
USE DATABASE DATA5035;
USE SCHEMA DOG;

-- Patients
CREATE OR REPLACE TABLE DATA5035.DOG.patients(
    patient_id INT,
    name VARCHAR(100),
    birth_year VARCHAR(4)
);

INSERT INTO DATA5035.DOG.patients (patient_id, name, birth_year)
VALUES
    (1, 'John', '1980'),
    (2, 'Mary',   '1975'),
    (3, 'Sam', '1990');

-- Visits
CREATE TABLE visits (
    visit_id    INT,
    patient_id  INT,
    visit_date  DATE,
    provider_id INT
);

INSERT INTO visits (visit_id, patient_id, visit_date, provider_id)
VALUES
    (2001, 1, '2024-02-01', 10),
    (2002, 2, '2024-02-03', 11);

-- Providers
CREATE TABLE providers (
    provider_id   INT,
    provider_name VARCHAR(100),
    specialty     VARCHAR(100)
);

INSERT INTO providers (provider_id, provider_name, specialty)
VALUES
    (10, 'Dr. Smith', 'Cardiology'),
    (11, 'Dr. Lee',   'Primary Care'),
    (12, 'Dr. Patel', 'Oncology');

-- Q1
SELECT
    pat.name, 
    pro.provider_name, 
    v.visit_date
FROM patients pat
INNER JOIN visits v ON pat.patient_ID = v.patient_id
INNER JOIN providers pro ON v.provider_id = pro.provider_id;

-- Q2
SELECT
    pat.name,
    v.visit_id
FROM patients pat
LEFT JOIN visits v ON pat.patient_id = v.patient_id;

-- Q3
SELECT 
    pro.provider_name,
    v.visit_id
FROM providers pro
LEFT JOIN visits v ON pro.provider_id = v.provider_id;

-- Q4
SELECT 
    pat.name
FROM patients pat
LEFT JOIN visits v ON pat.patient_id = v.patient_id
WHERE v.patient_id IS NULL;

-- Q5
SELECT
    pat.name,
    pro.provider_name,
    v.visit_date
FROM patients pat
INNER JOIN visits v ON pat.patient_id = v.patient_id
INNER JOIN providers pro ON v.provider_id = pro.provider_id
WHERE pro.specialty = 'Cardiology';