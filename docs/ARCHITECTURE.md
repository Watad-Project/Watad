# Watad architecture

This document describes the backend the Flutter app depends on. It was written from the live Supabase project (21 tables, 32 RPC functions, 20 views, 4 storage buckets, 1 Edge Function) on 2026-10-06. If the database changes, update this file in the same PR.

How the Flutter app itself is organised (folders, layers, BLoC, naming) is in [`APP_ARCHITECTURE.md`](APP_ARCHITECTURE.md). This file is the contract between that app and the backend.

## 1. Big picture

```
┌─────────────┐   anon key + user JWT    ┌──────────────────────────────────┐
│ Flutter app │ ───────────────────────► │ Supabase                         │
│ (BLoC)      │ ◄─────────────────────── │ Auth · Postgres (RLS) · Storage  │
└─────────────┘   views (read) / RPC     │ pg_net · pg_cron · Vault         │
                                         └─────────────────┬────────────────┘
                                                           │ x-sync-secret
                                                           ▼
                                         ┌──────────────────────────────────┐
                                         │ Edge Function: blockchain-sync   │
                                         └─────────────────┬────────────────┘
                                                           │ Bearer key, X-Org: platform
                                                           ▼
                                         ┌──────────────────────────────────┐
                                         │ Fabric REST API → Hyperledger    │
                                         │ Fabric network                   │
                                         └──────────────────────────────────┘
```

- The app only ever talks to Supabase.
- Postgres is the source of truth. The blockchain holds a verified copy of **agreed projects only**.
- Supabase region: `ap-northeast-1`. Postgres 17.

## 2. Users and roles

- `users` has one row per auth user (created by a trigger at sign-up). `users.role` is only `user` or `admin` (staff permissions). It is changed only by `admin_set_user_role()`.
- There is no "client" or "contractor" role column.
  - **Owner:** any user who creates a project (`projects.owner_id`).
  - **Contractor / taker:** a user with a row in `businesses`. The business must be `verified` to be trusted. `projects.taker_id` points to `businesses.user_id`.
- `businesses.verification_status`: `unverified → pending → verified | rejected | suspended`. Only admins change it (`admin_set_business_verification()`); the business asks with `request_business_verification()` after uploading `business_documents`.
- Suspensions are tracked in `user_suspensions` (at most one open row per user) via `admin_set_user_suspension()`.
- In the app these map to the role folders: owner → `client/`, contractor / taker → `contractor/`, `users.role = 'admin'` → `admin/` (see `APP_ARCHITECTURE.md` §3). `v_my_projects.my_role` says which side the signed-in user is on for each project: `owner` or `taker`.

## 3. Tables by domain

Legend: **RW** = the app may insert/update the signed-in user's own rows (RLS enforced). **RO** = read-only for the app, changed only by RPCs/triggers/webhook. ("The app" means any signed-in user, whatever their role.)

| Domain | Table | Access | Notes |
|--------|-------|--------|-------|
| Identity | `users` | update `full_name`, `avatar_path` only | `role` locked. Anonymised, never deleted. |
| | `businesses` | RW (own, except `verification_status`) | PK is the owner's user id. `cr_number` is 10 digits, unique. |
| | `business_documents` | insert while unverified/rejected | Files in the private `business-documents` bucket. |
| | `user_suspensions` | RO | Written by admin RPC. |
| | `addresses` | RW (owner only, delete allowed) | Private. A project's taker sees the site address only through the internal helper `private.project_site_address()` (private schema, not callable from the app). Both sides read it as `v_my_projects.site_address`; `v_my_projects.address_id` is returned to the owner only. |
| Projects | `projects` | insert as owner; edits limited | `taker_id` only by `accept_offer()`. `status` only by `set_project_status()` / `accept_offer()`. |
| | `project_offers` | insert/edit while `pending` | Decided by `accept_offer()`, `reject_offer()`, `withdraw_offer()`. |
| | `project_tasks` | propose as taker | `status` only by `set_task_status()`. |
| | `project_reports` | insert (taker, while project in progress) | "publishUpdate". |
| | `project_payments` | RO | Stages created by `add_payment_stage()`. |
| | `bank_transfers` | RO | Receipts in the private `bank-transfer-receipts` bucket. |
| Marketplace | `marketplace_items` | RW (seller) | Stock reduced only by `checkout()`. Delete = set `deleted_at`. |
| | `orders`, `order_items` | RO | Created by `checkout()`. Paid only by the payment webhook. Price and name are snapshots. |
| Social | `chats`, `chat_members` | RO | Via `start_chat()`, `add_chat_member()`, `remove_chat_member()`, `mark_chat_read()`. |
| | `messages` | insert only | Insert `{chat_id, content}`; `sender_id` comes from the session. |
| | `reviews` | insert | Only between the two parties of a completed project or delivered order. |
| Moderation | `help_reports` | insert (reporter) | Set at most one `target_*` column. Admins use `admin_assign_help_report()` / `admin_resolve_help_report()`. |
| Audit | `status_history` | RO, append-only | Written by triggers. |
| | `payment_events` | server only | One row per gateway event id. `needs_refund` / `amount_mismatch` need an admin. |

### 3a. Direct writes the app may do (exact columns)

Writes are limited twice: by RLS (which rows) and by column-level grants (which columns). Send only these columns. Anything else is rejected by the database.

| Table | INSERT columns | UPDATE columns | DELETE |
|-------|----------------|----------------|--------|
| `users` | none (trigger creates it) | `full_name`, `avatar_path` | no |
| `businesses` | `company_name`, `cr_number`, `specialized_field` | same three | no |
| `business_documents` | `document_type`, `storage_path` | none | no |
| `addresses` | `name`, `city`, `district`, `street`, `building_number`, `postal_code` | same six | yes |
| `projects` | `title`, `description`, `budget`, `city`, `district`, `address_id`, `status` | `title`, `description`, `budget`, `city`, `district`, `address_id` | yes |
| `project_offers` | `project_id`, `amount`, `message` | `amount`, `message` | no |
| `project_tasks` | `project_id`, `title`, `description`, `amount`, `start_date` | none (use `set_task_status()`) | no |
| `project_reports` | `project_id`, `title`, `content` | `title`, `content` | no |
| `marketplace_items` | `item_name`, `description`, `price`, `stock_quantity`, `is_active` | same five, plus `deleted_at` (soft delete) | no |
| `messages` | `chat_id`, `content` | none | no |
| `reviews` | `target_user_id`, `project_id` or `order_id`, `rating`, `comment` | `rating`, `comment` | yes |
| `help_reports` | `report_type`, `description`, one `target_*` column | none | no |

Every other table is read-only from the app. `projects.status` can be set on insert only (to start as `draft` or `open`); after that it changes through `set_project_status()`.

## 4. Enums (mirror these exactly in Dart)

| Enum | Values |
|------|--------|
| `app_role` | `user`, `admin` |
| `verification_status` | `unverified`, `pending`, `verified`, `rejected`, `suspended` |
| `project_status` | `draft`, `open`, `in_progress`, `completed`, `cancelled` |
| `offer_status` | `pending`, `accepted`, `rejected`, `withdrawn` |
| `task_status` | `proposed`, `accepted`, `done`, `approved`, `rejected` |
| `payment_status` (project stage) | `pending`, `processing`, `paid`, `failed`, `refunded`, `cancelled` |
| `project_payment_method` | `gateway`, `wallet`, `bank_transfer` |
| `bank_transfer_status` | `pending`, `confirmed`, `rejected`, `cancelled` |
| `order_status` | `pending_payment`, `paid`, `shipped`, `delivered`, `cancelled`, `refunded` |
| `payment_method` (orders) | `mada`, `credit_card`, `apple_pay`, `stc_pay`, `bank_transfer` |
| `report_type` | `fraud`, `scam`, `harassment`, `spam`, `inappropriate_content`, `payment_issue`, `technical_issue`, `other` |
| `report_status` | `open`, `in_review`, `resolved`, `dismissed` |
| `business_document_type` | `commercial_registration`, `vat_certificate`, `national_address`, `other` |

The Dart mirrors live in `lib/core/enums/` (see `APP_ARCHITECTURE.md` §6).

## 5. How a project moves

1. The owner inserts a project (`projects`, as `draft` or `open`). A draft is published with `set_project_status()`. Open projects appear in `v_open_projects`.
2. A business sends an offer (`project_offers`) and may edit or `withdraw_offer()` while it is `pending`.
3. The owner calls `accept_offer(p_offer_id, p_expected_amount)`. The expected amount protects against the offer changing at the last second. This assigns the taker. From here the project can be synced to the blockchain.
4. The taker proposes tasks (`project_tasks`). `set_task_status()` moves them `proposed → accepted → done → approved` (or `rejected`). Approving a priced task creates its payment stage. `start_date` / `finish_date` are optional Riyadh calendar days.
5. Payment stages are created by `add_payment_stage()` and paid by gateway (`attach_payment_intent()` then the webhook calls `record_payment_event()`), wallet, or bank transfer (`submit_bank_transfer()` then `confirm_bank_transfer()` / `reject_bank_transfer()`). `cancel_payment_stage()` cancels an unpaid stage.
6. While the project is in progress the taker posts `project_reports`.
7. When completed, both parties can leave a `reviews` row.

## 6. RPC catalogue

All are `SECURITY DEFINER` and check the caller inside. Call with `supabase.rpc('<name>', params: {...})`. Parameter names start with `p_`.

| Area | Functions |
|------|-----------|
| Projects and offers | `accept_offer(p_offer_id, p_expected_amount)`, `reject_offer(p_offer_id)`, `withdraw_offer(p_offer_id)`, `set_project_status(p_project_id, p_status)` |
| Tasks | `set_task_status(p_task_id, p_status)` |
| Project payments | `add_payment_stage(p_project_id, p_amount, p_description)`, `cancel_payment_stage(p_payment_id)`, `attach_payment_intent(p_gateway_reference, p_order_id, p_project_payment_id, p_method)`, `submit_bank_transfer(p_payment_id, p_storage_path, p_bank_reference)`, `confirm_bank_transfer(p_transfer_id)`, `reject_bank_transfer(p_transfer_id, p_reason)` |
| Webhook (server) | `record_payment_event(...)` |
| Marketplace | `checkout(p_items jsonb, p_payment_method)`, `cancel_order(p_order_id)`, `mark_order_shipped(p_order_id)`, `confirm_order_delivered(p_order_id)`, `expire_stale_orders(p_older_than)` |
| Chat | `start_chat(p_other_user_id, p_project_id)`, `add_chat_member(p_chat_id, p_user_id)`, `remove_chat_member(p_chat_id, p_user_id)`, `mark_chat_read(p_chat_id)` |
| Business | `request_business_verification()` |
| Account | `delete_my_account()` |
| Admin | `admin_set_user_role`, `admin_set_user_suspension`, `admin_set_business_verification`, `admin_assign_help_report`, `admin_resolve_help_report`, `admin_remove_listing` |
| Blockchain sync (server only) | `blockchain_sync_claim`, `blockchain_sync_snapshot`, `blockchain_sync_complete`. They need the shared secret. **The app never calls these.** |

## 7. Views (what the app reads)

| Domain | Views |
|--------|-------|
| Profile | `v_my_profile`, `v_public_profiles`, `v_my_addresses` |
| Business | `v_business_documents`, `v_admin_verification_queue` |
| Projects | `v_open_projects`, `v_my_projects`, `v_project_offers`, `v_project_tasks`, `v_project_reports`, `v_project_payments`, `v_bank_transfers` |
| Marketplace | `v_marketplace_items`, `v_my_orders`, `v_order_items` |
| Chat | `v_my_chats`, `v_chat_messages` |
| Reviews and reports | `v_reviews`, `v_my_help_reports`, `v_admin_help_reports` |

Rule: add a new screen's read by adding or reusing a `v_*` view (proposed in a PR), not by reading a base table with joins in Dart.

`v_my_projects` returns the projects of both sides. Filter with `my_role`: `owner` rows belong to the client screens, `taker` rows to the contractor screens.

This file does not list view columns. Never guess a column name: read it from the SQL in `supabase/migrations/`, or query `information_schema.columns` (read-only) through the Supabase MCP or CLI, or ask a maintainer.

## 8. Storage buckets

| Bucket | Public | Contents | Path rule |
|--------|--------|----------|-----------|
| `avatars` | yes | profile pictures | `<user id>/<file name>`, saved in `users.avatar_path` (never an external URL) |
| `images` | yes | general images (e.g. listings) | |
| `business-documents` | **no** | verification documents | path saved in `business_documents.storage_path` |
| `bank-transfer-receipts` | **no** | transfer receipts | path saved in `bank_transfers.storage_path` |

Use signed URLs for the private buckets. Never make them public.

## 9. Blockchain

**Who writes:** only the `blockchain-sync` Edge Function. The app does not.

**When:** the database calls the function (`pg_net`) right after a relevant row changes, and `pg_cron` job `blockchain-sync-retry` calls it every 2 minutes as a retry safety net.

**Security:** the function is deployed with `verify_jwt = false` because it checks its own shared secret: the header `x-sync-secret` must match the secret in Vault (`blockchain_sync_secret`), and each database call re-checks it. Without it the answer is 403. Function secrets: `BLOCKCHAIN_API_URL`, `BLOCKCHAIN_API_KEY`.

**What is synced:** only projects that have an accepted offer. Marketplace data is never synced.

**How:** it compares the database snapshot (`blockchain_sync_snapshot`) with the chain (`GET /projects/{id}`) and writes only the difference, so retries are safe and never create duplicates:

| Situation | Call |
|-----------|------|
| Not on chain | `POST /projects` |
| Data differs | `PUT /projects/{id}` |
| New paid payment | `POST /projects/{id}/payments` |

Payments are **append-only on the chain**. If a payment differs or disappears in the database, the sync reports `NEEDS ATTENTION` and a person must look at it.

**On-chain project record:** `id`, `owner`, `ownerId`, `ownerEmail`, `contractor`, `contractorId`, `contractorEmail`, `agreedPrice`, `currency` (SAR), `milestone[]` (`description`, `startDate`, `finishDate`, `status`), `payments[]` (`id`, `amount`, `date`, `note`). Task `start_date` and `finish_date` map to `startDate` and `finishDate`. Changing this shape needs a maintainer's approval, the Fabric chaincode and REST API change together with the Edge Function.

## 10. Security checklist for every change

- Every table has RLS enabled. A new table without RLS policies is a bug.
- The app uses only the anon key. A key that can bypass RLS never leaves the server.
- A new state change is a new RPC with its own checks, not a looser policy.
- The app gets INSERT/UPDATE only on the columns in section 3a. A new writable column needs an explicit grant in a migration, and section 3a must be updated.
- Sensitive files stay in private buckets.
- Run the Supabase security advisor after any schema change and fix what it reports.

## 11. Migrations

- Applied migrations are numbered in order (`00_setup` … `55_images_bucket`; the next is `56_...`). Keep the SQL files in the repo under `supabase/migrations/` (create the folder if it is not there yet) so the history is reviewable.
- One topic per migration. Never edit an applied migration; add a new one.
- A PR that changes the schema also updates sections 3 to 8 of this file.

## 12. Adding a feature (checklist)

1. Does the data exist in a `v_*` view and an RPC? If not, write the SQL proposal in the PR and wait for approval.
2. Build the Flutter side exactly as `APP_ARCHITECTURE.md` describes: `lib/features/<feature>/<role>/{datasource,domain,presentation}`. Only `datasource/` talks to Supabase.
3. Read through the view's real columns (section 7) into a model in `datasource/models/`. Write only the columns in section 3a, or call the RPC from section 6.
4. Use the Dart enum mirrors in `lib/core/enums/`. Never compare raw enum strings in features.
5. Add tests for the model mapping and any non-trivial bloc.
6. Run the checks from `AGENTS.md`.
