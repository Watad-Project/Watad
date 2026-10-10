# AGENTS.md

These are the rules for every AI agent (Claude, Codex, Cursor, Copilot, Gemini, …) and every person working in this repository. They are mandatory. If a request conflicts with them, stop and say so. Do not work around them.

## 1. Read these before you work

| Order | File | When | What it contains |
|-------|------|------|------------------|
| 1 | `AGENTS.md` (this file) | Always | Golden rules, toolchain, Linear and Git workflow, checks |
| 2 | [`docs/APP_ARCHITECTURE.md`](docs/APP_ARCHITECTURE.md) | Before any change in `lib/` or `test/` | How the Flutter app is built: feature → role → layer folders, BLoC, DI, routing, localization, naming, verified code templates |
| 3 | [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Before anything that reads or writes data | The backend: Supabase tables, views, RPCs, enums, storage, blockchain sync, security |
| 4 | [`docs/APP_COMPONENTS.md`](docs/APP_COMPONENTS.md) | Before building any UI | The shared components: use one, or create it and register it |
| 5 | [`docs/APP_PACKAGES.md`](docs/APP_PACKAGES.md) | Before importing or adding a package | Flutter version, allowed packages and where they may be imported, banned packages |

Agents: open and read these files at the start of every task. They change, so don't rely on what you remember from an earlier session.

**The rules are enforced by `tool/check_architecture.dart`.** Run `dart run tool/check_architecture.dart` after every change, not only before you push. It checks the folders, names, layers, routing, every Supabase call against `docs/ARCHITECTURE.md`, translations, money and the required tests; `docs/APP_ARCHITECTURE.md` §18 lists every rule. **A pull request that fails it is rejected**, whatever else it does. Fix the code until it passes; never change the checker, the rules or `analysis_options.yaml` to make it pass.

## 2. The project

Watad (Taibah University graduation project, CS 492) is a Flutter app where **clients** (project owners) hire **contractors** (verified businesses) for construction and renovation work. It also has an off-chain marketplace. The backend is **Supabase**: Postgres with RLS, Auth, Storage and one Edge Function. Agreed projects are copied to a **Hyperledger Fabric** blockchain by the server, never by the app.

```
Flutter app --(publishable key + user session)--> Supabase --(blockchain-sync Edge Function)--> Fabric REST API --> Fabric
```

## 3. Toolchain and configuration

- **Flutter 3.47.6 (stable), Dart 3.13.5.** Run `flutter --version` before you start. `pubspec.yaml` refuses older SDKs, and CI uses exactly this version.
- **Updated on 2026-10-06** from Flutter 3.38.3. If you are still on the old version, run `flutter upgrade`, then `flutter pub get`. What changed is in [`docs/APP_PACKAGES.md`](docs/APP_PACKAGES.md) §1.
- **Configuration lives in `.env`**, read with `flutter_dotenv`. After cloning, copy `.env.example` to `.env` and ask a maintainer for the values; the app does not build without it.
  - `.env` is git-ignored: never commit it.
  - `.env` is bundled into the app, so it holds only public values: the Supabase URL and the publishable (anon) key.
- **Agents:** never run `flutter upgrade`, `flutter downgrade`, `flutter channel` or `flutter pub upgrade --major-versions`. If the SDK does not match, stop and tell the user.

## 4. Golden rules (never break these)

1. **The app talks only to Supabase**, with the publishable (anon) key and the signed-in user's session. It never calls the blockchain REST API.
2. **No server secrets** in the app, `.env`, tests or docs. Never use or commit the secret (`service_role`) key, `BLOCKCHAIN_API_KEY`, `BLOCKCHAIN_API_URL` or the `blockchain_sync_secret`. Never commit `.env`.
3. **Read through `v_*` views; write through RPC functions.** Use a direct `insert`/`update` only on the tables and exact columns in `docs/ARCHITECTURE.md` §3a. Locked columns change only through RPCs: `projects.status` after creation, `projects.taker_id`, `orders.status`, `project_payments.status`, `users.role`.
4. **The marketplace is off-chain.** Nothing from marketplace items, orders or order payments goes to the blockchain.
5. **Do not add or change fields of the on-chain record** without a maintainer's approval. On-chain payments are append-only.
6. **Soft-delete by default.**
   - Listings use `deleted_at`.
   - Users are never deleted; closing an account calls `delete_my_account()`.
   - Only `addresses`, `projects` and `reviews` allow a real delete, and only where a screen needs it.
7. **Schema changes go through numbered migrations, reviewed in a PR.** Agents never run DDL (`apply_migration`, `CREATE`, `ALTER`, `DROP`) or data-changing SQL against the live Supabase project. Reading is fine (`list_tables`, `SELECT`).
8. **Money is SAR:** `numeric` with at most 2 decimals, handled only through `Money` (`lib/core/utils/money.dart`).
9. **Dates:** timestamps are `timestamptz` (UTC). Task `start_date` / `finish_date` are Riyadh calendar days.

## 5. App rules (summary; the details are in `docs/APP_ARCHITECTURE.md`)

- **Folders:** `lib/features/<feature>/<role>/{datasource,domain,presentation}`.
  - Roles are `client`, `contractor`, `admin`, and `shared` for code every role uses the same way.
  - Create only the role folders a feature needs, e.g. `lib/features/projects/client/` and `lib/features/projects/contractor/`, but `lib/features/business_verification/admin/` alone.
- **Clean architecture:** `presentation → domain ← datasource`. `domain/` is pure Dart. Only `datasource/` talks to Supabase.
- **No cross-imports** between features or between role folders.
- **State and errors:** `flutter_bloc` for state; blocs call use cases only; repositories return `Result<T>`.
- **Wiring and text:**
  - `get_it` with constructor injection;
  - `go_router`, navigating by route name;
  - `easy_localization` for every visible string, in `ar` and `en`;
  - RTL-safe layouts.
- **Names carry the role:** `client_projects_bloc.dart`, `ClientProjectsBloc`.
- **Components:** use one from `docs/APP_COMPONENTS.md`. If none fits, create it in `lib/core/components/` first and register it in the same change.
- **Packages:** only from `docs/APP_PACKAGES.md`. A new one is registered in the same change.
- **Copy the worked example** in `docs/APP_ARCHITECTURE.md` (§8 to §12). Do not invent a new layout.

## 6. Linear, branches and pull requests

**Tasks live in Linear.**

- The workspace is **`Graduation Project Taibah`** ([linear.app/graduation-project-taibah](https://linear.app/graduation-project-taibah)). Its team key is `GRA`, so issues are `GRA-1`, `GRA-2`, …
- **Workspace check (agents):** before reading or changing anything in Linear through an MCP, read the connected workspace's name (e.g. `get_workspace`). Compare it character by character with `Graduation Project Taibah`: same letters, same capitals, same spaces, nothing added or missing.
- If it differs in even one character, stop and tell the user: *"You are not connected to the correct Linear MCP: expected the workspace `Graduation Project Taibah`, found `<name>`."* Never read, create or change issues in any other workspace.
- Agents may read issues. They change an issue (status, comment, labels) or create one only when the user asks.

**One branch per feature task.**

- Branch from the latest `main` and name the branch after the Linear issue and the feature: `feature/gra-<n>-<feature>-<role>`, e.g. `feature/gra-12-projects-client`. Fixes, docs and chores use `fix/gra-<n>-<topic>`, `docs/gra-<n>-<topic>` and `chore/gra-<n>-<topic>`.
- The `gra-<n>` part links the branch and the PR to the issue.
- Never commit on `main` and never push to it.

```bash
git switch main
git pull
git switch -c feature/gra-12-projects-client
```

**Commits** follow Conventional Commits, e.g. `feat(projects/client): add my projects page`, `fix(chat): …`, `docs: …`.

**Pull requests** go into `main`, one feature-role per PR when possible.

- Fill in the template. The description contains `Closes GRA-<n>`, so Linear closes the issue when the PR merges.
- **Only Ameer (@73azn) or Omar Mulla (@Om4rMu) approve and merge pull requests.** Never merge your own PR. Agents never approve, merge or force-push.
- GitHub enforces this on `main` with the "PR" ruleset. A merge needs all of these:
  - 1 approval from a code owner (`.github/CODEOWNERS`);
  - a fresh approval after any new commit, given by someone other than the person who pushed last;
  - a green CI `check` job.

  Deleting `main` and force-pushing to it are blocked.

## 7. How to do a task

1. Read the files in §1. Take the Linear issue (after the workspace check in §6) and create its branch.
2. Identify the feature, its role folders (`APP_ARCHITECTURE.md` §3), and the views and RPCs involved (`ARCHITECTURE.md` §6–7).
3. If the backend lacks something (table, column, view, RPC, bucket, on-chain field), stop. Write the SQL proposal in the PR description; do not apply it.
4. If a foundation file you need (`APP_ARCHITECTURE.md` §6) does not exist yet, stop and tell the user.
5. Check `APP_COMPONENTS.md` before writing UI, and `APP_PACKAGES.md` before adding a package.
6. Build in this order (`APP_ARCHITECTURE.md` §17):
   1. domain;
   2. datasource;
   3. presentation;
   4. wiring (injection and routes);
   5. translations;
   6. registries;
   7. tests.

   After each step, run `dart run tool/check_architecture.dart` and fix what it reports before you start the next one.
7. Do everything in §8, then push and open the PR.
8. Report what you changed and anything you could not do.

## 8. Before you push (definition of done)

1. Run the four checks and fix every problem in the code:

   ```bash
   dart format .
   flutter analyze --fatal-infos
   flutter test
   dart run tool/check_architecture.dart
   ```

   CI runs the same four on every PR, and a PR that fails any of them is not merged. The architecture check is the strict one: each problem names its rule, file, line and the section to read. Fix every one; there are no exceptions, and a maintainer rejects a PR that works around it.
2. Run **`flutter clean`**, so that only source files leave your machine and the project stays small. Run `flutter pub get` afterwards if you keep working.
3. Check `git status`. Only your task's files may be in the commit: no `.env`, `build/`, `.dart_tool/` or IDE files.
4. Done also means:
   - new components are in `docs/APP_COMPONENTS.md` and new packages in `docs/APP_PACKAGES.md`;
   - new translation keys are in every language file;
   - `docs/ARCHITECTURE.md` is updated if the backend changed;
   - the PR template is filled in, with `Closes GRA-<n>`.

## 9. Working with other people and agents

- **Stay inside the folders of your task.** In `lib/core/` you may only do the edits listed in `APP_ARCHITECTURE.md` §6: add a component, add your names file in `router/routes/` and spread your routes, add your DI line.
- **A maintainer must approve changes to:**
  - anything else in `lib/core/`;
  - `pubspec.yaml` (except adding a registered package);
  - `analysis_options.yaml`, `tool/`, `.github/`, `supabase/`;
  - the rule files.
- **Docs and code disagree?** If the docs disagree with the code or the database, say so in the PR. Do not silently pick one.

## 10. Changing the rules

- **Never edit the rules to make a change pass.** That covers `AGENTS.md`, `CLAUDE.md`, `docs/APP_ARCHITECTURE.md`, `docs/ARCHITECTURE.md`, `tool/check_architecture.dart`, `analysis_options.yaml` and the CI workflow. Rule changes are separate PRs approved by a maintainer.
- **Two exceptions:**
  - the registries (`APP_COMPONENTS.md`, `APP_PACKAGES.md`) are updated as part of normal work;
  - `ARCHITECTURE.md` §3–8 is updated in the same PR as an approved schema change.
- **Do not silence the analyzer** with `// ignore:` unless there is no other way. Explain it in a comment and in the PR.

## 11. Stop and ask when

- the Linear workspace name is not exactly `Graduation Project Taibah`;
- the task needs a new table, column, view, RPC, bucket or on-chain field;
- a foundation file is missing;
- you would need to change `lib/core/` beyond the allowed edits, or change a component in a way that breaks its callers;
- you need a banned package, or one that overlaps a registered package;
- you are not sure which feature or role folder something belongs in;
- the instructions conflict with these rules;
- `dart run tool/check_architecture.dart` reports a problem you can only fix by changing the checker or a rule;
- your Flutter version is not 3.47.6.

**Maintainers:** Ameer (@73azn) and Omar Mulla (@Om4rMu). They approve and merge pull requests and approve rule changes. In `docs/ARCHITECTURE.md`, a project **owner** is the client who created a project, not a maintainer.
