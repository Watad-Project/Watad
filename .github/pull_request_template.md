## What and why

<!-- One or two sentences. -->

## Linear issue

<!-- From the Linear workspace "Graduation Project Taibah". Replace 0 with the issue number; Linear closes the issue when this PR merges. -->
Closes GRA-0

## Review

Approved and merged only by Ameer (@73azn) or Omar Mulla (@Om4rMu). Never merge your own pull request.

## Area

- [ ] Feature: `lib/features/<feature>/<role>/` (role: client / contractor / admin / shared)
- [ ] New or changed shared component (`lib/core/components/`, registered in `docs/APP_COMPONENTS.md`)
- [ ] New or removed package (registered in `docs/APP_PACKAGES.md`)
- [ ] Other `lib/core/` changes, app setup, Flutter version or tooling (needed a maintainer's approval)
- [ ] Database change (migration proposed below)
- [ ] Blockchain / on-chain record change (needed a maintainer's approval)
- [ ] Docs only

## Checklist

- [ ] I read `AGENTS.md`, `docs/APP_ARCHITECTURE.md` and `docs/ARCHITECTURE.md`
- [ ] `flutter --version` shows Flutter 3.47.6
- [ ] The branch is `feature/gra-<n>-<feature>-<role>` (or `fix/`, `docs/`, `chore/`) and starts from the latest `main`
- [ ] `dart format .`, `flutter analyze --fatal-infos`, `flutter test` and `dart run tool/check_architecture.dart` all pass
- [ ] I ran `flutter clean` before pushing, and no `.env`, `build/` or IDE files are in the diff
- [ ] Folders are feature → role → `datasource` / `domain` / `presentation`, with no cross-feature or cross-role imports
- [ ] Only `datasource/` talks to Supabase; reads use `v_*` views; writes use RPCs or the exact columns in `ARCHITECTURE.md` §3a
- [ ] I reused existing components; any new component is registered in `APP_COMPONENTS.md`
- [ ] Any new package is registered in `APP_PACKAGES.md`
- [ ] All visible text uses translation keys, added to every language file, and the layout works in Arabic (RTL)
- [ ] No server secret or blockchain call in app code; no marketplace data goes on-chain
- [ ] New or changed behavior has a test
- [ ] If the schema, RPCs, views or buckets changed, `docs/ARCHITECTURE.md` is updated

## Database or on-chain proposal (if any)

<!-- Paste the SQL or the field change. Do not apply it to the live project. -->

## Screenshots (UI changes)

<!-- Before / after, in Arabic and English, or a short screen recording. -->

## AI assistance

<!-- Tool and model used, if any (e.g. Claude Code, Cursor, Copilot, Codex). -->
