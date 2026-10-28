
-- =====================================================
-- CAMPUSSHARE - MEMBER 2 WORKFLOW TEST
-- Run only in the local development database.
-- All test data is rolled back at the end.
-- =====================================================

USE campusshare_db;

START TRANSACTION;

-- 1. Borrower submits request
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
    '2026-11-12'
);

SET @request_id = LAST_INSERT_ID();

-- 2. Item owner approves request
UPDATE borrow_requests
SET status = 'Approved',
    decided_at = CURRENT_TIMESTAMP
WHERE request_id = @request_id
  AND status = 'Pending';

-- 3. Borrower confirms handover
INSERT INTO loans (
    request_id,
    approved_start,
    approved_return_date
)
VALUES (
    @request_id,
    '2026-11-10',
    '2026-11-12'
);

SET @loan_id = LAST_INSERT_ID();

-- 4. Record item condition at handover
INSERT INTO condition_records (
    loan_id,
    recorded_by,
    stage,
    condition_description,
    condition_status
)
VALUES (
    @loan_id,
    998,
    'Handover',
    'Item received in good condition',
    'Good'
);

-- 5. Notify borrower of approval
INSERT INTO notifications (
    user_id,
    request_id,
    notification_type,
    message
)
VALUES (
    998,
    @request_id,
    'RequestApproved',
    'Your borrowing request was approved'
);

-- 6. Record item condition at return
INSERT INTO condition_records (
    loan_id,
    recorded_by,
    stage,
    condition_description,
    condition_status
)
VALUES (
    @loan_id,
    998,
    'Return',
    'Item returned in good condition',
    'Good'
);

-- 7. Owner confirms return and completion
UPDATE loans
SET status = 'Completed',
    returned_at = CURRENT_TIMESTAMP,
    completed_at = CURRENT_TIMESTAMP
WHERE loan_id = @loan_id
  AND status = 'Active';

-- 8. Submit rating after completion
INSERT INTO ratings (
    loan_id,
    reviewer_id,
    reviewed_user_id,
    rating_value,
    review_comment
)
VALUES (
    @loan_id,
    998,
    997,
    5,
    'Good lending experience'
);

-- 9. Add activity log
INSERT INTO activity_logs (
    user_id,
    action_type,
    entity_type,
    entity_id,
    description
)
VALUES (
    998,
    'LOAN_COMPLETED',
    'loans',
    @loan_id,
    'Borrowing workflow test completed'
);

-- 10. Check borrowing request
SELECT *
FROM borrow_requests
WHERE request_id = @request_id;

-- 11. Check loan
SELECT *
FROM loans
WHERE loan_id = @loan_id;

-- 12. Check condition records
SELECT *
FROM condition_records
WHERE loan_id = @loan_id;

-- 13. Check rating
SELECT *
FROM ratings
WHERE loan_id = @loan_id;

-- 14. Check notification
SELECT *
FROM notifications
WHERE request_id = @request_id;

-- 15. Check activity log
SELECT *
FROM activity_logs
WHERE entity_type = 'loans'
  AND entity_id = @loan_id;

-- 16. Remove all temporary test data
ROLLBACK;

-- =====================================================
-- END OF WORKFLOW TEST
-- =====================================================
