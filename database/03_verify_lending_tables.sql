
-- =====================================================
-- CAMPUSSHARE - MEMBER 2 DATABASE VERIFICATION
-- =====================================================

USE campusshare_db;

-- TEST 1: Show all tables
SHOW TABLES;

-- TEST 2: Check all table columns
DESCRIBE borrow_requests;
DESCRIBE loans;
DESCRIBE condition_records;
DESCRIBE ratings;
DESCRIBE notifications;
DESCRIBE reported_issues;
DESCRIBE activity_logs;

-- TEST 3: Verify primary keys
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'campusshare_db'
  AND CONSTRAINT_NAME = 'PRIMARY'
ORDER BY TABLE_NAME;

-- TEST 4: Verify foreign key relationships
SELECT
    TABLE_NAME AS child_table,
    COLUMN_NAME AS child_column,
    REFERENCED_TABLE_NAME AS parent_table,
    REFERENCED_COLUMN_NAME AS parent_column
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'campusshare_db'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, COLUMN_NAME;

-- TEST 5: Verify unique constraints
SELECT
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    NON_UNIQUE
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'campusshare_db'
  AND NON_UNIQUE = 0
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- TEST 6: Verify check constraints
SELECT
    tc.TABLE_NAME,
    tc.CONSTRAINT_NAME,
    cc.CHECK_CLAUSE
FROM information_schema.TABLE_CONSTRAINTS tc
JOIN information_schema.CHECK_CONSTRAINTS cc
    ON tc.CONSTRAINT_SCHEMA = cc.CONSTRAINT_SCHEMA
   AND tc.CONSTRAINT_NAME = cc.CONSTRAINT_NAME
WHERE tc.TABLE_SCHEMA = 'campusshare_db'
  AND tc.CONSTRAINT_TYPE = 'CHECK'
ORDER BY tc.TABLE_NAME;

-- TEST 7: Check table row counts
SELECT 'borrow_requests' AS table_name,
       COUNT(*) AS total_rows
FROM borrow_requests

UNION ALL
SELECT 'loans', COUNT(*) FROM loans

UNION ALL
SELECT 'condition_records',
       COUNT(*) FROM condition_records

UNION ALL
SELECT 'ratings', COUNT(*) FROM ratings

UNION ALL
SELECT 'notifications',
       COUNT(*) FROM notifications

UNION ALL
SELECT 'reported_issues',
       COUNT(*) FROM reported_issues

UNION ALL
SELECT 'activity_logs',
       COUNT(*) FROM activity_logs;
