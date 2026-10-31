# CampusShare – Backend Database Guide

**Project:** Smart Campus Resource & Gear Lending Hub  
**Database:** MySQL (`campusshare_db`)  
**Prepared by:** Database Team – Member 2  
**Status:** Development guide – pending integration with Member 1

## 1. Purpose

This guide explains how the backend team should interact with the lending database, including borrowing requests, owner approvals, loans, condition records, ratings, notifications, issue reports, and activity logs.

**Important:** Only the item owner can approve or reject a borrowing request. Administrators do not approve borrowing requests.

### Initialize the complete database

Run [`01_campusshare_schema.sql`](./01_campusshare_schema.sql) in MySQL to create the `campusshare_db` database and all application tables, including users, items, and lending operations. Use a MySQL version that enforces `CHECK` constraints (8.0.16 or later).

The other SQL files in this folder are supporting scripts for the earlier Member 2 lending-table schema. Do not run `02_lending_tables.sql` as the application schema when using the complete schema; it defines a different version of several lending tables.

## 2. Member 2 Database Tables

| Table | Purpose |
|---|---|
| `borrow_requests` | Stores borrowing requests and approval decisions |
| `loans` | Stores active and completed loans |
| `condition_records` | Records item condition during handover and return |
| `ratings` | Stores user ratings after completed loans |
| `notifications` | Stores in-app notifications |
| `reported_issues` | Records damage reports and disputes |
| `activity_logs` | Records important system activities |

## 3. Complete Borrowing Workflow

### Step 1 – Borrower submits request

The borrower selects an item and enters the requested start and end dates.

Backend responsibilities:
- Verify that the borrower is authenticated.
- Confirm that the item exists and is available.
- Validate the requested dates.
- Create a record in `borrow_requests` with status `Pending`.
- Notify the item owner if request notifications are implemented.

### Step 2 – Item owner approves or rejects

The backend must verify that the authenticated user owns the requested item.

If approved:
- Check that no approved reservation or active loan conflicts with the requested dates.
- Change the request status from `Pending` to `Approved`.
- Record `decided_at`.
- Reserve the approved period.
- Create an approval notification for the borrower.

If rejected:
- Change the request status from `Pending` to `Rejected`.
- Record `decided_at`.
- Notify the borrower.

**Do not create an active loan immediately when the owner approves.**

### Step 3 – Borrower confirms handover

When the physical item is handed over, the borrower confirms receipt.

Backend responsibilities:
- Verify the approved request.
- Verify that the authenticated borrower is the person named in the request.
- Create a record in `loans`.
- Set loan status to `Active`.
- Record the handover timestamp.
- Allow the parties to record the item's condition.

### Step 4 – Item is returned

When the borrower returns the item:
- Record the return condition.
- Record the physical return timestamp.
- Obtain the owner's confirmation.
- Update the loan status to `Completed`.
- Record the completion timestamp.

The backend must distinguish physical return from owner-confirmed completion.

### Step 5 – Ratings

After a loan is completed:
- Allow eligible participants to submit ratings.
- Validate that the rating is between 1 and 5.
- Prevent users from rating themselves.
- Prevent duplicate ratings by the same reviewer for the same loan.

### Step 6 – Issue reporting

Users can report item damage, condition disagreements, or other lending issues.

The backend must:
- Identify the related loan or borrowing request.
- Record the reporting user.
- Store the issue description and status.
- Flag condition disagreements for administrator review.

Administrators review disputes, not borrowing approvals.

## 4. Borrowing Request Statuses

| Status | Meaning |
|---|---|
| `Pending` | Waiting for item owner's decision |
| `Approved` | Owner accepted the borrowing request |
| `Rejected` | Owner rejected the request |
| `Cancelled` | Borrower cancelled while Pending |

Allowed request transitions:
- `Pending` → `Approved`
- `Pending` → `Rejected`
- `Pending` → `Cancelled`

Approved, rejected, and cancelled requests should not be changed back to Pending without a separately approved policy.

## 5. Loan Statuses

| Status | Meaning |
|---|---|
| `Active` | Borrower confirmed handover |
| `Completed` | Owner confirmed completion after return |

Allowed loan transition:

`Active` → `Completed`

The current schema does not define an intermediate `Returned` loan status. Use the existing return timestamps and agreed backend workflow.

## 6. Required Backend Operations

| Operation | Main table | Required validation |
|---|---|---|
| Create borrowing request | `borrow_requests` | Borrower, item, dates and availability |
| Approve request | `borrow_requests` | Authenticated item owner, Pending status, no overlap |
| Reject request | `borrow_requests` | Authenticated item owner, Pending status |
| Cancel request | `borrow_requests` | Authenticated borrower, Pending status |
| Confirm handover | `loans` | Correct borrower, approved request, no existing loan |
| Record condition | `condition_records` | Authorized loan participant and valid stage |
| Complete loan | `loans` | Authorized owner, Active loan, confirmed return |
| Submit rating | `ratings` | Completed loan, eligible reviewer, rating 1–5 |
| Create notification | `notifications` | Correct recipient and event |
| Report issue | `reported_issues` | Valid request or loan and authorized reporter |
| Record activity | `activity_logs` | Valid action details and authenticated user where applicable |

## 7. Overlapping Reservation Rule

Two approved borrowing requests for the same item must not have overlapping dates.

Use this overlap condition:

`existing_start <= requested_end AND existing_end >= requested_start`

Pending requests do not reserve an item.

The backend must perform the availability check and approval as one safe database transaction. Concurrent approvals must be serialized or protected with an appropriate locking strategy to prevent two requests for the same item from being approved simultaneously.

The existing SQL tests demonstrate overlap detection only. Automatic overlap prevention is not yet implemented in the database.

## 8. Database Relationships

Existing Member 2 foreign keys:

| Child table | Parent table |
|---|---|
| `loans` | `borrow_requests` |
| `condition_records` | `loans` |
| `ratings` | `loans` |
| `notifications` | `borrow_requests` |
| `reported_issues` | `loans` |
| `reported_issues` | `borrow_requests` |

Pending integration with Member 1:

- `borrow_requests.item_id` → `items`
- `borrow_requests.borrower_id` → `users`
- `condition_records.recorded_by` → `users`
- `ratings.reviewer_id` → `users`
- `ratings.reviewed_user_id` → `users`
- `notifications.user_id` → `users`
- `reported_issues.reported_by` → `users`
- `activity_logs.user_id` → `users`

The exact referenced primary-key names and column types must be confirmed from Member 1's schema before adding these foreign keys.

## 9. Recommended Backend API Endpoints

These are proposed endpoints for the backend team to agree on, not endpoints already implemented.

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/api/borrow-requests` | Submit request |
| GET | `/api/borrow-requests/my` | View borrower's requests |
| GET | `/api/borrow-requests/owner` | View requests for owner's items |
| PATCH | `/api/borrow-requests/{id}/approve` | Owner approves |
| PATCH | `/api/borrow-requests/{id}/reject` | Owner rejects |
| PATCH | `/api/borrow-requests/{id}/cancel` | Borrower cancels Pending request |
| POST | `/api/borrow-requests/{id}/handover` | Confirm handover and create loan |
| POST | `/api/loans/{id}/conditions` | Record condition |
| PATCH | `/api/loans/{id}/complete` | Confirm return and complete loan |
| POST | `/api/loans/{id}/ratings` | Submit rating |
| GET | `/api/notifications` | View notifications |
| POST | `/api/reported-issues` | Report an issue |

The backend must derive the authenticated user's identity from its authentication system, not trust arbitrary user IDs submitted by the frontend.

## 10. Transaction Requirements

Use database transactions for operations that modify several related records.

Examples:
- Approving a request and creating a notification.
- Confirming handover and creating a loan.
- Recording return information and completing a loan.
- Reporting a condition dispute and creating the related issue.

If any required operation fails, roll back the transaction.

## 11. Tests Already Completed

The Member 2 database team has tested:

- Seven tables and their primary keys.
- Six existing foreign keys.
- Invalid borrowing date rejection.
- Invalid rating rejection.
- Invalid loan foreign-key rejection.
- Issue-reference validation.
- Borrowing request creation and approval.
- Loan creation and completion.
- Condition records, notifications, ratings and activity logs.
- Pending cancellation and owner rejection SQL operations.
- Overlapping reservation detection.

These tests do not replace backend authorization, concurrency, integration, or end-to-end tests.

## 12. Remaining Work

1. Obtain Member 1's core SQL definitions.
2. Confirm the `users` and `items` primary-key names and data types.
3. Add and verify the missing foreign keys.
4. Agree on the final condition-dispute workflow.
5. Implement and test backend authentication and authorization.
6. Implement safe overlapping-reservation prevention.
7. Test the frontend–backend–database integration.
8. Review the complete database before merging the GitHub Pull Request.

## 13. Files Available in the Repository

- `database/02_lending_tables.sql`
- `database/03_verify_lending_tables.sql`
- `database/04_test_lending_constraints.sql`
- `database/05_test_borrowing_workflow.sql`
- `database/06_test_request_scenarios.sql`
