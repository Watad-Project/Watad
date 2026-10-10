# App packages

The Flutter version the whole team uses, and the registry of every package the app may use.

`dart run tool/check_architecture.dart` compares this file with `pubspec.yaml`. CI fails on a dependency that is not in the Registry, on a dependency from the "Not allowed" list, and on a Registry row whose package is not in `pubspec.yaml`.

## 1. Flutter SDK

| Tool | Version |
|------|---------|
| Flutter | **3.47.6** (stable channel) |
| Dart | **3.13.5** (ships with Flutter 3.47.6) |

- **Everyone uses this version:** coworkers, AI agents and CI. `pubspec.yaml` declares `flutter: ">=3.47.6"` and `sdk: ^3.13.0`, so `flutter pub get` refuses an older SDK. `.github/workflows/ci.yml` runs exactly 3.47.6.
- Run `flutter --version` before you start. If it shows an older version, run `flutter upgrade`, then `flutter pub get`.
- **AI agents:** never run `flutter upgrade`, `flutter downgrade`, `flutter channel` or `flutter pub upgrade --major-versions` yourself. If the SDK does not match, stop and tell the user.
- Changing the team version is a maintainer's decision (Ameer or Omar Mulla). It is one PR that updates this section, the `environment` block of `pubspec.yaml` and `ci.yml` together, and adds a row to the update log.

### Update log

| Date | Change | What it means for you |
|------|--------|-----------------------|
| 2026-10-06 | Flutter 3.38.3 → **3.47.6** (Dart 3.10.1 → **3.13.5**) | Run `flutter upgrade`, then `flutter pub get`. The current `go_router` (18) and `pinput` (7) need Flutter 3.44 or newer, so an older SDK cannot resolve `pubspec.lock`. The lint `avoid_returning_null_for_future` no longer exists and was removed from `analysis_options.yaml`. In `supabase_flutter` 2.18, `Supabase.initialize(anonKey: …)` is deprecated; use `publishableKey: …` (same key, new name). |

## 2. Rules

1. **Look in the Registry first.** If a registered package does the job, use it.
2. **Never add a package from the "Not allowed" list.**
3. A new package must be actively maintained (a release in the last 12 months), null-safe, work on Android and iOS, and be compatible with the Flutter version above. Prefer verified publishers and high pub points.
4. Add it with `flutter pub add <name>` (`flutter pub add dev:<name>` for tools and test helpers). Commit `pubspec.yaml` and `pubspec.lock` together. Keep both dependency lists in alphabetical order.
5. **Add its row to the Registry in the same change:** package, type, purpose, where it may be imported, date added. Put the package name in backticks in the first column; the checker reads it from there.
6. Keep packages at the edges:
   - UI packages are used only inside a component in `lib/core/components/`.
   - Packages that talk to a service are used only in `datasource/` or `lib/core/`.
   - `domain/` never depends on a Flutter or service package (`APP_ARCHITECTURE.md` §5).
7. When you remove a package, delete its row in the same change.
8. `flutter pub upgrade` within the current constraints is fine. A major upgrade (`--major-versions`, or a new major in a `^x.y.z` constraint) needs a maintainer: one package per PR, with its changelog read and all checks green.

## 3. Registry

| Package | Type | Purpose | May be imported in | Added |
|---------|------|---------|--------------------|-------|
| `flutter` | SDK | The framework | `presentation/`, the non-pure `lib/core/` folders, `lib/main.dart`, `lib/app.dart` | 2026-10-06 |
| `cupertino_icons` | runtime | iOS-style icons | `presentation/` (not blocs), `lib/core/components/` | 2026-10-06 |
| `easy_localization` | runtime | Translations (`ar`, `en`), locale switching, RTL | `presentation/` (not blocs), `lib/core/components/`, `lib/core/localization/`, `lib/main.dart`, `lib/app.dart` | 2026-10-06 |
| `flutter_bloc` | runtime | State management: `Bloc`, `Cubit`, `BlocProvider`, `BlocBuilder`, … | `presentation/`, `lib/core/router/`, `lib/app.dart` | 2026-10-06 |
| `flutter_dotenv` | runtime | Loads `.env` (Supabase URL, publishable key). `.env` is git-ignored but bundled into the app: public values only | `lib/main.dart` (load) and `lib/core/config/` (read) only | 2026-10-06 |
| `get_it` | runtime | Dependency injection, registered by hand | `lib/core/di/` and `*_injection.dart` files only | 2026-10-06 |
| `go_router` | runtime | Navigation by route name | `presentation/` (not blocs), `lib/core/router/` | 2026-10-06 |
| `material_ui` | runtime | The standalone Material library that `pinput` 7 is built on. `AppOtpInput` uses its `Material` and `MaterialLocalizations`, which are other types than Flutter's own | `lib/core/components/` only (the `AppOtpInput` component) | 2026-10-10 |
| `pinput` | runtime | OTP / PIN input. The package is `pinput`, not `pin_put` | `lib/core/components/` only (the `AppOtpInput` component) | 2026-10-06 |
| `supabase_flutter` | runtime | Backend: Auth, Postgres views and RPCs, Storage, Realtime | `datasource/`, `lib/core/supabase/`, `lib/core/di/`, `lib/main.dart` | 2026-10-06 |
| `flutter_lints` | dev | Lint rules used by `analysis_options.yaml` | not imported | 2026-10-06 |
| `flutter_test` | dev (SDK) | Unit and widget tests | `test/` | 2026-10-06 |

## 4. Not allowed

| Package | Why | Use instead |
|---------|-----|-------------|
| `bloc_flutter` | An unrelated, abandoned Dart 2 package whose name looks like ours | `flutter_bloc` |
| `provider`, `riverpod`, `flutter_riverpod`, `hooks_riverpod`, `get`, `mobx`, `redux` | One state-management solution per app | `flutter_bloc` |
| `auto_route`, `beamer`, `fluro`, `routemaster` | One router per app | `go_router` |
| `injectable`, `kiwi` | One way to do DI, without code generation | `get_it`, registered by hand |
| `slang`, `intl_utils`, `flutter_i18n` | One localization system. Flutter's gen-l10n (`l10n.yaml`, `generate: true`) is not used either | `easy_localization` |
| `pin_code_fields`, `otp_text_field`, `flutter_otp_text_field` | One OTP input | `pinput` through `AppOtpInput` |
| `http`, `dio`, `chopper`, `retrofit` | The app talks only to Supabase. It never calls the blockchain REST API, and any other network access needs a maintainer | `supabase_flutter` |
| `supabase` | The plain Dart client, which `supabase_flutter` already wraps | `supabase_flutter` |
