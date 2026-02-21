USE SCHEMA data5035.dog;


-- STEP 1: Create the test table NOTE: I had to run this section first by highlighting it before I ran the other code. 
CREATE OR REPLACE TEMPORARY TABLE donations_unit_test (
    test_id     INT,
    check_name  VARCHAR,
    input_value VARCHAR,
    expected    VARCHAR  -- 'TRUE' or 'FALSE'
);


-- STEP 2: Populate the test table
INSERT INTO donations_unit_test (test_id, check_name, input_value, expected)
VALUES


/** DQ_ZIP_LENGTH Tests (10 scenarios)
    Logic: CASE WHEN LENGTH(ZIP) = 5 THEN 'TRUE' ELSE 'FALSE' END
**/

-- Test 01: Standard valid 5-digit ZIP
(1,  'DQ_ZIP_LENGTH', '62704',     'TRUE'),
-- Test 02: 4-digit ZIP (too short)
(2,  'DQ_ZIP_LENGTH', '4918',      'FALSE'),
-- Test 03: 6-digit ZIP (too long)
(3,  'DQ_ZIP_LENGTH', '627041',    'FALSE'),
-- Test 04: ZIP with leading zeros - valid 5-digit
(4,  'DQ_ZIP_LENGTH', '01234',     'TRUE'),
-- Test 05: ZIP of all zeros - still 5 chars, passes length check
(5,  'DQ_ZIP_LENGTH', '00000',     'TRUE'),
-- Test 06: ZIP is NULL - LENGTH(NULL) is not 5, so FALSE
(6,  'DQ_ZIP_LENGTH', NULL,        'FALSE'),
-- Test 07: ZIP is empty string - length 0, not 5
(7,  'DQ_ZIP_LENGTH', '',          'FALSE'),
-- Test 08: ZIP with letters mixed in - 5 chars, passes length check
(8,  'DQ_ZIP_LENGTH', 'AB12C',     'TRUE'),
-- Test 09: ZIP+4 extended format - 9 digits, too long
(9,  'DQ_ZIP_LENGTH', '627041234', 'FALSE'),
-- Test 10: ZIP as exactly 3 digits
(10, 'DQ_ZIP_LENGTH', '123',       'FALSE'),


/** DQ_PHONE_LENGTH Tests (10 scenarios)
    Logic: CASE WHEN CONTAINS(PHONE,'(') OR CONTAINS(PHONE,')')
            OR CONTAINS(PHONE,'+') OR CONTAINS(PHONE,'x')
            OR CONTAINS(PHONE,'.') AND LENGTH(PHONE) > 12
            THEN 'FALSE' ELSE 'TRUE' END 
**/

-- Test 11: Clean standard phone - 12 chars, no special chars
(11, 'DQ_PHONE_LENGTH', '314-555-1234',       'TRUE'),
-- Test 12: Phone with parentheses around area code
(12, 'DQ_PHONE_LENGTH', '(314) 555-1234',     'FALSE'),
-- Test 13: Phone with country code using '+'
(13, 'DQ_PHONE_LENGTH', '+1-314-555-1234',    'FALSE'),
-- Test 14: Phone with extension using 'x'
(14, 'DQ_PHONE_LENGTH', '314-555-1234x47',    'FALSE'),
-- Test 15: Phone with dots and length > 12
(15, 'DQ_PHONE_LENGTH', '314.555.1234xx',     'FALSE'),
-- Test 16: Phone with dots but length <= 12 - passes per current logic
(16, 'DQ_PHONE_LENGTH', '314.555.1234',       'TRUE'),
-- Test 17: NULL phone - no special chars detected, passes
(17, 'DQ_PHONE_LENGTH', NULL,                 'TRUE'),
-- Test 18: Empty string - no special chars, passes
(18, 'DQ_PHONE_LENGTH', '',                   'TRUE'),
-- Test 19: Phone with both '(' and '+' characters
(19, 'DQ_PHONE_LENGTH', '(+1) 314-555-1234',  'FALSE'),
-- Test 20: Clean 12-char phone with only digits and dashes
(20, 'DQ_PHONE_LENGTH', '314-555-9999',       'TRUE');


-- STEP 3: Run the tests and display results
SELECT
    test_id,
    check_name,
    input_value,
    expected,
    CASE check_name
        WHEN 'DQ_ZIP_LENGTH' THEN
            CASE WHEN LENGTH(input_value) = 5 THEN 'TRUE' ELSE 'FALSE' END
        WHEN 'DQ_PHONE_LENGTH' THEN
            CASE
                WHEN CONTAINS(input_value, '(')
                  OR CONTAINS(input_value, ')')
                  OR CONTAINS(input_value, '+')
                  OR CONTAINS(input_value, 'x')
                  OR CONTAINS(input_value, '.') AND LENGTH(input_value) > 12
                THEN 'FALSE'
                ELSE 'TRUE'
            END
    END AS actual,
    CASE check_name
        WHEN 'DQ_ZIP_LENGTH' THEN
            CASE WHEN LENGTH(input_value) = 5 THEN 'TRUE' ELSE 'FALSE' END
        WHEN 'DQ_PHONE_LENGTH' THEN
            CASE
                WHEN CONTAINS(input_value, '(')
                  OR CONTAINS(input_value, ')')
                  OR CONTAINS(input_value, '+')
                  OR CONTAINS(input_value, 'x')
                  OR CONTAINS(input_value, '.') AND LENGTH(input_value) > 12
                THEN 'FALSE'
                ELSE 'TRUE'
            END
    END = expected AS match

FROM donations_unit_test
ORDER BY test_id;

