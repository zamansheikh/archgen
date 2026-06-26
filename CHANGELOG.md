# Changelog

## 0.1.0

Initial release.

- Rich, interactive terminal UI: arrow-key menus with a recommended default,
  plus a main menu when running `arch_gen` with no command.
- Three interchangeable commands installed together: `arch_gen`, `archgen`, `agen`.
- Architectures: **Clean Architecture** (feature-first) and **MVC**.
- State management: **None, Provider, Riverpod, Bloc, GetX** (`-s/--state`) —
  adds the matching dependency, runs `flutter pub get`, and scaffolds a working
  example wired into `main.dart`.
- Prompts for organization and shows the full package id (e.g. `com.example.my_app`).
- Optional light/dark theme setup (`--[no-]theme`).
- Optional localization (`--[no-]l10n`): adds `flutter_localizations`/`intl`,
  `generate: true`, `l10n.yaml`, ARB files, and runs codegen.
- Replaces Flutter's default counter test with a smoke test so `flutter analyze`
  and `flutter test` pass on a freshly generated project.
