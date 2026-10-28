
-- =====================================================
-- CAMPUSSHARE - MEMBER 2 REQUEST SCENARIO TESTS
-- =====================================================

USE campusshare_db;

-- All test records are temporary.
START TRANSACTION;

-- =====================================================
-- TEST 1: BORROWER CANCELS A PENDING REQUEST
-- =====================================================

INSERT INTO borrow_requests (
    item_id,
    borrower_id,
    requested_start,
    requested_end
)
VALUES (
    999,
    998,
    '2026-11-15',
    '2026-11-17'
);

SET @cancel_request_id = LAST_INSERT_ID();

UPDATE borrow_requests
SET status = 'Cancelled',
    cancelled_at = CURRENT_TIMESTAMP
WHERE request_id = @cancel_request_id
  AND status = 'Pending';

SELECT
    request_id,
    status,
    cancelled_at
FROM borrow_requests
WHERE request_id = @cancel_request_id;


-- =====================================================
-- TEST 2: OWNER REJECTS A PENDING REQUEST
-- =====================================================

INSERT INTO borrow_requests (
    item_id,
    borrower_id,
    requested_start,
    requested_end
)
VALUES (
    999,
    997,
    '2026-11-18',
    '2026-11-20'
);

SET @reject_request_id = LAST_INSERT_ID();

UPDATE borrow_requests
SET status = 'Rejected',
    decided_at = CURRENT_TIMESTAMP
WHERE request_id = @reject_request_id
  AND status = 'Pending';

SELECT
    request_id,
    status,
    decided_at
FROM borrow_requests
WHERE request_id = @reject_request_id;


-- =====================================================
-- TEST 3: OVERLAPPING APPROVED RESERVATIONS
-- =====================================================

-- First borrower requests an item
INSERT INTO borrow_requests (
    item_id,
    borrower_id,
    requested_start,
    requested_end
)
VALUES (
    999,
    998,
    '2026-11-21',
    '2026-11-25'
);

SET @first_request_id = LAST_INSERT_ID();

UPDATE borrow_requests
SET status = 'Approved',
    decided_at = CURRENT_TIMESTAMP
WHERE request_id = @first_request_id
  AND status = 'Pending';

-- Second borrower requests the same item
-- with overlapping dates
INSERT INTO borrow_requests (
    item_id,
    borrower_id,
    requested_start,
    requested_end
)
VALUES (
    999,
    997,
    '2026-11-23',
    '2026-11-27'
);

SET @second_request_id = LAST_INSERT_ID();

-- Check for overlapping approved reservations
SELECT
    request_id,
    item_id,
    requested_start,
    requested_end,
    status
FROM borrow_requests
WHERE item_id = 999
  AND status = 'Approved'
  AND request_id <> @second_request_id
  AND requested_start <= '2026-11-27'
  AND requested_end >= '2026-11-23';

-- The query above should find the first
-- approved request, meaning approval of
-- the second request must be blocked.

-- Check the second request remains Pending
SELECT
    request_id,
    status
FROM borrow_requests
WHERE request_id = @second_request_id;


-- =====================================================
-- CLEANUP
-- =====================================================

ROLLBACK;

-- =====================================================
-- END OF TESTS
-- =====================================================
