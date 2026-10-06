# Watad

A blockchain-based platform that connects **clients (owners)** and **contractors** and keeps a trustworthy, tamper-proof record of construction/renovation projects between them.

> Graduation Project (CS 492), Computer Science, Taibah University, Term 1 2026-2027.

## About the Project

Construction projects often suffer from disputes over scope, payments, and progress. Watad addresses this by recording the key project data (agreements, milestones, and payments) on a permissioned blockchain, so both the client and the contractor share one verified source of truth.

The mobile app is built with **Flutter** and talks only to **Supabase**. The server copies every agreed project to a custom **Hyperledger Fabric** network; the app never calls the blockchain itself.

## User Roles

- **Client (Owner):** creates projects, reviews offers and milestones, pays in stages, and follows progress.
- **Contractor:** a verified business that sends offers, proposes milestones, and posts progress updates.
- **Admin:** staff who verify businesses, handle reports, confirm bank transfers, and moderate listings.

## Key Features

- Create and manage projects between a client and a contractor
- Offers, milestone tracking, and staged payments
- Immutable records of agreed projects on Hyperledger Fabric
- In-app chat and reviews
- Marketplace (kept off-chain; no marketplace data is stored on the blockchain)
- Cross-platform Flutter app (Android / iOS), in Arabic and English

## Architecture

```
Flutter app --(publishable key + user session)--> Supabase --(blockchain-sync Edge Function)--> Fabric REST API --> Hyperledger Fabric
```

| Layer | Technology |
|-------|-----------|
| Mobile app | Flutter / Dart: BLoC, go_router, get_it, easy_localization |
| Backend | Supabase: Postgres (RLS), Auth, Storage, Edge Function |
| Blockchain | Hyperledger Fabric (custom network) behind a REST API |

The app is organized feature-first with clean architecture: `lib/features/<feature>/<role>/{datasource,domain,presentation}`. Details are in [`docs/APP_ARCHITECTURE.md`](docs/APP_ARCHITECTURE.md), and the backend is described in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Working on This Project

Every coworker and every AI agent follows [`AGENTS.md`](AGENTS.md) (Claude Code loads it through [`CLAUDE.md`](CLAUDE.md)). In short:

- Tasks come from the Linear workspace **Graduation Project Taibah** (issues `GRA-<n>`).
- One branch per feature task: `feature/gra-<n>-<feature>-<role>`, created from the latest `main`.
- Reuse components from [`docs/APP_COMPONENTS.md`](docs/APP_COMPONENTS.md), and use only packages from [`docs/APP_PACKAGES.md`](docs/APP_PACKAGES.md).
- Run the checks below, then `flutter clean`, before you push.
- Pull requests are approved and merged only by Ameer (@73azn) or Omar Mulla (@Om4rMu).

## Getting Started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) **3.47.6** (stable) with Dart 3.13.5. Check with `flutter --version`; older versions cannot resolve the dependencies.
- Android Studio or Xcode for emulators/simulators
- The Supabase URL and publishable key (ask Ameer or Omar)

### Installation

```bash
git clone git@github.com:Watad-Project/Watad.git
cd Watad
cp .env.example .env    # then fill in the two values
flutter pub get
```

### Configuration

The app reads its configuration from `.env` with [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv):

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_PUBLISHABLE_KEY=<publishable key>
```

- `.env` is git-ignored, so the keys never reach the repository. The app does not build without it.
- `.env` is bundled into the app, so it may hold only public values. Never put the secret (service role) key in it.

### Run

```bash
flutter run
```

### Checks (run before every push)

```bash
dart format .
flutter analyze --fatal-infos
flutter test
dart run tool/check_architecture.dart
flutter clean
```

CI runs the same checks on every pull request.

### Build

```bash
flutter build apk      # Android
flutter build ios      # iOS
```

## Project Structure

```
lib/
├── main.dart              # bootstrap: .env, Supabase, dependency injection
├── app.dart               # MaterialApp.router, theme, localization
├── core/                  # shared code: components, di, router, theme, errors, utils
└── features/<feature>/
    └── <role>/            # client / contractor / admin / shared
        ├── datasource/    # Supabase calls, models, repository implementations
        ├── domain/        # entities, repository interfaces, use cases
        └── presentation/  # blocs, pages, widgets, routes
docs/                      # architecture and registries
tool/check_architecture.dart
```

## Team

Computer Science students, Taibah University.

## Course

CS 492: Graduation Project 2, Taibah University, 2026-2027.
