
-- =====================================================
-- CAMPUSSHARE DATABASE
-- MEMBER 2 - LENDING OPERATIONS
-- =====================================================

USE campusshare_db;

-- IMPORTANT:
-- Member 1 is responsible for users and items.
-- Their foreign keys will be added after integration.
-- Only item owners approve or reject borrow requests.


-- =====================================================
-- TABLE 1: BORROW REQUESTS
-- =====================================================

CREATE TABLE IF NOT EXISTS borrow_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,

    item_id INT NOT NULL,
    borrower_id INT NOT NULL,

    requested_start DATE NOT NULL,
    requested_end DATE NOT NULL,

    status ENUM(
        'Pending',
        'Approved',
        'Rejected',
        'Cancelled'
    ) NOT NULL DEFAULT 'Pending',

    requested_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    decided_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,

    CONSTRAINT chk_request_dates
        CHECK (requested_end >= requested_start),

    INDEX idx_request_item_status (item_id, status),
    INDEX idx_request_borrower (borrower_id)

    -- TODO: FK item_id -> items(item_id)
    -- TODO: FK borrower_id -> users(user_id)
);


-- =====================================================
-- TABLE 2: LOANS
-- =====================================================

CREATE TABLE IF NOT EXISTS loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,

    request_id INT NOT NULL UNIQUE,

    approved_start DATE NOT NULL,
    approved_return_date DATE NOT NULL,

    status ENUM(
        'Active',
        'Completed'
    ) NOT NULL DEFAULT 'Active',

    handover_confirmed_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    returned_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,

    CONSTRAINT chk_loan_dates
        CHECK (approved_return_date >= approved_start),

    CONSTRAINT fk_loan_request
        FOREIGN KEY (request_id)
        REFERENCES borrow_requests(request_id)
);


-- =====================================================
-- TABLE 3: CONDITION RECORDS
-- =====================================================

CREATE TABLE IF NOT EXISTS condition_records (
    condition_id INT AUTO_INCREMENT PRIMARY KEY,

    loan_id INT NOT NULL,

    recorded_by INT NOT NULL,

    stage ENUM(
        'Handover',
        'Return'
    ) NOT NULL,

    condition_description TEXT NOT NULL,

    condition_status ENUM(
        'Good',
        'Minor Damage',
        'Major Damage'
    ) NOT NULL,

    dispute_flag BOOLEAN NOT NULL DEFAULT FALSE,

    recorded_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_condition_loan
        FOREIGN KEY (loan_id)
        REFERENCES loans(loan_id),

    INDEX idx_condition_loan_stage (loan_id, stage)

    -- TODO: FK recorded_by -> users(user_id)
);


-- =====================================================
-- TABLE 4: RATINGS
-- =====================================================

CREATE TABLE IF NOT EXISTS ratings (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,

    loan_id INT NOT NULL,

    reviewer_id INT NOT NULL,
    reviewed_user_id INT NOT NULL,

    rating_value INT NOT NULL,

    review_comment TEXT NULL,

    created_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_rating_value
        CHECK (rating_value BETWEEN 1 AND 5),

    CONSTRAINT chk_different_users
        CHECK (reviewer_id <> reviewed_user_id),

    CONSTRAINT fk_rating_loan
        FOREIGN KEY (loan_id)
        REFERENCES loans(loan_id),

    UNIQUE KEY uq_rating_reviewer
        (loan_id, reviewer_id)

    -- TODO: FKs to users
);


-- =====================================================
-- TABLE 5: NOTIFICATIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,

    user_id INT NOT NULL,

    request_id INT NULL,

    notification_type ENUM(
        'RequestReceived',
        'RequestApproved',
        'RequestRejected',
        'ReturnReminder',
        'General'
    ) NOT NULL,

    message TEXT NOT NULL,

    is_read BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    read_at TIMESTAMP NULL,

    CONSTRAINT fk_notification_request
        FOREIGN KEY (request_id)
        REFERENCES borrow_requests(request_id),

    INDEX idx_notification_user_read
        (user_id, is_read)

    -- TODO: FK user_id -> users(user_id)
);


-- =====================================================
-- TABLE 6: REPORTED ISSUES
-- =====================================================

CREATE TABLE IF NOT EXISTS reported_issues (
    issue_id INT AUTO_INCREMENT PRIMARY KEY,

    loan_id INT NULL,
    request_id INT NULL,

    reported_by INT NOT NULL,

    issue_type ENUM(
        'ItemDamage',
        'ConditionDispute',
        'LateReturn',
        'Other'
    ) NOT NULL,

    description TEXT NOT NULL,

    status ENUM(
        'Open',
        'UnderReview',
        'Resolved',
        'Closed'
    ) NOT NULL DEFAULT 'Open',

    created_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    resolved_at TIMESTAMP NULL,

    CONSTRAINT fk_issue_loan
        FOREIGN KEY (loan_id)
        REFERENCES loans(loan_id),

    CONSTRAINT fk_issue_request
        FOREIGN KEY (request_id)
        REFERENCES borrow_requests(request_id),

    CONSTRAINT chk_issue_reference
        CHECK (
            loan_id IS NOT NULL
            OR request_id IS NOT NULL
        )

    -- TODO: FK reported_by -> users(user_id)
);


-- =====================================================
-- TABLE 7: ACTIVITY LOGS
-- =====================================================

CREATE TABLE IF NOT EXISTS activity_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,

    user_id INT NULL,

    action_type VARCHAR(100) NOT NULL,

    entity_type VARCHAR(50) NOT NULL,

    entity_id INT NULL,

    description TEXT NULL,

    created_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_activity_user (user_id),
    INDEX idx_activity_entity (entity_type, entity_id)

    -- TODO: FK user_id -> users(user_id)
);


