
USE campusshare_integration_test;

-- ==========================================================
-- CAMPUSSHARE - MEMBER 2 REQUEST SCENARIO TESTS
-- File: 06_test_request_scenarios.sql
--
-- TEST 1: Cancel a pending request
-- TEST 2: Reject a pending request
-- TEST 3: Detect overlapping approved reservations
--
-- All test records are rolled back.
-- ==========================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS test_request_scenarios$$

CREATE PROCEDURE test_request_scenarios()
BEGIN
    DECLARE v_owner_id INT;
    DECLARE v_borrower1_id INT;
    DECLARE v_borrower2_id INT;
    DECLARE v_category_id INT;
    DECLARE v_item_id INT;

    DECLARE v_cancel_request_id INT;
    DECLARE v_reject_request_id INT;
    DECLARE v_approved_request_id INT;
    DECLARE v_overlap_request_id INT;

    DECLARE v_overlap_count INT DEFAULT 0;
    DECLARE v_run_id VARCHAR(36);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET v_run_id = UUID();

    START TRANSACTION;

    -- ======================================================
    -- SETUP: CREATE TEST USERS AND ITEM
    -- ======================================================

    INSERT INTO users
        (email, password_hash, display_name)
    VALUES
        (CONCAT('owner_', v_run_id, '@example.com'),
         'test_hash', 'Test Owner');

    SET v_owner_id = LAST_INSERT_ID();

    INSERT INTO users
        (email, password_hash, display_name)
    VALUES
        (CONCAT('borrower1_', v_run_id, '@example.com'),
         'test_hash', 'Test Borrower 1');

    SET v_borrower1_id = LAST_INSERT_ID();

    INSERT INTO users
        (email, password_hash, display_name)
    VALUES
        (CONCAT('borrower2_', v_run_id, '@example.com'),
         'test_hash', 'Test Borrower 2');

    SET v_borrower2_id = LAST_INSERT_ID();

    INSERT INTO categories (category_name)
    VALUES (CONCAT('Test Category ', v_run_id));

    SET v_category_id = LAST_INSERT_ID();

    INSERT INTO items
        (owner_id, category_id, title, item_condition)
    VALUES
        (v_owner_id, v_category_id,
         'Test Projector', 'Good');

    SET v_item_id = LAST_INSERT_ID();

    -- ======================================================
    -- TEST 1: CANCEL PENDING REQUEST
    -- ======================================================

    INSERT INTO borrow_requests
        (item_id, borrower_id,
         requested_start, requested_end, status)
    VALUES
        (v_item_id, v_borrower1_id,
         '2026-11-10', '2026-11-12', 'Pending');

    SET v_cancel_request_id = LAST_INSERT_ID();

    UPDATE borrow_requests
    SET status = 'Cancelled',
        cancelled_at = CURRENT_TIMESTAMP
    WHERE request_id = v_cancel_request_id
      AND borrower_id = v_borrower1_id
      AND status = 'Pending';

    SELECT
        'TEST 1 - Cancel pending request' AS test_name,
        IF(
            status = 'Cancelled'
            AND cancelled_at IS NOT NULL,
            'PASS', 'FAIL'
        ) AS result,
        status
    FROM borrow_requests
    WHERE request_id = v_cancel_request_id;

    -- ======================================================
    -- TEST 2: OWNER REJECTS PENDING REQUEST
    -- ======================================================

    INSERT INTO borrow_requests
        (item_id, borrower_id,
         requested_start, requested_end, status)
    VALUES
        (v_item_id, v_borrower2_id,
         '2026-11-15', '2026-11-17', 'Pending');

    SET v_reject_request_id = LAST_INSERT_ID();

    -- Simulates an owner-authorized backend action.
    -- The SQL UPDATE itself does not authenticate the owner.

    UPDATE borrow_requests
    SET status = 'Rejected',
        decided_at = CURRENT_TIMESTAMP
    WHERE request_id = v_reject_request_id
      AND status = 'Pending'
      AND item_id IN (
          SELECT item_id
          FROM items
          WHERE owner_id = v_owner_id
      );

    SELECT
        'TEST 2 - Owner rejects request' AS test_name,
        IF(
            status = 'Rejected'
            AND decided_at IS NOT NULL,
            'PASS', 'FAIL'
        ) AS result,
        status
    FROM borrow_requests
    WHERE request_id = v_reject_request_id;

    -- ======================================================
    -- TEST 3: DETECT OVERLAPPING RESERVATIONS
    -- ======================================================

    -- Existing approved reservation:
    -- November 20 to November 25

    INSERT INTO borrow_requests
        (item_id, borrower_id,
         requested_start, requested_end,
         approved_start, approved_end,
         status, decided_at)
    VALUES
        (v_item_id, v_borrower1_id,
         '2026-11-20', '2026-11-25',
         '2026-11-20', '2026-11-25',
         'Approved', CURRENT_TIMESTAMP);

    SET v_approved_request_id = LAST_INSERT_ID();

    -- Another borrower requests overlapping dates:
    -- November 23 to November 27

    INSERT INTO borrow_requests
        (item_id, borrower_id,
         requested_start, requested_end, status)
    VALUES
        (v_item_id, v_borrower2_id,
         '2026-11-23', '2026-11-27', 'Pending');

    SET v_overlap_request_id = LAST_INSERT_ID();

    -- Count approved reservations overlapping this request.
    -- Date ranges are inclusive.

    SELECT COUNT(*)
    INTO v_overlap_count
    FROM borrow_requests existing
    JOIN borrow_requests candidate
      ON existing.item_id = candidate.item_id
    WHERE candidate.request_id = v_overlap_request_id
      AND existing.request_id <> candidate.request_id
      AND existing.status = 'Approved'
      AND existing.approved_start <= candidate.requested_end
      AND existing.approved_end >= candidate.requested_start;

    SELECT
        'TEST 3 - Detect overlapping dates' AS test_name,
        IF(
            v_overlap_count > 0
            AND status = 'Pending',
            'PASS', 'FAIL'
        ) AS result,
        v_overlap_count AS overlapping_reservations,
        status AS new_request_status
    FROM borrow_requests
    WHERE request_id = v_overlap_request_id;

    -- ======================================================
    -- FINAL VERIFICATION
    -- ======================================================

    SELECT
        (SELECT COUNT(*)
         FROM borrow_requests
         WHERE request_id IN (
             v_cancel_request_id,
             v_reject_request_id,
             v_approved_request_id,
             v_overlap_request_id
         )) AS test_requests_created,

        (SELECT COUNT(*)
         FROM borrow_requests
         WHERE request_id = v_cancel_request_id
           AND status = 'Cancelled')
           AS cancelled_requests,

        (SELECT COUNT(*)
         FROM borrow_requests
         WHERE request_id = v_reject_request_id
           AND status = 'Rejected')
           AS rejected_requests,

        (SELECT COUNT(*)
         FROM borrow_requests
         WHERE request_id = v_approved_request_id
           AND status = 'Approved')
           AS approved_requests,

        v_overlap_count AS detected_overlaps;

    -- ======================================================
    -- ROLLBACK
    -- ======================================================

    ROLLBACK;

    SELECT
        'Request scenario testing completed; data rolled back'
        AS final_message;

END$$

DELIMITER ;

CALL test_request_scenarios();

DROP PROCEDURE IF EXISTS test_request_scenarios;
