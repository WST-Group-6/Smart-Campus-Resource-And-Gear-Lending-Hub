CREATE DATABASE IF NOT EXISTS campusshare_db;
USE campusshare_db;

CREATE TABLE IF NOT EXISTS departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    account_status ENUM('active', 'suspended', 'pending') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    owner_id INT NOT NULL,
    department_id INT NULL,
    category_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    item_condition ENUM('Brand New', 'Like New', 'Good', 'Fair') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE SET NULL,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS item_images (
    image_id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    display_order INT DEFAULT 0,
    FOREIGN KEY (item_id) REFERENCES items(item_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS borrow_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    borrower_id INT NOT NULL,
    requested_start DATE NOT NULL,
    requested_end DATE NOT NULL,
    approved_start DATE NULL,
    approved_end DATE NULL,
    status ENUM('Pending', 'Approved', 'Rejected', 'Cancelled') DEFAULT 'Pending',
    decided_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (item_id) REFERENCES items(item_id) ON DELETE CASCADE,
    FOREIGN KEY (borrower_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL UNIQUE,
    approved_due_at TIMESTAMP NOT NULL,
    handover_at TIMESTAMP NULL,
    actual_return_at TIMESTAMP NULL,
    owner_return_confirmed_at TIMESTAMP NULL,
    status ENUM('Active', 'Completed') DEFAULT 'Active',
    FOREIGN KEY (request_id) REFERENCES borrow_requests(request_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS condition_records (
    condition_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL,
    actor_id INT NOT NULL,
    phase ENUM('handover', 'return') NOT NULL,
    condition_value ENUM('Brand New', 'Like New', 'Good', 'Fair', 'Damaged') NOT NULL,
    confirmation ENUM('confirmed', 'disputed') DEFAULT 'confirmed',
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE CASCADE,
    FOREIGN KEY (actor_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ratings (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL,
    rater_id INT NOT NULL,
    target_type ENUM('user', 'item') NOT NULL,
    target_user_id INT NULL,
    stars TINYINT NOT NULL CHECK (stars BETWEEN 1 AND 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE CASCADE,
    FOREIGN KEY (rater_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (target_user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    recipient_id INT NOT NULL,
    request_id INT NULL,
    event_type VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    read_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipient_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (request_id) REFERENCES borrow_requests(request_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS reported_issues (
    issue_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NULL,
    item_id INT NULL,
    reporter_id INT NOT NULL,
    resolved_by INT NULL,
    description TEXT NOT NULL,
    status ENUM('open', 'in_progress', 'resolved') DEFAULT 'open',
    resolution TEXT NULL,
    resolved_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE SET NULL,
    FOREIGN KEY (item_id) REFERENCES items(item_id) ON DELETE SET NULL,
    FOREIGN KEY (reporter_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (resolved_by) REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS activity_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    actor_id INT NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (actor_id) REFERENCES users(user_id) ON DELETE SET NULL
);