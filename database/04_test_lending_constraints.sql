
USE campusshare_integration_test;

-- =====================================================
-- CAMPUSSHARE - MEMBER 2 DATABASE CONSTRAINT TESTING
-- File: 04_test_lending_constraints.sql
-- Database: campusshare_integration_test
--
-- Tests:
-- 1. Invalid rating values
-- 2. Invalid foreign key
-- 3. Duplicate loan request
-- 4. Missing required values
-- 5. Valid data insertion
--
-- Expected failures are caught by handlers.
-- All inserted test data is rolled back.
-- =====================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS test_lending_constraints$$

CREATE PROCEDURE test_lending_constraints()
BEGIN

    DECLARE v_user_id INT;
    DECLARE v_owner_id INT;
    DECLARE v_category_id INT;
    DECLARE v_item_id INT;
    DECLARE v_request_id INT;
    DECLARE v_loan_id INT;
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_failed BOOLEAN DEFAULT FALSE;

    -- ---------------------------------------------
    -- Start a transaction for temporary test data
    -- ---------------------------------------------

    START TRANSACTION;

    -- ---------------------------------------------
    -- Create temporary test users
    -- ---------------------------------------------

    INSERT INTO users
        (email, password_hash, display_name)
    VALUES
        (CONCAT('test_borrower_', UUID(), '@example.com'),
         'test_hash', 'Test Borrower');

    SET v_user_id = LAST_INSERT_ID();

    INSERT INTO users
        (email, password_hash, display_name)
    VALUES
        (CONCAT('test_owner_', UUID(), '@example.com'),
         'test_hash', 'Test Owner');

    SET v_owner_id = LAST_INSERT_ID();

    -- ---------------------------------------------
    -- Create temporary category and item
    -- ---------------------------------------------

    INSERT INTO categories (category_name)
    VALUES (CONCAT('Test Category ', UUID()));

    SET v_category_id = LAST_INSERT_ID();

    INSERT INTO items
        (owner_id, category_id, title, item_condition)
    VALUES
        (v_owner_id, v_category_id,
         'Test Calculator', 'Good');

    SET v_item_id = LAST_INSERT_ID();

    -- ---------------------------------------------
    -- Create a valid borrow request
    -- ---------------------------------------------

    INSERT INTO borrow_requests
        (item_id, borrower_id,
         requested_start, requested_end, status)
    VALUES
        (v_item_id, v_user_id,
         '2026-11-01', '2026-11-05', 'Approved');

    SET v_request_id = LAST_INSERT_ID();

    -- ---------------------------------------------
    -- Create a valid loan
    -- ---------------------------------------------

    INSERT INTO loans
        (request_id, approved_due_at, status)
    VALUES
        (v_request_id, '2026-11-05 17:00:00',
         'Completed');

    SET v_loan_id = LAST_INSERT_ID();

    -- =============================================
    -- TEST 1: INVALID RATING (6 STARS)
    -- Expected: REJECTED
    -- =============================================

    SET v_failed = FALSE;

    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
            SET v_failed = TRUE;

        INSERT INTO ratings
            (loan_id, rater_id, target_type,
             target_user_id, stars)
        VALUES
            (v_loan_id, v_user_id, 'user',
             v_owner_id, 6);
    END;

    SELECT
        'TEST 1 - Invalid rating (6 stars)' AS test_name,
        IF(v_failed, 'PASS', 'FAIL') AS result;

    -- =============================================
    -- TEST 2: INVALID FOREIGN KEY
    -- Expected: REJECTED
    -- =============================================

    SET v_failed = FALSE;

    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
            SET v_failed = TRUE;

        INSERT INTO loans
            (request_id, approved_due_at, status)
        VALUES
            (-999999, '2026-11-06 17:00:00',
             'Active');
    END;

    SELECT
        'TEST 2 - Invalid foreign key' AS test_name,
        IF(v_failed, 'PASS', 'FAIL') AS result;

    -- =============================================
    -- TEST 3: DUPLICATE LOAN REQUEST
    -- Expected: REJECTED
    -- =============================================

    SET v_failed = FALSE;

    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
            SET v_failed = TRUE;

        INSERT INTO loans
            (request_id, approved_due_at, status)
        VALUES
            (v_request_id, '2026-11-07 17:00:00',
             'Active');
    END;

    SELECT
        'TEST 3 - Duplicate loan request' AS test_name,
        IF(v_failed, 'PASS', 'FAIL') AS result;

    -- =============================================
    -- TEST 4: MISSING REQUIRED VALUE
    -- Expected: REJECTED
    -- =============================================

    SET v_failed = FALSE;

    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
            SET v_failed = TRUE;

        INSERT INTO borrow_requests
            (item_id, borrower_id,
             requested_start, requested_end)
        VALUES
            (v_item_id, v_user_id,
             NULL, '2026-11-10');
    END;

    SELECT
        'TEST 4 - Missing required date' AS test_name,
        IF(v_failed, 'PASS', 'FAIL') AS result;

    -- =============================================
    -- TEST 5: VALID RATING
    -- Expected: ACCEPTED
    -- =============================================

    SET v_failed = FALSE;

    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
            SET v_failed = TRUE;

        INSERT INTO ratings
            (loan_id, rater_id, target_type,
             target_user_id, stars)
        VALUES
            (v_loan_id, v_user_id, 'user',
             v_owner_id, 5);
    END;

    SELECT
        'TEST 5 - Valid rating (5 stars)' AS test_name,
        IF(NOT v_failed, 'PASS', 'FAIL') AS result;

    -- =============================================
    -- ROLLBACK ALL TEMPORARY TEST DATA
    -- =============================================

    ROLLBACK;

    SELECT
        'Constraint testing completed; test data rolled back'
        AS final_message;

END$$

DELIMITER ;

-- Run the tests
CALL test_lending_constraints();

-- Remove the temporary testing procedure
DROP PROCEDURE IF EXISTS test_lending_constraints;
