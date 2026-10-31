
USE campusshare_integration_test;

-- ==========================================================
-- CAMPUSSHARE - MEMBER 2 BORROWING WORKFLOW TEST
-- File: 05_test_borrowing_workflow.sql
--
-- 1. Create borrower and owner
-- 2. Create an item
-- 3. Submit borrowing request
-- 4. Owner approves request
-- 5. Send approval notification
-- 6. Confirm item handover and create active loan
-- 7. Record handover conditions
-- 8. Record return conditions
-- 9. Owner confirms return
-- 10. Borrower rates owner
-- 11. Record activity logs
--
-- All inserted test data is rolled back.
-- ==========================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS test_borrowing_workflow$$

CREATE PROCEDURE test_borrowing_workflow()
BEGIN
    DECLARE v_borrower_id INT;
    DECLARE v_owner_id INT;
    DECLARE v_category_id INT;
    DECLARE v_item_id INT;
    DECLARE v_request_id INT;
    DECLARE v_loan_id INT;
    DECLARE v_run_id VARCHAR(36);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET v_run_id = UUID();

    START TRANSACTION;

    -- STEP 1: Create borrower
    INSERT INTO users
        (email, password_hash, display_name)
    VALUES
        (CONCAT('borrower_', v_run_id, '@example.com'),
         'test_hash', 'Test Borrower');

    SET v_borrower_id = LAST_INSERT_ID();

    -- STEP 2: Create item owner
    INSERT INTO users
        (email, password_hash, display_name)
    VALUES
        (CONCAT('owner_', v_run_id, '@example.com'),
         'test_hash', 'Test Owner');

    SET v_owner_id = LAST_INSERT_ID();

    -- STEP 3: Create category
    INSERT INTO categories (category_name)
    VALUES (CONCAT('Test Category ', v_run_id));

    SET v_category_id = LAST_INSERT_ID();

    -- STEP 4: Create item
    INSERT INTO items
        (owner_id, category_id, title,
         description, item_condition)
    VALUES
        (v_owner_id, v_category_id,
         'Scientific Calculator',
         'Calculator available for borrowing',
         'Good');

    SET v_item_id = LAST_INSERT_ID();

    -- STEP 5: Student submits request
    INSERT INTO borrow_requests
        (item_id, borrower_id,
         requested_start, requested_end, status)
    VALUES
        (v_item_id, v_borrower_id,
         '2026-11-01', '2026-11-05', 'Pending');

    SET v_request_id = LAST_INSERT_ID();

    SELECT '1. Request submitted' AS step,
           status
    FROM borrow_requests
    WHERE request_id = v_request_id;

    -- STEP 6: Item owner approves request
    UPDATE borrow_requests
    SET status = 'Approved',
        approved_start = '2026-11-01',
        approved_end = '2026-11-05',
        decided_at = CURRENT_TIMESTAMP
    WHERE request_id = v_request_id
      AND status = 'Pending';

    SELECT '2. Owner approved request' AS step,
           status, approved_start, approved_end
    FROM borrow_requests
    WHERE request_id = v_request_id;

    -- STEP 7: Send notification
    INSERT INTO notifications
        (recipient_id, request_id,
         event_type, message)
    VALUES
        (v_borrower_id, v_request_id,
         'REQUEST_APPROVED',
         'Your borrowing request was approved.');

    -- STEP 8: Confirm handover and create loan
    INSERT INTO loans
        (request_id, approved_due_at,
         handover_at, status)
    VALUES
        (v_request_id,
         '2026-11-05 17:00:00',
         CURRENT_TIMESTAMP, 'Active');

    SET v_loan_id = LAST_INSERT_ID();

    SELECT '3. Loan activated' AS step,
           status, approved_due_at
    FROM loans
    WHERE loan_id = v_loan_id;

    -- STEP 9: Owner records handover condition
    INSERT INTO condition_records
        (loan_id, actor_id, phase,
         condition_value, confirmation)
    VALUES
        (v_loan_id, v_owner_id,
         'handover', 'Good', 'confirmed');

    -- STEP 10: Borrower confirms condition
    INSERT INTO condition_records
        (loan_id, actor_id, phase,
         condition_value, confirmation)
    VALUES
        (v_loan_id, v_borrower_id,
         'handover', 'Good', 'confirmed');

    -- STEP 11: Record return conditions
    INSERT INTO condition_records
        (loan_id, actor_id, phase,
         condition_value, confirmation)
    VALUES
        (v_loan_id, v_borrower_id,
         'return', 'Good', 'confirmed');

    INSERT INTO condition_records
        (loan_id, actor_id, phase,
         condition_value, confirmation)
    VALUES
        (v_loan_id, v_owner_id,
         'return', 'Good', 'confirmed');

    -- STEP 12: Owner confirms return
    UPDATE loans
    SET status = 'Completed',
        actual_return_at = CURRENT_TIMESTAMP,
        owner_return_confirmed_at = CURRENT_TIMESTAMP
    WHERE loan_id = v_loan_id
      AND status = 'Active';

    SELECT '4. Loan completed' AS step,
           status
    FROM loans
    WHERE loan_id = v_loan_id;

    -- STEP 13: Borrower rates owner
    INSERT INTO ratings
        (loan_id, rater_id,
         target_type, target_user_id, stars)
    VALUES
        (v_loan_id, v_borrower_id,
         'user', v_owner_id, 5);

    SELECT '5. Rating submitted' AS step,
           stars
    FROM ratings
    WHERE loan_id = v_loan_id;

    -- STEP 14: Record activity logs
    INSERT INTO activity_logs
        (actor_id, action, entity_type, entity_id)
    VALUES
        (v_borrower_id, 'REQUEST_CREATED',
         'borrow_requests', v_request_id),
        (v_owner_id, 'REQUEST_APPROVED',
         'borrow_requests', v_request_id),
        (v_borrower_id, 'LOAN_STARTED',
         'loans', v_loan_id),
        (v_owner_id, 'LOAN_COMPLETED',
         'loans', v_loan_id),
        (v_borrower_id, 'RATING_SUBMITTED',
         'ratings', v_loan_id);

    -- STEP 15: Verify records
    SELECT
        (SELECT COUNT(*) FROM borrow_requests
         WHERE request_id = v_request_id)
            AS requests_created,

        (SELECT COUNT(*) FROM loans
         WHERE loan_id = v_loan_id
           AND status = 'Completed')
            AS completed_loans,

        (SELECT COUNT(*) FROM condition_records
         WHERE loan_id = v_loan_id)
            AS condition_records_created,

        (SELECT COUNT(*) FROM ratings
         WHERE loan_id = v_loan_id)
            AS ratings_created,

        (SELECT COUNT(*) FROM notifications
         WHERE request_id = v_request_id)
            AS notifications_created,

        (SELECT COUNT(*) FROM activity_logs
         WHERE entity_id = v_request_id
           AND entity_type = 'borrow_requests')
            AS request_activity_logs;

    -- STEP 16: Roll back test records
    ROLLBACK;

    SELECT 'Workflow test completed; test data rolled back'
        AS final_message;

END$$

DELIMITER ;

CALL test_borrowing_workflow();

DROP PROCEDURE IF EXISTS test_borrowing_workflow;
