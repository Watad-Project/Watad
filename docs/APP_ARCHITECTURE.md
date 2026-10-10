# Watad app architecture (Flutter)

This is the rulebook for every file in `lib/` and `test/`. It is written for AI agents and people alike, and every rule in it is mandatory.

- **MUST / MUST NOT**: a hard rule. Many are checked by `dart run tool/check_architecture.dart` in CI (§18).
- **SHOULD**: the default. Break it only with a reason written in the PR.
- If a rule and an example disagree, the rule wins. If this file and the code disagree, say so in the PR; do not silently pick one.
- If something you need is not covered here, stop and ask a maintainer. Do not invent a new pattern.

Related files: [`AGENTS.md`](../AGENTS.md) (workflow and golden rules) · [`ARCHITECTURE.md`](ARCHITECTURE.md) (backend: tables, views, RPCs) · [`APP_COMPONENTS.md`](APP_COMPONENTS.md) (shared UI components) · [`APP_PACKAGES.md`](APP_PACKAGES.md) (allowed packages).

---

## 0. The rules on one screen

1. **Feature first, then role, then layer:** `lib/features/<feature>/<role>/{datasource,domain,presentation}`.
2. **Roles** are `client`, `contractor` and `admin`, plus `shared` for code that every role uses the same way. Create only the role folders a feature needs (§3).
3. **Dependency direction:** `presentation → domain ← datasource`. `domain` is pure Dart (§5).
4. **Only `datasource/` talks to Supabase.** Read `v_*` views; write through RPCs or the exact columns in `ARCHITECTURE.md` §3a (§9).
5. **No cross-imports.** A role folder never imports another role folder. A feature never imports another feature. Shared code goes in the feature's `shared/` or in `lib/core/` (§5).
6. **State management is `flutter_bloc`.** One bloc per page or flow. Blocs call use cases only (§10).
7. **Repositories return `Result<T>`** (`Success` or `Failed`). Nothing throws up to the UI (§13).
8. **Constructor injection everywhere.** `get_it` registrations live in the role folder's `*_injection.dart`; `getIt` is used only there and in route builders (§12).
9. **Navigation is `go_router`, by route name.** Names and paths live in `lib/core/router/app_routes.dart` (§11).
10. **No hard-coded text.** Every visible string is a translation key, in both language files of its group in `assets/translations/` (§14).
11. **RTL-safe layout:** `start`/`end`, never `left`/`right` (§14).
12. **Components first.** Use one from `APP_COMPONENTS.md`. If none fits, create it in `lib/core/components/` and register it in the same change (§15).
13. **Packages from the registry only.** A new package is added to `APP_PACKAGES.md` in the same change (§15).
14. **Names carry the role:** files in `client/` start with `client_`, public types with `Client` (§7).
15. **Green before done:** format, analyze, test and the architecture check all pass (§18, `AGENTS.md`).

---

## 1. Stack

| Concern | Package | Notes |
|---------|---------|-------|
| State management | `flutter_bloc` | `Bloc` by default, `Cubit` only for UI-only state (§10) |
| Navigation | `go_router` | One router, routes by name (§11) |
| Backend | `supabase_flutter` | Auth, Postgres views and RPCs, Storage, Realtime. Only in `datasource/` |
| Dependency injection | `get_it` | Manual registration, no code generation (§12) |
| Localization | `easy_localization` | One JSON file per group and language in `assets/translations/` (§14) |
| OTP / PIN input | `pinput` | Only inside the `AppOtpInput` component |
| Configuration | `flutter_dotenv` | Loads `.env` in `main()`; everything else reads it through `Env` (`lib/core/config/`) |

The full list, the Flutter version and the "not allowed" list are in [`APP_PACKAGES.md`](APP_PACKAGES.md).

---

## 2. Words used in this file

| Word | Meaning |
|------|---------|
| Feature | A product area: one folder in `lib/features/`, e.g. `projects`, `chat`. |
| Role | Who uses the code: `client`, `contractor`, `admin`. `shared` means every role, the same way. |
| Layer | `datasource`, `domain` or `presentation`, inside a role folder. |
| Component | A reusable, feature-agnostic widget in `lib/core/components/`, listed in `APP_COMPONENTS.md`. |
| Foundation | The app-wide files in `lib/main.dart`, `lib/app.dart` and `lib/core/` that the maintainers set up once (§6). |
| Maintainers | Ameer (@73azn) and Omar Mulla (@Om4rMu): the only people who approve and merge pull requests, and who approve rule changes. Not the same as a project **owner** in `ARCHITECTURE.md`, which is the client who created a project. |

---

## 3. Roles

The backend has no client or contractor column (`ARCHITECTURE.md` §2). The app groups code by who uses it:

| Folder | Who | Backend meaning | Prefix (file / type) |
|--------|-----|-----------------|----------------------|
| `client/` | The client, i.e. the project owner | The user who created the project. `v_my_projects.my_role = 'owner'` | `client_` / `Client` |
| `contractor/` | The contractor, i.e. the taker | A user with a `businesses` row (trusted once `verified`). `my_role = 'taker'` | `contractor_` / `Contractor` |
| `admin/` | Staff | `users.role = 'admin'` | `admin_` / `Admin` |
| `shared/` | Every role, the same way (also before sign-in) | Any user | none |

### Which role folders does a feature get?

| The feature is used… | Create | Example |
|----------------------|--------|---------|
| by contractors only | `contractor/` | `business`: business profile, documents, verification request |
| by admins only | `admin/` | `business_verification`: the verification queue |
| by clients only | `client/` | a client-only flow |
| by clients and contractors, with different screens or logic | `client/` + `contractor/` | `projects`: the client posts projects and accepts offers; the contractor browses open projects and sends offers |
| by every role in the same way | `shared/` only | `auth` (sign-in, OTP), `chat` |
| partly the same for everyone, partly role-specific | `shared/` + the role folders | `payments`: `shared/` lists the stages, `client/` pays, `admin/` confirms bank transfers |

Rules:

- MUST create only the role folders the feature needs. Never create empty folders "for later".
- MUST NOT copy code between role folders. If two roles need the same code, it goes in the feature's `shared/`.
- A role folder MAY import its own feature's `shared/`. `shared/` MUST NOT import any role folder.
- MUST NOT add a role column or work out the user's role inside a feature. Which areas a user may open is decided once, in the foundation (auth session and router guards).

---

## 4. Folder structure

```
lib/
├── main.dart                 # bootstrap only (§6)
├── app.dart                  # WatadApp: MaterialApp.router, theme, localization
├── core/                     # app-wide code shared by all features (§6)
└── features/
    └── <feature>/                              # snake_case, e.g. projects
        ├── client/                             # only the role folders this feature needs (§3)
        │   ├── client_<feature>_injection.dart # get_it registrations for this folder (§12)
        │   ├── datasource/
        │   │   ├── remote/                     # Supabase calls; the only code that knows table, view, column and RPC names
        │   │   ├── local/                      # on-device cache, only if the feature has one
        │   │   ├── models/                     # JSON → entity mapping
        │   │   └── repositories/               # implementations of the domain repositories
        │   ├── domain/
        │   │   ├── entities/                   # immutable plain Dart classes (also inputs like ClientNewProject)
        │   │   ├── repositories/               # abstract interfaces
        │   │   └── usecases/                   # one action per class
        │   └── presentation/
        │       ├── client_<feature>_routes.dart # this folder's GoRoutes (§11)
        │       ├── bloc/                       # blocs and cubits with their events and states
        │       ├── pages/                      # full screens, one route each
        │       └── widgets/                    # widgets used only by this folder's pages
        ├── contractor/                         # same layout, prefix contractor_
        ├── admin/                              # same layout, prefix admin_
        └── shared/                             # same layout, no prefix: <feature>_injection.dart, <feature>_routes.dart
```

Rules:

- MUST use exactly the folder names above. The checker rejects anything else, for example `data/`, `screens/`, `views/`, `models/` inside `domain/`, `helpers/` or `utils/` inside a feature.
- The only file allowed directly in a role folder is its injection file. The only file allowed directly in `presentation/` is its routes file. `datasource/` and `domain/` hold folders only.
- You MAY add sub-folders inside `remote/`, `models/`, `entities/`, `usecases/`, `bloc/`, `pages/` and `widgets/` to group files.
- MUST NOT create empty folders.

Examples:

```
lib/features/projects/                 # clients and contractors, different logic
├── client/ …
└── contractor/ …

lib/features/business_verification/    # admins only
└── admin/ …

lib/features/auth/                     # the same for everyone
└── shared/ …
```

---

## 5. Layers and allowed imports

```
presentation ──► domain ◄── datasource
 (Flutter, BLoC,   (pure      (Supabase,
  go_router, UI)    Dart)      models)
```

One action, end to end:

```
Page ─event─► Bloc ─► UseCase ─► Repository (interface, domain)
                                        ▲ implements
                         RepositoryImpl (datasource) ─► RemoteDataSource ─► Supabase

Supabase row (Map) ─► Model.fromJson ─► Entity ─► Result<T> ─► Bloc state ─► Page
```

### Import matrix

"Own" means the same feature and the same role folder, plus the same feature's `shared/` (role folders only).

| A file in… | MAY import | MUST NOT import |
|------------|------------|-----------------|
| `domain/` | Dart SDK (not `dart:ui`), own `domain/`, the pure core folders: `core/enums`, `core/error`, `core/usecase`, `core/utils` | Flutter, `dart:ui`, `flutter_bloc`, `go_router`, `easy_localization`, `get_it`, `pinput`, `supabase_flutter`, any `datasource/` or `presentation/`, other core folders |
| `datasource/` | own `domain/` and `datasource/`, `supabase_flutter`, `core/supabase`, the pure core folders | Flutter, `dart:ui`, `flutter_bloc`, `go_router`, `easy_localization`, `get_it`, `pinput`, any `presentation/`, `core/components`, `core/di`, `core/localization`, `core/router`, `core/theme` |
| `presentation/` | own `domain/` and `presentation/`, Flutter, `flutter_bloc`, `go_router`, `easy_localization`, core (except below) | any `datasource/`, `supabase_flutter`, `core/supabase`, `get_it`; `core/di` (only the routes file may import it) |
| `presentation/bloc/` | as `presentation/` | additionally: Flutter widgets (`package:flutter/…`), `dart:ui`, `go_router`, `easy_localization` |
| `<role>_<feature>_injection.dart` | everything in its own role folder (and own `shared/`), `get_it`, core | other role folders, other features |

Also:

- A file in `lib/features/A/` MUST NOT import anything from `lib/features/B/`. Features talk through navigation (§11) and share code through `lib/core/`.
- In `lib/core/`, only `core/di/` may import features (their `*_injection.dart` files) and only `core/router/` may import features (their `*_routes.dart` files). No other core file imports a feature.
- The pure core folders (`enums`, `error`, `usecase`, `utils`) MUST stay pure Dart, because `domain/` depends on them.
- `flutter_dotenv` is used only in `lib/main.dart` (to load `.env`) and `lib/core/config/` (to read it). Everything else reads configuration through `Env`.
- `lib/main.dart` and `lib/app.dart` wire the app together and may import what they need. Features MUST NOT import them.
- Only `package:watad/…` imports, never relative ones (also enforced by the analyzer).

---

## 6. `lib/core/` and the foundation

```
lib/core/
├── components/    # shared UI components, listed in APP_COMPONENTS.md
├── config/        # Env: reads .env through flutter_dotenv
├── di/            # getIt + configureDependencies()
├── enums/         # Dart mirrors of the Postgres enums (ARCHITECTURE.md §4) (pure Dart)
├── error/         # Failure, Result                                       (pure Dart)
├── localization/  # supported locales and translation helpers
├── router/        # app_router.dart (the GoRouter), app_routes.dart (names and paths)
├── supabase/      # Supabase setup, guardSupabaseCall(), storage helpers
├── theme/         # AppTheme, colors, text styles, spacing
├── usecase/       # UseCase<T, P>, NoParams                               (pure Dart)
└── utils/         # Money (SAR), date helpers, validators                 (pure Dart)
```

Rules:

- `lib/core/` MUST contain only these folders. A new one needs a maintainer, and this section and the checker are updated in the same PR.
- `lib/core/` MUST NOT contain feature logic: no feature entities or blocs, and no table, view or RPC names outside `core/supabase/`.
- In a feature task you MAY do only these edits in core:
  - add a component to `components/` and register it (§15);
  - add your route constants to `router/app_routes.dart` and spread your routes list in `router/app_router.dart` (§11);
  - add your register call to `di/injection.dart` (§12).
- Any other change in core needs a maintainer: changing how an existing component behaves, theme, errors, Supabase helpers, router guards or bootstrap.

### Foundation files

The maintainers create these once, before feature work starts. **If one you need does not exist yet, do not create your own version inside a feature task.** Stop and tell the user, so that every coworker builds on the same foundation.

| File | Contains |
|------|----------|
| `lib/main.dart` | Bootstrap only: `WidgetsFlutterBinding.ensureInitialized()`, `EasyLocalization.ensureInitialized()`, `dotenv.load()`, `Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabasePublishableKey)`, `configureDependencies()`, `runApp(EasyLocalization(child: WatadApp()))` |
| `lib/app.dart` | `WatadApp`: `MaterialApp.router` with `AppTheme`, `appRouter` and the easy_localization delegates, locales and current locale |
| `lib/core/config/env.dart` | `Env.supabaseUrl`, `Env.supabasePublishableKey`, read with `dotenv.get(…)` from `.env` (copied from `.env.example`, git-ignored, bundled into the app: public values only) |
| `lib/core/di/injection.dart` | `final GetIt getIt = GetIt.instance;` and `configureDependencies()` (§12) |
| `lib/core/error/failure.dart`, `result.dart` | `Failure` and its subclasses, `Result` (§13) |
| `lib/core/usecase/usecase.dart` | `UseCase<T, P>`, `NoParams` (§8) |
| `lib/core/supabase/supabase_guard.dart` | `guardSupabaseCall()` (§13) |
| `lib/core/router/app_router.dart`, `app_routes.dart` | `appRouter`, `AppRoutes`, sign-in and role guards (§11) |
| `lib/core/theme/` | `AppTheme` (light and dark) and the design tokens |
| `lib/core/enums/` | One file per Postgres enum in `ARCHITECTURE.md` §4 |
| `lib/core/utils/money.dart`, `dates.dart` | `Money` (§8) and the date helpers |
| `assets/translations/common.ar.json`, `common.en.json` | The shared translations (§14). Each feature adds its own pair |

---

## 7. Naming

Code, comments, commit messages and docs are in English. User-facing text lives only in the translation files.

| Thing | Pattern | Example (`projects` / `client`) |
|-------|---------|----------------------------------|
| Feature folder | snake_case noun from the backend domain | `projects`, `chat`, `business_verification` |
| File | snake_case of its main type. In a role folder it starts with the role | `client_projects_bloc.dart` |
| Public type in a role folder (class, enum, mixin, extension, typedef) | starts with `Client`, `Contractor` or `Admin` | `ClientProjectsBloc`, `ClientProject` |
| Public type in `shared/` | no role prefix (MUST NOT start with one) | `AuthBloc`, `SendOtpUseCase` |
| Entity | noun | `ClientProject`, `ClientNewProject` |
| Model | `<Entity>Model` | `ClientProjectModel` |
| Remote data source | `<Prefix><Feature>RemoteDataSource` + `…Impl` | `ClientProjectsRemoteDataSource` |
| Repository | `<Prefix><Feature>Repository` (domain) + `…Impl` (datasource) | `ClientProjectsRepositoryImpl` |
| Use case | `<Prefix><Verb><Noun>UseCase` | `ClientGetMyProjectsUseCase` |
| Bloc / Cubit | `<Prefix><Subject>Bloc` / `…Cubit` | `ClientProjectsBloc` |
| Event | `<Bloc subject>` + past-tense verb | `ClientProjectsFetched`, `ClientProjectTitleChanged` |
| State | `<Bloc subject>` + `Initial` / `LoadInProgress` / `LoadSuccess` / `LoadFailure` | `ClientProjectsLoadSuccess` |
| Page | `<Prefix><Name>Page` | `ClientProjectsPage` |
| Feature widget | `<Prefix><Name>` (no `Widget` suffix) | `ClientProjectTile` |
| Injection file / function | `<prefix><feature>_injection.dart` / `register<Prefix><Feature>Dependencies` | `registerClientProjectsDependencies` |
| Routes file / list | `<prefix><feature>_routes.dart` / `<prefix><Feature>Routes` | `clientProjectsRoutes` |
| Route constants | `AppRoutes.<prefix><Name>Name` / `…Path` | `AppRoutes.clientProjectsName` |
| Translation key | `<feature>.<role>.<key>`, or `<feature>.<key>` in `shared/`, snake_case | `projects.client.list_title` |
| Component | `App<Name>` in `app_<name>.dart` | `AppButton` |

One public type per file, except a bloc's events and states (in `part` files) and small sealed hierarchies.

---

## 8. Domain layer

Rules:

- MUST be pure Dart (§5).
- **Entities** are immutable: `final` fields, a `const` constructor, no `fromJson`/`toJson`, no Supabase types. Use `Money` for amounts, `DateTime` (UTC) for timestamps and the `lib/core/enums/` types for enum columns. A field is nullable only if its column is nullable.
- **Inputs** with several values are entities too (e.g. `ClientNewProject`). A single value such as an id is passed directly.
- **Repository interfaces** are `abstract interface class`. Every method returns `Future<Result<T>>` (or `Stream<Result<T>>` for realtime) and takes entities or plain values, never `Map`s or Supabase types.
- **Use cases** do one action through a single `call` method and depend only on repository interfaces. Business rules (validation, combining data) live here, not in blocs or widgets.

Foundation types:

```dart
// lib/core/usecase/usecase.dart
import 'package:watad/core/error/result.dart';

/// One action of the app. Blocs call use cases; use cases call repositories.
abstract interface class UseCase<T, P> {
  Future<Result<T>> call(P params);
}

/// For use cases that need no input.
final class NoParams {
  const NoParams();
}
```

```dart
// lib/core/enums/project_status.dart
/// Mirror of the Postgres enum `project_status` (ARCHITECTURE.md §4).
enum ProjectStatus {
  draft('draft'),
  open('open'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  const ProjectStatus(this.value);

  /// The exact value stored in Postgres.
  final String value;

  /// Throws on an unknown value: never guess a status.
  static ProjectStatus fromJson(String value) =>
      values.firstWhere((status) => status.value == value);

  String toJson() => value;
}
```

```dart
// lib/core/utils/money.dart
/// An amount in SAR, kept as halalas (1 SAR = 100 halalas) so sums never
/// drift. Postgres stores it as `numeric` with at most 2 decimals.
final class Money {
  const Money.halalas(this.halalas);

  /// Parses a `numeric` value as Supabase sends it.
  factory Money.fromJson(num value) => Money.halalas((value * 100).round());

  final int halalas;

  /// The value to send to a `numeric` column or an RPC parameter.
  num toJson() => halalas / 100;
}
```

The worked example used in §8 to §12 is the client's "My projects" list. It reads `v_my_projects` and creates rows in `projects`, with the real column names from the live database.

```dart
// lib/features/projects/client/domain/entities/client_project.dart
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';

/// A project the signed-in user owns: a `v_my_projects` row with
/// `my_role = 'owner'`.
class ClientProject {
  const ClientProject({
    required this.id,
    required this.title,
    required this.status,
    required this.city,
    required this.pendingOfferCount,
    required this.createdAt,
    this.district,
    this.budget,
  });

  final String id;
  final String title;
  final ProjectStatus status;
  final String city;
  final int pendingOfferCount;
  final DateTime createdAt;
  final String? district;
  final Money? budget;
}
```

```dart
// lib/features/projects/client/domain/entities/client_new_project.dart
import 'package:watad/core/utils/money.dart';

/// What the client fills in to create a project: only the `projects`
/// INSERT columns of ARCHITECTURE.md §3a.
class ClientNewProject {
  const ClientNewProject({
    required this.title,
    required this.city,
    this.description,
    this.district,
    this.budget,
    this.addressId,
    this.publish = false,
  });

  final String title;
  final String city;
  final String? description;
  final String? district;
  final Money? budget;
  final String? addressId;

  /// true: the project starts as `open`; false: as `draft`.
  final bool publish;
}
```

```dart
// lib/features/projects/client/domain/repositories/client_projects_repository.dart
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';

abstract interface class ClientProjectsRepository {
  Future<Result<List<ClientProject>>> getMyProjects();

  Future<Result<void>> createProject(ClientNewProject project);
}
```

```dart
// lib/features/projects/client/domain/usecases/client_get_my_projects_use_case.dart
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

class ClientGetMyProjectsUseCase
    implements UseCase<List<ClientProject>, NoParams> {
  const ClientGetMyProjectsUseCase(this._repository);

  final ClientProjectsRepository _repository;

  @override
  Future<Result<List<ClientProject>>> call(NoParams params) =>
      _repository.getMyProjects();
}
```

```dart
// lib/features/projects/client/domain/usecases/client_create_project_use_case.dart
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

class ClientCreateProjectUseCase implements UseCase<void, ClientNewProject> {
  const ClientCreateProjectUseCase(this._repository);

  final ClientProjectsRepository _repository;

  @override
  Future<Result<void>> call(ClientNewProject params) async {
    if (params.title.trim().isEmpty) {
      return const Failed(ValidationFailure('validation.title_required'));
    }
    return _repository.createProject(params);
  }
}
```

---

## 9. Datasource layer

Rules:

- The only layer that imports `supabase_flutter` (besides `lib/main.dart`, `core/supabase/` and `core/di/`).
- The only place that contains table, view, column, RPC and bucket names. Take them from `ARCHITECTURE.md`. **Never guess a column name**; `ARCHITECTURE.md` §7 explains how to look it up.
- **Reads** come from `v_*` views (`ARCHITECTURE.md` §7). Select only the columns the model maps (`select('id, title, …')`), and filter and order on the server.
- **Writes** go through RPCs (`ARCHITECTURE.md` §6), or are an insert/update with exactly the columns of `ARCHITECTURE.md` §3a. Build the map by hand in the remote data source; never serialize a whole entity into a write.
- **Remote data sources** are an `abstract interface class` plus an `…Impl`. They receive `SupabaseClient` through the constructor (never `Supabase.instance`), return models or `void`, and let Supabase exceptions propagate.
- **Models** extend their entity and add one `factory fromJson(Map<String, dynamic> json)`. Parse enums with `fromJson` of the core enum, amounts with `Money.fromJson` and timestamps with `DateTime.parse`. Accept `null` exactly where the column is nullable.
- **Repository implementations** implement the domain interface and wrap every call in `guardSupabaseCall` (§13). No business rules here.
- **Storage:** follow the bucket and path rules of `ARCHITECTURE.md` §8. Store paths, never URLs. Private buckets are read through signed URLs.
- **Realtime** (e.g. chat): subscribe in the remote data source, expose a `Stream`, and remove the channel when the stream is cancelled. The repository returns `Stream<Result<T>>` through `guardSupabaseStream` (§13).

```dart
// lib/features/projects/client/datasource/models/client_project_model.dart
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';

class ClientProjectModel extends ClientProject {
  const ClientProjectModel({
    required super.id,
    required super.title,
    required super.status,
    required super.city,
    required super.pendingOfferCount,
    required super.createdAt,
    super.district,
    super.budget,
  });

  /// Maps the columns selected in ClientProjectsRemoteDataSourceImpl.
  factory ClientProjectModel.fromJson(Map<String, dynamic> json) {
    final budget = json['budget'] as num?;
    return ClientProjectModel(
      id: json['id'] as String,
      title: json['title'] as String,
      status: ProjectStatus.fromJson(json['status'] as String),
      city: json['city'] as String,
      pendingOfferCount: json['pending_offer_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      district: json['district'] as String?,
      budget: budget == null ? null : Money.fromJson(budget),
    );
  }
}
```

```dart
// lib/features/projects/client/datasource/remote/client_projects_remote_data_source.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_model.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';

abstract interface class ClientProjectsRemoteDataSource {
  Future<List<ClientProjectModel>> getMyProjects();

  Future<void> createProject(ClientNewProject project);
}

class ClientProjectsRemoteDataSourceImpl
    implements ClientProjectsRemoteDataSource {
  const ClientProjectsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ClientProjectModel>> getMyProjects() async {
    final rows = await _client
        .from('v_my_projects')
        .select(
          'id, title, status, city, district, budget, pending_offer_count, '
          'created_at',
        )
        .eq('my_role', 'owner')
        .order('created_at', ascending: false);
    return rows.map(ClientProjectModel.fromJson).toList();
  }

  @override
  Future<void> createProject(ClientNewProject project) async {
    // Only the INSERT columns allowed on `projects` (ARCHITECTURE.md §3a).
    await _client.from('projects').insert({
      'title': project.title,
      'description': project.description,
      'budget': project.budget?.toJson(),
      'city': project.city,
      'district': project.district,
      'address_id': project.addressId,
      'status': (project.publish ? ProjectStatus.open : ProjectStatus.draft)
          .toJson(),
    });
  }
}
```

An RPC call looks like this (names and parameters from `ARCHITECTURE.md` §6):

```dart
await _client.rpc<void>(
  'accept_offer',
  params: {'p_offer_id': offerId, 'p_expected_amount': amount.toJson()},
);
```

```dart
// lib/features/projects/client/datasource/repositories/client_projects_repository_impl.dart
import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/projects/client/datasource/remote/client_projects_remote_data_source.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

class ClientProjectsRepositoryImpl implements ClientProjectsRepository {
  const ClientProjectsRepositoryImpl(this._remote);

  final ClientProjectsRemoteDataSource _remote;

  @override
  Future<Result<List<ClientProject>>> getMyProjects() =>
      guardSupabaseCall(_remote.getMyProjects);

  @override
  Future<Result<void>> createProject(ClientNewProject project) =>
      guardSupabaseCall(() => _remote.createProject(project));
}
```

---

## 10. Presentation layer

### Blocs

- MUST use one bloc per page or flow. Blocs never call each other; if two screens share data, both read it through their use cases.
- Use `Bloc` with events. Use `Cubit` only for UI-only state that never calls a use case (selected tab, wizard step, password visibility).
- A bloc receives **use cases** through its constructor, and nothing else: no repository, data source, `SupabaseClient`, `getIt` or `BuildContext`.
- Files: `<name>_bloc.dart` declares `part '<name>_event.dart';` and `part '<name>_state.dart';`. Events and states are a `sealed` base class with immutable `final class` subclasses and `const` constructors.
- Events are past-tense facts (`…Fetched`, `…Submitted`, `…Refreshed`, `…TitleChanged`).
- States default to a sealed set: `…Initial`, `…LoadInProgress`, `…LoadSuccess(data)`, `…LoadFailure(failure)`. A form, or a screen that must keep its data while reloading, uses one `final class …State` with a `status` enum, the data fields and `copyWith`.
- Handle every `Result` with an exhaustive `switch`. Never use `!` or a cast on a result.
- Blocs never translate text and never navigate. The page reacts to states in a `BlocListener` (navigate, show a snackbar).

```dart
// lib/features/projects/client/presentation/bloc/client_projects_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_my_projects_use_case.dart';

part 'client_projects_event.dart';
part 'client_projects_state.dart';

class ClientProjectsBloc
    extends Bloc<ClientProjectsEvent, ClientProjectsState> {
  ClientProjectsBloc(this._getMyProjects)
    : super(const ClientProjectsInitial()) {
    on<ClientProjectsFetched>(_onFetched);
  }

  final ClientGetMyProjectsUseCase _getMyProjects;

  Future<void> _onFetched(
    ClientProjectsFetched event,
    Emitter<ClientProjectsState> emit,
  ) async {
    emit(const ClientProjectsLoadInProgress());
    final result = await _getMyProjects(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(ClientProjectsLoadSuccess(data));
      case Failed(:final failure):
        emit(ClientProjectsLoadFailure(failure));
    }
  }
}
```

```dart
// lib/features/projects/client/presentation/bloc/client_projects_event.dart
part of 'client_projects_bloc.dart';

sealed class ClientProjectsEvent {
  const ClientProjectsEvent();
}

/// The page opened, the user pulled to refresh, or tapped retry.
final class ClientProjectsFetched extends ClientProjectsEvent {
  const ClientProjectsFetched();
}
```

```dart
// lib/features/projects/client/presentation/bloc/client_projects_state.dart
part of 'client_projects_bloc.dart';

sealed class ClientProjectsState {
  const ClientProjectsState();
}

final class ClientProjectsInitial extends ClientProjectsState {
  const ClientProjectsInitial();
}

final class ClientProjectsLoadInProgress extends ClientProjectsState {
  const ClientProjectsLoadInProgress();
}

final class ClientProjectsLoadSuccess extends ClientProjectsState {
  const ClientProjectsLoadSuccess(this.projects);

  final List<ClientProject> projects;
}

final class ClientProjectsLoadFailure extends ClientProjectsState {
  const ClientProjectsLoadFailure(this.failure);

  final Failure failure;
}
```

### Pages and widgets

- A page is one route and lives in `pages/`. Its bloc is created by the route builder (§11), never inside the page.
- Build pages from components (`APP_COMPONENTS.md`) and this folder's `widgets/`.
- Send events with `context.read<B>().add(…)`. Rebuild with `BlocBuilder` / `BlocSelector`, run one-off effects with `BlocListener`, or use `BlocConsumer` for both.
- No hard-coded colors, text styles or magic sizes: use `Theme.of(context)` and the tokens in `lib/core/theme/`. The checker rejects `Color(0x…)` in features.
- No hard-coded text: translation keys only (§14).
- `StatefulWidget` only for local UI objects (text controllers, focus nodes, animations), and dispose them. Never use `setState` for data that comes from the backend.
- Keep `build` small. Extract widget classes, not helper methods that return widgets. Use `const` wherever possible.
- A widget in `widgets/` is used only inside its role folder. If the same feature's other roles need it, move it to the feature's `shared/presentation/widgets/`. If other features need it, make it a component (§15).

```dart
// lib/features/projects/client/presentation/pages/client_projects_page.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/layout/app_scaffold.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_project_tile.dart';

class ClientProjectsPage extends StatelessWidget {
  const ClientProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'projects.client.list_title'.tr(),
      body: BlocBuilder<ClientProjectsBloc, ClientProjectsState>(
        builder: (context, state) => switch (state) {
          ClientProjectsInitial() ||
          ClientProjectsLoadInProgress() => const AppLoadingIndicator(),
          ClientProjectsLoadFailure(:final failure) => AppErrorView(
            message: failure.messageKey.tr(),
            onRetry: () => context.read<ClientProjectsBloc>().add(
              const ClientProjectsFetched(),
            ),
          ),
          ClientProjectsLoadSuccess(:final projects) when projects.isEmpty =>
            AppEmptyView(message: 'projects.client.empty'.tr()),
          ClientProjectsLoadSuccess(:final projects) => ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) =>
                ClientProjectTile(project: projects[index]),
          ),
        },
      ),
    );
  }
}
```

```dart
// lib/features/projects/client/presentation/widgets/client_project_tile.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';

/// One row of the client's project list.
class ClientProjectTile extends StatelessWidget {
  const ClientProjectTile({required this.project, this.onTap, super.key});

  final ClientProject project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(project.title),
      subtitle: Text(project.city),
      trailing: Text(
        'projects.client.offers_count'.tr(
          namedArgs: {'count': '${project.pendingOfferCount}'},
        ),
      ),
      onTap: onTap,
    );
  }
}
```

---

## 11. Routing (go_router)

- There is one `GoRouter`: `appRouter` in `lib/core/router/app_router.dart`. It only spreads the routes lists of the role folders and holds the guards (signed in, role). Features MUST NOT add their own redirects.
- Every route has a name and a path constant in `lib/core/router/app_routes.dart`.
- Paths are `/<role>/<feature>/…` for role folders (e.g. `/client/projects/:projectId`) and `/<feature>/…` for `shared/` (e.g. `/auth/sign-in`). Use kebab-case segments and pass ids as path parameters.
- Navigate by name: use `context.pushNamed(…)` to open a page on top (details, forms) and `context.goNamed(…)` to switch area (after sign-in, bottom-navigation tabs). MUST NOT build paths by string interpolation, and MUST NOT use `Navigator.push` or `MaterialPageRoute`.
- Pass ids, not objects. Do not pass entities through `extra:`. The destination page loads its own data by id, which keeps deep links and refreshes working.
- Each role folder exposes its routes as a top-level `final List<RouteBase>` in `presentation/<prefix><feature>_routes.dart`. The route builder creates the page's bloc.
- Dialogs and bottom sheets are not routes. Open them from the page with `showDialog` or `showModalBottomSheet`.

```dart
// lib/features/projects/client/presentation/client_projects_routes.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/app_routes.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';
import 'package:watad/features/projects/client/presentation/pages/client_projects_page.dart';

final List<RouteBase> clientProjectsRoutes = [
  GoRoute(
    name: AppRoutes.clientProjectsName,
    path: AppRoutes.clientProjectsPath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<ClientProjectsBloc>()..add(const ClientProjectsFetched()),
      child: const ClientProjectsPage(),
    ),
  ),
];
```

```dart
// lib/core/router/app_routes.dart (add your constants, grouped by feature and role)
abstract final class AppRoutes {
  // projects / client
  static const String clientProjectsName = 'client-projects';
  static const String clientProjectsPath = '/client/projects';
}
```

```dart
// lib/core/router/app_router.dart (spread your list)
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.clientProjectsPath,
  routes: [...clientProjectsRoutes],
);
```

Opening a page with an id:

```dart
context.pushNamed(
  AppRoutes.clientProjectDetailsName,
  pathParameters: {'projectId': project.id},
);
```

### How the router is set up

The router is set up once, in `lib/core/router/`. Every route lives in the feature that owns it.

| File | Holds |
|------|-------|
| `app_routes.dart` | `AppRoutes`: every route's name and path |
| `app_router.dart` | `appRouter`, built by `createAppRouter()`: starts on `/splash`, spreads each role folder's routes list, holds the guard (`_guard`) and shows `AppNotFoundView` for unknown addresses |

These routes exist today. Each one opens a placeholder page ("This screen is still being built") until its issue builds the real screen:

| Path | Name constant | Routes file (in `lib/features/`) | Page | Issue |
|------|---------------|----------------------------------|------|-------|
| `/splash` | `splashName` | `splash/shared/presentation/splash_routes.dart` | `SplashPage` | GRA-8 |
| `/onboarding` | `onboardingName` | `onboarding/shared/presentation/onboarding_routes.dart` | `OnboardingPage` | GRA-9 |
| `/auth/login` | `loginName` | `auth/shared/presentation/auth_routes.dart` | `LoginPage` | GRA-10 |
| `/auth/role` | `roleSelectionName` | `auth/shared/presentation/auth_routes.dart` | `RoleSelectionPage` | GRA-11 |
| `/auth/signup/client` | `signUpClientName` | `auth/shared/presentation/auth_routes.dart` | `SignUpClientPage` | GRA-12 |
| `/auth/signup/business` | `signUpBusinessName` | `auth/shared/presentation/auth_routes.dart` | `SignUpBusinessPage` | GRA-13 |
| `/contractor/business-verification/license` | `contractorLicenseUploadName` | `business_verification/contractor/presentation/contractor_business_verification_routes.dart` | `ContractorLicenseUploadPage` | GRA-14 |
| `/business-verification/status` | `verificationStatusName` | `business_verification/shared/presentation/business_verification_routes.dart` | `VerificationStatusPage` | GRA-15 |
| `/contractor/onboarding/specialty` | `contractorSpecialtyName` | `onboarding/contractor/presentation/contractor_onboarding_routes.dart` | `ContractorSpecialtyPage` | GRA-16 |

**Your screen already has a placeholder?** Replace the page in your `pages/` folder. Keep the route's name and path. If the page needs a bloc, create it in the route's builder (see the example above). You don't touch `lib/core/`.

**Adding a new route:**

1. Add its name and path to `AppRoutes`, in a block for your feature and role.
2. Add a `GoRoute` to your role folder's routes list in `presentation/<prefix><feature>_routes.dart`. Create the file if your folder doesn't have one yet.
3. If you created a routes file, spread its list in `createAppRouter()` (sorted by file name). The `AppRoutes` constants and this one line are the only core edits a feature makes (§6).
4. Add the route to the list in `test/core/router/app_router_test.dart`, which opens every route by name.
5. Navigate by name: `context.goNamed(AppRoutes.loginName)`.

**Guards** live only in `_guard` in `app_router.dart`. For now it lets every route through. The auth issues add the rules from the session: signed out goes to the login page, and a role without access goes to its own home.

---

## 12. Dependency injection (get_it)

get_it is how the layers of §5 meet without knowing each other. Every class asks for what it needs **in its constructor**, typed as the layer below (its interface, where it has one). Only the injection files know which class fills each constructor, and only they and the route builders touch `getIt`. So a bloc never knows Supabase exists, and a test can hand any class a fake.

### Rules

- There is one container: `getIt` in `lib/core/di/injection.dart`. `configureDependencies()` registers the core services and then calls one register function per role folder, in alphabetical order. `main()` calls it once, after `Supabase.initialize()`.
- Each role folder has exactly one `<prefix><feature>_injection.dart` at its root with `void register<Prefix><Feature>Dependencies(GetIt getIt)`. It registers that folder's classes only.
- Lifetimes: data sources, repositories and use cases use `registerLazySingleton`. Blocs and cubits always use `registerFactory`, so each `BlocProvider` gets a fresh instance and closes it.
- Register against the interface: `registerLazySingleton<ClientProjectsRepository>(() => ClientProjectsRepositoryImpl(getIt()))`.
- Inject through constructors everywhere. `getIt` may appear only in `lib/core/di/`, `lib/core/router/`, `*_injection.dart` files, `*_routes.dart` files, `lib/main.dart` and `lib/app.dart`. Never in blocs, use cases, repositories, data sources or widgets. `package:get_it` itself is imported only in `lib/core/di/` and the injection files; routes files take `getIt` from `lib/core/di/injection.dart`.
- Register each class once, in the role folder that owns it. get_it throws on a second registration of the same type.
- A bloc that needs an id gets it in an event, not in its constructor (see step 4).
- No `injectable` and no code generation.

### How one folder is wired

Read it from the bottom up. The route builder asks get_it for a bloc. get_it builds the bloc with its use case, the use case with the repository, the repository with the data source, and the data source with the Supabase client. Each `getIt()` inside a register call fills one constructor parameter, by its type.

```
lib/core/di/injection.dart        SupabaseClient                         registerLazySingleton
                                     │ constructor
client_projects_injection.dart    ClientProjectsRemoteDataSource ◄─ …Impl  registerLazySingleton<interface>
                                     │ constructor
                                  ClientProjectsRepository ◄─ …Impl        registerLazySingleton<domain interface>
                                     │ constructor
                                  ClientGetMyProjectsUseCase               registerLazySingleton
                                     │ constructor
                                  ClientProjectsBloc                       registerFactory
                                     ▲
client_projects_routes.dart       getIt<ClientProjectsBloc>() in the GoRoute builder
```

| Class | Register with | Registered as | Why |
|-------|---------------|---------------|-----|
| `SupabaseClient` | `registerLazySingleton` | `SupabaseClient` | Once, in `lib/core/di/`. Never in a feature |
| Remote data source | `registerLazySingleton` | its interface: `<ClientProjectsRemoteDataSource>` | Stateless, one for the app |
| Repository | `registerLazySingleton` | the domain interface: `<ClientProjectsRepository>` | The use case asks for the interface, so it never sees `…Impl` or Supabase |
| Use case | `registerLazySingleton` | its own class | Stateless, one for the app |
| Bloc / cubit | `registerFactory` | its own class | A new one for each page. `BlocProvider` closes it when the page goes away, and a closed bloc cannot take events again |

### Step by step

**1. Constructors.** Each class takes its dependencies as constructor parameters, typed as the layer below. No `getIt`, no `Supabase.instance`:

```dart
class ClientProjectsRemoteDataSourceImpl
    implements ClientProjectsRemoteDataSource {
  const ClientProjectsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;
}

class ClientProjectsRepositoryImpl implements ClientProjectsRepository {
  const ClientProjectsRepositoryImpl(this._remote);

  final ClientProjectsRemoteDataSource _remote; // the interface
}

class ClientGetMyProjectsUseCase
    implements UseCase<List<ClientProject>, NoParams> {
  const ClientGetMyProjectsUseCase(this._repository);

  final ClientProjectsRepository _repository; // the domain interface
}

class ClientProjectsBloc
    extends Bloc<ClientProjectsEvent, ClientProjectsState> {
  ClientProjectsBloc(this._getMyProjects)
    : super(const ClientProjectsInitial());

  final ClientGetMyProjectsUseCase _getMyProjects; // use cases only
}
```

**2. The injection file** registers the folder's classes, bottom layer first:

```dart
// lib/features/projects/client/client_projects_injection.dart
import 'package:get_it/get_it.dart';
import 'package:watad/features/projects/client/datasource/remote/client_projects_remote_data_source.dart';
import 'package:watad/features/projects/client/datasource/repositories/client_projects_repository_impl.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';
import 'package:watad/features/projects/client/domain/usecases/client_create_project_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_my_projects_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';

/// Registers everything in lib/features/projects/client/.
void registerClientProjectsDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<ClientProjectsRemoteDataSource>(
      () => ClientProjectsRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<ClientProjectsRepository>(
      () => ClientProjectsRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => ClientGetMyProjectsUseCase(getIt()))
    ..registerLazySingleton(() => ClientCreateProjectUseCase(getIt()))
    ..registerFactory(() => ClientProjectsBloc(getIt()));
}
```

**3. One line in core.** Call the register function from `configureDependencies()`, in alphabetical order. This line is the only edit a feature makes in `lib/core/di/` (§6):

```dart
// lib/core/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/projects/client/client_projects_injection.dart';

/// The app's only service locator. Use it only in *_injection.dart and
/// *_routes.dart files (APP_ARCHITECTURE.md §12).
final GetIt getIt = GetIt.instance;

/// Called once from main(), after Supabase.initialize().
void configureDependencies() {
  // Lazy, so registering never touches Supabase: data sources take the
  // client through their constructor.
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Features: one line per role folder, in alphabetical order.
  registerClientProjectsDependencies(getIt);
}
```

**4. The route builder** asks for the bloc. It is the only place a bloc comes from (§11):

```dart
GoRoute(
  // name and path from the folder's names (§11)
  builder: (context, state) => BlocProvider(
    create: (_) =>
        getIt<ClientProjectsBloc>()..add(const ClientProjectsFetched()),
    child: const ClientProjectsPage(),
  ),
),
```

A bloc for one item gets the id from the path in its first event, so get_it never needs to know it:

```dart
builder: (context, state) => BlocProvider(
  create: (_) => getIt<ClientProjectDetailsBloc>()
    ..add(ClientProjectDetailsFetched(state.pathParameters['projectId']!)),
  child: const ClientProjectDetailsPage(),
),
```

**5. The page** reads the bloc from the context, never from get_it: `BlocBuilder<ClientProjectsBloc, ClientProjectsState>(…)`, `context.read<ClientProjectsBloc>().add(…)` (§10).

### Sharing

- **Inside a feature:** `shared/` registers its classes in `<feature>_injection.dart`, and the role folders use them through `getIt()` in their own register calls. For example, `ClientPayStageUseCase(getIt())` in `client_payments_injection.dart` receives the `PaymentsRepository` that `payments_injection.dart` registered. The order of the register calls does not matter: lazy singletons and factories are built on first use, after `configureDependencies()` has finished.
- **Between features:** never. A feature cannot import another feature's types (§5), so it cannot ask get_it for them either. A service that several features need goes in `lib/core/` and is registered in `configureDependencies()` by a maintainer.

### Testing

- Unit tests of use cases, blocs and repositories do not use get_it. Build the class with hand-written fakes through its constructor (§16).
- A test that opens a route runs its builder, which calls `getIt`. Register what the builder needs, with fakes, and reset after each test:

```dart
setUp(() {
  getIt.registerFactory(
    () => ClientProjectsBloc(
      ClientGetMyProjectsUseCase(
        FakeClientProjectsRepository(const Success([])),
      ),
    ),
  );
});
tearDown(getIt.reset);
```

- Never call `configureDependencies()` in a test: it registers the real Supabase client.

### Common mistakes

| Mistake | Do this instead |
|---------|-----------------|
| `getIt<…>()` inside a bloc, use case, repository, data source or widget | Take it as a constructor parameter |
| `Supabase.instance.client` in a data source | Take `SupabaseClient` in the constructor |
| `registerLazySingleton(() => ClientProjectsBloc(…))` | `registerFactory`: the second visit to the page would get a closed bloc and crash |
| `registerLazySingleton(() => ClientProjectsRepositoryImpl(…))` | `registerLazySingleton<ClientProjectsRepository>(…)`: without the interface type, `getIt<ClientProjectsRepository>()` finds nothing |
| A use case or bloc that asks for `…RepositoryImpl` | Ask for the domain interface |
| A bloc that takes a repository, or another bloc | A bloc takes use cases only. Two screens that share data each read it through a use case (§10) |
| `BlocProvider(create: …)` in a page | Create the bloc in the route builder |
| Registering a `shared/` class again in a role folder | Register it once, in `shared/`, and resolve it with `getIt()` |
| An id as a bloc constructor parameter | Send it in the first event |
| `GetIt.instance` / `GetIt.I` in a feature, or a second `GetIt` | Use `getIt` from `lib/core/di/injection.dart`, in injection and routes files only |

---

## 13. Errors

The flow is always the same. Supabase throws in the data source. `guardSupabaseCall` in the repository turns it into a `Failure`. The repository returns `Failed(failure)`, the bloc emits a failure state, and the page shows `failure.messageKey.tr()`.

```dart
// lib/core/error/result.dart
import 'package:watad/core/error/failure.dart';

/// What a repository returns. Repositories never throw: they return
/// [Success] with the data or [Failed] with a [Failure].
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

final class Failed<T> extends Result<T> {
  const Failed(this.failure);

  final Failure failure;
}
```

`lib/core/error/failure.dart` declares `sealed class Failure { final String messageKey; final Object? cause; }` and these subclasses. The mapping from Supabase errors lives in `lib/core/supabase/supabase_guard.dart` and nowhere else: `guardSupabaseCall` wraps a `Future`, and `guardSupabaseStream` wraps a realtime `Stream` (each event becomes `Success`, each error `Failed`). The messages are in `assets/translations/errors.*.json` and `validation.*.json`.

| Failure | When (Postgres / PostgREST code, HTTP status) | `messageKey` |
|---------|------|--------------|
| `NetworkFailure` | No connection, timeout | `errors.network` |
| `AuthFailure` | Not signed in, session expired, wrong OTP (auth errors, `PGRST301`–`PGRST303`, `401`) | `errors.auth` |
| `PermissionFailure` | RLS or an RPC rejected the caller (`42501`, `403`) | `errors.permission` |
| `NotFoundFailure` | No row (`PGRST116`), an RPC found nothing (`P0002`), a missing file (`404`) | `errors.not_found` |
| `ConflictFailure` | Unique violation (`23505`), or the data changed meanwhile (`40001`, `409`) | `errors.conflict` |
| `RateLimitFailure` | Too many attempts, e.g. asking for sign-in codes (`429`) | `errors.rate_limit` |
| `ValidationFailure` | A use case rejected the input (its own key, e.g. `validation.title_required`), or a database rule did (`23514`, `23502`, `22P02`, `22023`: `validation.invalid`) | its own key |
| `ServerFailure` | Any other database, storage or RPC error | `errors.server` |
| `UnknownFailure` | Anything else | `errors.unknown` |

**The RPCs and the table disagree today.** Every RPC raises its rules (`'Only the project owner can accept offers'`, `'The offer amount changed to %; review it again'`, …) as Postgres `P0001` with an English message and no code, so all of them reach the app as `ServerFailure`. The fix is a migration that gives them codes: `42501` when the caller may not do it, `P0002` when the row is not found, `40001` when the data changed meanwhile, `22023` when an argument is invalid. The app already maps those codes, so it needs no change then. Never parse the message text instead.

Rules:

- Data sources throw. Repositories never throw; they return `Result`. Use cases and blocs never `try`/`catch` backend errors; they `switch` on the `Result`.
- Never show `error.toString()` or a raw database message to the user.
- Never swallow a failure. Every `Failed` ends in something visible: an error view or a snackbar.
- Never `print`. Log with `log()` from `dart:developer`.

---

## 14. Localization and RTL

- All user-facing text comes from easy_localization. The locales are `ar` (right-to-left) and `en`.
- Text is split into groups. Each group has one file per language in `assets/translations/`, named `<group>.<language>.json`:
  - `common`: shared words (Save, Cancel, Retry, …), also used by the components;
  - `errors`: failure messages (§13);
  - `validation`: form messages;
  - one group per feature, named exactly like its folder in `lib/features/`. The feature owns its two files, so teams don't edit the same file.
- Write the keys without the group's name: `AppTranslationsLoader` puts each file under its group. Inside a file, keys are nested JSON and snake_case, with a sub-object per role for role-specific text.
- Every key MUST exist in both languages of its group. Add the keys in the same change as the code; the checker compares the files.
- A new feature adds `<feature>.ar.json` and `<feature>.en.json`. There is nothing to register: `assets/translations/` is already in `pubspec.yaml`, and the loader finds new files by name.

`assets/translations/projects.en.json` (its Arabic twin is `projects.ar.json`, with the same keys):

```json
{
  "client": {
    "list_title": "My projects",
    "empty": "You have no projects yet.",
    "offers_count": "{count} offers"
  }
}
```

`assets/translations/common.en.json`, `errors.en.json` and `validation.en.json` look the same, e.g. `{ "retry": "Retry" }`. The keys above are read as `projects.client.list_title` and `common.retry`.

- In code: `'projects.client.list_title'.tr()`, with values `'projects.client.offers_count'.tr(namedArgs: {'count': '$n'})`, and plurals with `.plural(n)`.
- Blocs, use cases and repositories never translate. They carry keys (`Failure.messageKey`) or data; widgets translate.
- In widgets, SHOULD prefer `context.tr('projects.client.list_title')`. It rebuilds the widget when the language changes; `'…'.tr()` reads a global and can leave a `const` widget in the old language.
- Inside a group, start the key with the screen, then the element: `auth.login_title`, `auth.login_email_hint`, `projects.client.details_title`.
- Format money through `Money` and the money component, and dates through the helpers in `lib/core/utils/`. Never build strings like `"SAR 1,500"` by hand.

Setup (`lib/core/localization/app_localization.dart`):

- `main.dart` wraps the app in `AppLocalization.scope`. The first launch is in Arabic; after that the app opens in the language the person picked last, saved on the phone.
- `WatadApp` takes the localization delegates, the supported locales and the current locale from easy_localization. Arabic runs right to left and English left to right with no work in the screens.
- Change the language with `context.changeLanguage(AppLocalization.english)` or `context.toggleLanguage()`. Read it with `context.isArabic`.
- easy_localization re-exports `intl`, which has its own `TextDirection`. A file that imports both easy_localization and Flutter's `TextDirection` adds `hide TextDirection` to the easy_localization import.
- In widget tests, use `pumpComponent` or `pumpLocalizedApp` from `test/helpers/pump_component.dart`. They load the real translation files, so a missing key fails the test.

RTL (the checker enforces the first four):

| Instead of | Use |
|------------|-----|
| `EdgeInsets.only(left: …, right: …)` | `EdgeInsetsDirectional.only(start: …, end: …)` |
| `EdgeInsets.fromLTRB(…)` | `EdgeInsetsDirectional.fromSTEB(…)` |
| `Alignment.centerLeft`, `Alignment.topRight`, … | `AlignmentDirectional.centerStart`, `AlignmentDirectional.topEnd`, … |
| `TextAlign.left` / `TextAlign.right` | `TextAlign.start` / `TextAlign.end` |
| `BorderRadius.only(topLeft: …)` | `BorderRadiusDirectional.only(topStart: …)` |
| `Positioned(left: …)` | `PositionedDirectional(start: …)` |

Icons that point in a direction (back, forward, chevrons) must flip in RTL. Check every new page once in Arabic.

---

## 15. Components and packages

### Components ([`APP_COMPONENTS.md`](APP_COMPONENTS.md))

1. Before writing any widget, look in `APP_COMPONENTS.md`. If a component exists, use it. Do not rebuild it, copy it, or wrap it in a near-duplicate.
2. If it almost fits, add an optional parameter (existing calls must keep working) and update its row. A breaking change needs a maintainer.
3. If none exists and the piece is generic (button, field, dialog, badge, card, empty, error or loading view, …), create it in `lib/core/components/<category>/app_<name>.dart` **first**, then use it, and register it in the same change. Use the reserved name if `APP_COMPONENTS.md` lists one.
4. If the piece only makes sense inside one role folder (it shows that folder's entity), it goes in that folder's `presentation/widgets/`. It is not a component and is not registered.
5. Third-party UI widgets (e.g. `Pinput`) are used only inside a component. Features use the component.

### Packages ([`APP_PACKAGES.md`](APP_PACKAGES.md))

1. Use only the packages in the Registry of `APP_PACKAGES.md`, and only in the folders its "May be imported in" column allows.
2. Need a new one? Check the "Not allowed" list first, add it with `flutter pub add <name>`, then add its row to the Registry in the same change. The checker fails on an unregistered or banned dependency.

---

## 16. Tests

- `test/` mirrors `lib/`. `lib/features/projects/client/datasource/models/client_project_model.dart` is tested in `test/features/projects/client/datasource/models/client_project_model_test.dart`.
- MUST test every model's `fromJson` (with a realistic row from the view, including `null`s), every use case that has logic, and every bloc's success and failure paths.
- Use hand-written fakes that implement the domain interfaces. Tests never call the real Supabase project. (`mocktail` and `bloc_test` are not in the registry; add and register them if the team wants them.)

```dart
// test/features/projects/client/datasource/models/client_project_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_model.dart';

void main() {
  test('fromJson maps a v_my_projects row', () {
    final project = ClientProjectModel.fromJson(const {
      'id': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
      'title': 'Kitchen renovation',
      'status': 'in_progress',
      'city': 'Madinah',
      'district': null,
      'budget': 15000.5,
      'pending_offer_count': 2,
      'created_at': '2026-10-06T09:30:00+00:00',
    });

    expect(project.status, ProjectStatus.inProgress);
    expect(project.budget?.halalas, 1500050);
    expect(project.district, isNull);
    expect(project.createdAt.isUtc, isTrue);
  });
}
```

```dart
// test/features/projects/client/presentation/bloc/client_projects_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_my_projects_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';

class FakeClientProjectsRepository implements ClientProjectsRepository {
  FakeClientProjectsRepository(this.result);

  final Result<List<ClientProject>> result;

  @override
  Future<Result<List<ClientProject>>> getMyProjects() async => result;

  @override
  Future<Result<void>> createProject(ClientNewProject project) async =>
      const Success(null);
}

ClientProjectsBloc buildBloc(Result<List<ClientProject>> result) =>
    ClientProjectsBloc(
      ClientGetMyProjectsUseCase(FakeClientProjectsRepository(result)),
    );

void main() {
  test('emits LoadInProgress then LoadSuccess', () async {
    final bloc = buildBloc(
      Success([
        ClientProject(
          id: 'p1',
          title: 'Kitchen renovation',
          status: ProjectStatus.open,
          city: 'Madinah',
          pendingOfferCount: 0,
          createdAt: DateTime.utc(2026, 10, 6),
        ),
      ]),
    );

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ClientProjectsLoadInProgress>(),
        isA<ClientProjectsLoadSuccess>(),
      ]),
    );
    bloc.add(const ClientProjectsFetched());
    await states;
    await bloc.close();
  });

  test('emits LoadInProgress then LoadFailure', () async {
    final bloc = buildBloc(const Failed(NetworkFailure()));

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ClientProjectsLoadInProgress>(),
        isA<ClientProjectsLoadFailure>(),
      ]),
    );
    bloc.add(const ClientProjectsFetched());
    await states;
    await bloc.close();
  });
}
```

---

## 17. Recipe: adding a feature (or a role to a feature)

1. **Name it.** Find the backend domain in `ARCHITECTURE.md` §3. Look in `lib/features/` for a folder that already covers it, and extend that one instead of creating a near-duplicate.
2. **Pick the role folders** with the table in §3.
3. **Confirm the backend.** Find the views to read (`ARCHITECTURE.md` §7), and the RPCs or §3a columns to write. Look up the real column names. If something is missing, stop and write the SQL proposal in the PR.
4. **Domain:** entities → repository interface → use cases.
5. **Datasource:** models → remote data source → repository implementation.
6. **Presentation:** bloc (events, states) → pages → widgets, built from components first.
7. **Wire it up:** `<prefix><feature>_injection.dart` plus one line in `lib/core/di/injection.dart`; `<prefix><feature>_routes.dart`, its constants in `app_routes.dart`, and the spread in `app_router.dart`.
8. **Text:** add the keys to your feature's `<feature>.ar.json` and `<feature>.en.json`.
9. **Registries:** add new components to `APP_COMPONENTS.md` and new packages to `APP_PACKAGES.md`.
10. **Tests** (§16).
11. **Run the four checks** (`AGENTS.md`) and fix every problem in the code. Never weaken a rule to pass.

---

## 18. What the checker enforces

`dart run tool/check_architecture.dart` runs locally and in CI. Each problem is printed with its rule name:

| Rule | What it checks |
|------|----------------|
| `structure` | `lib/` has only `main.dart`, `app.dart`, `core/`, `features/`; `lib/core/` has only the folders of §6; feature → role → layer → folder names exactly as in §4; only the injection file in a role folder and only the routes file in `presentation/` |
| `naming` | Files in a role folder start with the role (`client_…`); public types start with it (`Client…`); `shared/` uses no role prefix (§7) |
| `layers` | The import matrix of §5, including pure-Dart `domain/` and pure core folders, no Flutter in blocs, and no relative imports |
| `isolation` | No feature imports another feature; no role folder imports another role folder; `shared/` imports no role; only `core/di` and `core/router` import features |
| `packages` | `supabase_flutter`, `get_it`, `pinput` and `flutter_dotenv` only where allowed |
| `di` | `getIt` only in `core/di`, `core/router`, `*_injection.dart`, `*_routes.dart`, `main.dart`, `app.dart` |
| `secrets` | No server-only secret, key or function name in `lib/` or `test/` (even in comments); no hard-coded Supabase URL or key; only placeholders in `.env.example`; `.env` never committed |
| `registry` | Every `pubspec.yaml` dependency is registered in `APP_PACKAGES.md` and none is on its "Not allowed" list; every public type in `lib/core/components/` is in `APP_COMPONENTS.md`; no stale rows in either |
| `i18n` | Files in `assets/translations/` are named `<group>.<language>.json`; the group is `common`, `errors`, `validation` or a folder in `lib/features/`; every group has a file in every language, with the same keys |
| `theme` | No `Color(0x…)` / `Color.fromARGB` / `Color.fromRGBO` in features |
| `rtl` | No `EdgeInsets.only(left/right)`, `EdgeInsets.fromLTRB`, `BorderRadius.only(topLeft…)`, `Alignment.*Left/Right`, `TextAlign.left/right` in `lib/` |
