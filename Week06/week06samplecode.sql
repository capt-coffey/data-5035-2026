USE SCHEMA data5035.dog; --use your own user name here

CREATE OR REPLACE TEMPORARY TABLE donations_test 
(name varchar, expected int not null);

INSERT INTO donations_test 
VALUES
('Boal, Paul', 1),
('Paul Boal', 0),
('', 0),
(NULL, 0);

SELECT
    'dq_reversed_name' as test_name,
    name as input_value,
    CASE WHEN CONTAINS(name, ',') THEN 1 ELSE 0 END AS actual,
    expected,
    actual = expected as match
FROM
    donations_test;
