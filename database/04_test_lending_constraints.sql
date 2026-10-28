
-- =====================================================
-- CAMPUSSHARE - MEMBER 2 CONSTRAINT TESTS
-- =====================================================

USE campusshare_db;

-- Ensure MySQL stops on a failed statement.
-- Run tests individually when instructed.

-- TEST 1: Verify date CHECK constraint
-- Expected: Error 3819 (invalid dates)

INSERT INTO borrow_requests (
    item_id,
    borrower_id,
    requested_start,
    requested_end
)
VALUES (
    999,
    998,
    '2026-11-10',
    '2026-11-05'
);

-- TEST 2: Verify rating CHECK constraint
-- Expected: Error 3819 (rating must be 1 to 5)
-- This test assumes no loan with ID 999999 exists.
-- An FK error may occur first, so use a real test loan
-- when testing the rating constraint.

INSERT INTO ratings (
    loan_id,
    reviewer_id,
    reviewed_user_id,
    rating_value
)
VALUES (
    999999,
    998,
    997,
    6
);

-- TEST 3: Verify loan foreign key
-- Expected: Error 1452 (nonexistent request)

INSERT INTO loans (
    request_id,
    approved_start,
    approved_return_date
)
VALUES (
    999999,
    '2026-11-01',
    '2026-11-03'
);

-- TEST 4: Verify issue reference CHECK
-- Expected: Error 3819
-- Both loan_id and request_id are NULL

INSERT INTO reported_issues (
    reported_by,
    issue_type,
    description
)
VALUES (
    998,
    'Other',
    'Test issue without a linked request or loan'
);
