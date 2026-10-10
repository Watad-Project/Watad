# CLAUDE.md

@AGENTS.md

All rules for this repository live in [AGENTS.md](AGENTS.md), imported above, so that every AI tool follows the same ones. If your tool did not load it, open it now and follow its reading order:

1. [AGENTS.md](AGENTS.md): golden rules, toolchain (Flutter 3.47.6), workflow and checks.
2. [docs/APP_ARCHITECTURE.md](docs/APP_ARCHITECTURE.md): how the Flutter app is built.
3. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): the Supabase backend and the blockchain sync.
4. [docs/APP_COMPONENTS.md](docs/APP_COMPONENTS.md) and [docs/APP_PACKAGES.md](docs/APP_PACKAGES.md): the registries.

**Run `dart run tool/check_architecture.dart` after every change, and before you say a task is done.** It enforces these rules (AGENTS.md §1 and §8, APP_ARCHITECTURE.md §18), and a pull request that fails it is rejected. Fix the code until it passes; never edit the checker or the rules to get past it.

Do not add rules here. Change AGENTS.md instead, with a maintainer's approval.
