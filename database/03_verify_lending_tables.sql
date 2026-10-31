USE campusshare_integration_test;

-- 1. Verify all seven Member 2 tables
SELECT
    TABLE_NAME
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME IN (
    'borrow_requests',
    'loans',
    'condition_records',
    'ratings',
    'notifications',
    'reported_issues',
    'activity_logs'
)
ORDER BY TABLE_NAME;

-- 2. Verify table columns
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_KEY
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME IN (
    'borrow_requests',
    'loans',
    'condition_records',
    'ratings',
    'notifications',
    'reported_issues',
    'activity_logs'
)
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- 3. Verify Member 2 foreign keys
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE()
AND REFERENCED_TABLE_NAME IS NOT NULL
AND TABLE_NAME IN (
    'borrow_requests',
    'loans',
    'condition_records',
    'ratings',
    'notifications',
    'reported_issues',
    'activity_logs'
)
ORDER BY TABLE_NAME, COLUMN_NAME;

-- 4. Count Member 2 tables
SELECT COUNT(*) AS total_member2_tables
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME IN (
    'borrow_requests',
    'loans',
    'condition_records',
    'ratings',
    'notifications',
    'reported_issues',
    'activity_logs'
);

-- 5. Count Member 2 foreign keys
SELECT COUNT(*) AS total_member2_foreign_keys
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE()
AND REFERENCED_TABLE_NAME IS NOT NULL
AND TABLE_NAME IN (
    'borrow_requests',
    'loans',
    'condition_records',
    'ratings',
    'notifications',
    'reported_issues',
    'activity_logs'
);