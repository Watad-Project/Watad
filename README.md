# Watad

A blockchain-based platform that connects **clients (owners)** and **contractors** and keeps a trustworthy, tamper-proof record of construction/renovation projects between them.

> Graduation Project (CS 492), Computer Science, Taibah University, Term 1 2026-2027.

## About the Project

Construction projects often suffer from disputes over scope, payments, and progress. Watad addresses this by recording the key project data (agreements, milestones, and status updates) on a permissioned blockchain, so both the client and the contractor share one verified source of truth.

The mobile app is built with **Flutter**. It talks to a REST API that sits in front of a custom **Hyperledger Fabric** network.

## User Roles

- **Client (Owner):** creates projects, reviews milestones, and follows progress.
- **Contractor:** receives projects, submits progress updates, and tracks milestones.

## Key Features

- Create and manage projects between a client and a contractor
- Milestone and progress tracking
- Immutable project records stored on Hyperledger Fabric
- Marketplace for finding contractors (kept off-chain; no marketplace data is stored on the blockchain)
- Cross-platform Flutter app (Android / iOS)

## Architecture

```
Flutter App  <-->  REST API (backend)  <-->  Hyperledger Fabric Network
```

| Layer | Technology |
|-------|-----------|
| Mobile app | Flutter / Dart |
| Backend | Supabase |
| Blockchain | Hyperledger Fabric (custom network) |

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio or Xcode for emulators/simulators
- Access to the backend API (see configuration below)

### Installation

```bash
git clone <repository-url>
cd watad
flutter pub get
```

### Configuration

Set the backend API base URL in the app's configuration file (for example `lib/config.dart`):

```dart
const String apiBaseUrl = 'http://<your-backend-host>:<port>';
```

### Run

```bash
flutter run
```

### Build

```bash
flutter build apk      # Android
flutter build ios      # iOS
```

## Project Structure

```
lib/
├── main.dart
├── screens/      # UI screens
├── widgets/      # Reusable widgets
├── models/       # Data models
├── services/     # API calls
└── config.dart   # App configuration
```

## Team

Computer Science students, Taibah University.

## Course

CS 492: Graduation Project 2, Taibah University, 2026-2027.