# arch_gen

A rich, interactive command-line tool that scaffolds a new **Flutter** project
with a ready-to-use **Clean Architecture** or **MVC** folder structure.

- 🎛️ Interactive terminal UI — pick your architecture with **↑/↓ arrow keys**,
  with the recommended option preselected.
- 🏗️ Runs `flutter create` for you, then wires up the chosen architecture.
- 🧱 Two architectures today: **Clean Architecture** (feature-first) and **MVC**.
- ⚙️ Fully scriptable with flags for CI / non-interactive use.

## Install (globally)

```bash
dart pub global activate arch_gen
```

> Make sure the pub global bin is on your PATH
> (`$HOME/.pub-cache/bin`, or `%LOCALAPPDATA%\Pub\Cache\bin` on Windows).

While developing locally from this repo:

```bash
dart pub global activate --source path .
```

Installing the package gives you **three interchangeable commands** — use
whichever you like:

```bash
arch_gen   # full name
archgen    # no underscore
agen       # short alias
```

## Usage

Interactive (recommended) — just run:

```bash
arch_gen create
```

You'll be prompted for the project name and shown a selectable menu:

```
? Choose an architecture (↑/↓ to move, enter to select)
❯ Clean Architecture  —  Layered: data / domain / presentation, feature-first. (Recommended)
  MVC                 —  Models / Views / Controllers — simple and familiar.
```

### Non-interactive / scripted

```bash
# Clean Architecture with a first feature called "auth"
arch_gen create my_app --arch clean --feature auth --org com.example --theme --l10n

# MVC, no theme, no localization
arch_gen create my_app --arch mvc --no-theme --no-l10n

# Only scaffold folders, skip running flutter create
arch_gen create my_app --arch clean --no-flutter-create
```

| Flag | Description |
|------|-------------|
| `-a, --arch` | `clean` or `mvc`. Omit to choose interactively. |
| `-s, --state` | `none`, `provider`, `riverpod`, `bloc`, or `getx`. Omit to choose interactively. |
| `-f, --feature` | First feature name (Clean Architecture only). Default `home`. |
| `--org` | Organization (reverse-domain), e.g. `com.example`. |
| `--[no-]theme` | Add a light/dark theme setup. Omit to be asked. |
| `--[no-]l10n` | Enable localization (multi-language). Omit to be asked. |
| `--no-flutter-create` | Scaffold folders only; don't run `flutter create`. |
| `--version` | Print version. |

Any flag you omit is asked interactively (with a sensible default), so a bare
`arch_gen` walks you through everything: project name → organization →
architecture → feature → state management → theme → localization. The resolved
full package id (e.g. `com.example.my_app`) is shown as you go.

### State management

Pick one of **None / Provider / Riverpod / Bloc / GetX**. arch_gen adds the
matching dependency, runs `flutter pub get`, and scaffolds a small working
counter example wired with that library in the correct layer (Clean
Architecture: `presentation/bloc` · `presentation/providers` ·
`presentation/controllers`; MVC: `controllers/`). `main.dart` is wired too
(e.g. `ProviderScope` for Riverpod, `GetMaterialApp` for GetX).

When localization is enabled, arch_gen also adds `flutter_localizations` + `intl`
to `pubspec.yaml`, sets `flutter: generate: true`, creates `l10n.yaml` and ARB
files under `lib/l10n/`, and runs `flutter pub get` so the generated
`AppLocalizations` is ready. The default `test/widget_test.dart` is replaced with
a smoke test that matches the generated `main.dart`, so `flutter analyze` and
`flutter test` stay green out of the box.

## Generated structure

### Clean Architecture (feature-first)

```
lib/
├── core/                # shared: errors, usecases, network, constants, utils
├── config/              # routes, theme
├── features/
│   └── <feature>/
│       ├── data/        # datasources, models, repositories (impl)
│       ├── domain/      # entities, repositories (abstract), usecases
│       └── presentation/# controllers, pages, widgets
└── main.dart
```

### MVC

```
lib/
├── models/
├── views/
├── controllers/
├── services/
├── routes/
├── utils/
└── main.dart
```

## Roadmap

- More architectures (e.g. feature-driven + Bloc/Riverpod presets).
- `arch_gen feature <name>` to add a feature to an existing project.

## License

MIT
