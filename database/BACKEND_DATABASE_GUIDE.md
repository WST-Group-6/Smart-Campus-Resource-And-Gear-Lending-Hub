# CampusShare — Backend Database Integration Guide

**Project:** Smart Campus Resource & Gear Lending Hub  
**Database:** MySQL  
**Backend:** Java Spring Boot  
**Database schema:** `01_campusshare_schema.sql`

## 1. Database Structure

The CampusShare database contains 14 tables.

**Core tables:**
- `users`
- `roles`
- `user_roles`
- `departments`
- `categories`
- `items`
- `item_images`

**Lending tables:**
- `borrow_requests`
- `loans`
- `condition_records`
- `ratings`
- `notifications`
- `reported_issues`
- `activity_logs`

The backend must use the exact column names defined in `01_campusshare_schema.sql`.

## 2. User Roles

The system supports borrowers, item owners, department representatives, and administrators.

One account can have multiple roles through `user_roles`.

**Important:** Only the owner of an item can approve or reject its borrowing requests. Administrators do not approve borrowing requests.

The backend must check permissions before performing protected operations.

## 3. Borrowing Request Workflow

### Step 1 — Submit Request

A borrower selects an item and submits the requested borrowing dates.

Table: `borrow_requests`

Required columns:
- `item_id`
- `borrower_id`
- `requested_start`
- `requested_end`

Initial status: `Pending`.

The backend must validate the dates and prevent users from requesting their own items.

### Step 2 — Owner Decision

The item owner reviews the pending request.

**Approval:**
- Set `status = 'Approved'`.
- Set `approved_start` and `approved_end`.
- Set `decided_at`.

**Rejection:**
- Set `status = 'Rejected'`.
- Set `decided_at`.

Before approval, the backend must verify that the approved dates do not overlap another approved reservation or active loan for the same item.

Only pending requests can be approved or rejected.

### Step 3 — Request Cancellation

The borrower may cancel their own request while it is pending.

Update:
- `status = 'Cancelled'`
- `cancelled_at = CURRENT_TIMESTAMP`

Do not allow cancellation of approved or active borrowing transactions without an additional approved policy.

### Step 4 — Notifications

After an owner approves or rejects a request, create an in-app notification.

Table: `notifications`

Relevant columns:
- `recipient_id`
- `request_id`
- `event_type`
- `message`
- `read_at`
- `created_at`

The borrower receives the notification.

### Step 5 — Item Handover

After approval and physical handover confirmation, the backend creates a loan.

Table: `loans`

Relevant columns:
- `request_id`
- `approved_due_at`
- `handover_at`
- `status`

Initial loan status: `Active`.

Each borrowing request can have at most one loan because `loans.request_id` is unique.

### Step 6 — Condition Recording

The borrower and owner separately record the item's condition at handover and return.

Table: `condition_records`

Relevant columns:
- `loan_id`
- `actor_id`
- `phase`
- `condition_value`
- `confirmation`
- `recorded_at`

The `phase` value must be `handover` or `return`.

The `confirmation` value must be `confirmed` or `disputed`.

If the two parties disagree about the condition, the backend should flag the disagreement for administrator review.

### Step 7 — Item Return

After the borrower returns the item and the owner confirms the return, update the loan:

- `status = 'Completed'`
- `actual_return_at`
- `owner_return_confirmed_at`

The backend must verify that the authenticated user is the item's owner before accepting owner confirmation.

### Step 8 — Rating

Ratings are allowed only after the loan is completed.

Table: `ratings`

Relevant columns:
- `loan_id`
- `rater_id`
- `target_type`
- `target_user_id`
- `stars`

The rating value must be between 1 and 5.

The backend must validate that the reviewer participated in the borrowing transaction and is rating an allowed target.

### Step 9 — Reported Issues

Table: `reported_issues`

Relevant columns:
- `loan_id`
- `item_id`
- `reporter_id`
- `resolved_by`
- `description`
- `status`
- `resolution`
- `resolved_at`

Supported issue statuses:
- `open`
- `in_progress`
- `resolved`

The backend must verify permissions before allowing issue resolution.

### Step 10 — Activity Logging

Table: `activity_logs`

Relevant columns:
- `actor_id`
- `action`
- `entity_type`
- `entity_id`
- `created_at`

Record important actions such as request submission, approval, rejection, cancellation, handover, return confirmation, and rating submission.

## 4. Backend Validation Requirements

The Spring Boot backend must enforce:

1. Authentication and role-based authorization.
2. Item-owner-only request approval and rejection.
3. Valid borrowing and approved date ranges.
4. Prevention of overlapping approved reservations and active loans.
5. Pending-only request cancellation.
6. Approved-request-only loan creation after handover confirmation.
7. Completed-loan-only ratings.
8. Valid rating participants and targets.
9. Proper return confirmation.
10. Transaction handling to prevent concurrent approvals from reserving the same item.

**Important:** Database foreign keys and CHECK constraints do not enforce all these business rules. They must also be implemented in the backend.

## 5. Database Testing

The following scripts have been tested using `campusshare_integration_test`:

- `03_verify_lending_tables.sql` — Table and relationship verification.
- `04_test_lending_constraints.sql` — Database constraint testing.
- `05_test_borrowing_workflow.sql` — Complete borrowing workflow simulation.
- `06_test_request_scenarios.sql` — Cancellation, rejection, and overlapping-date detection.

These tests passed for the scenarios covered. They do not replace backend API, authorization, or concurrency tests.

## 6. Important Integration Notes

- Use `01_campusshare_schema.sql` as the shared database schema.
- Do not execute the old `02_lending_tables.sql`, because it defines incompatible versions of the lending tables.
- Do not use `campusshare_integration_test` as the production database.
- Agree on the final schema before the backend team creates Java entities and repositories.
- Apply future schema changes through reviewed migration scripts.
- Use transactions for approval, loan creation, and return operations.
- Do not rely on frontend validation alone.

## 7. Remaining Improvements

Before final deployment, the team should review:

- Date-range constraints.
- Duplicate ratings and rating-target validation.
- Condition-dispute handling.
- Overlapping reservation enforcement.
- Request and loan status-transition rules.
- Appropriate foreign-key deletion behavior to preserve borrowing history.
- Missing business-rule constraints that require backend implementation.

**Database team status:** The shared