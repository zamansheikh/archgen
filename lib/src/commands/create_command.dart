import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../generators/architecture.dart';
import '../generators/clean_architecture_generator.dart';
import '../generators/mvc_generator.dart';
import '../generators/state_management.dart';
import '../models/project_config.dart';
import '../utils/flutter_cli.dart';
import '../utils/pubspec_patcher.dart';
import '../utils/scaffold.dart';

/// `arch_gen create [name]` — scaffold a new Flutter project.
class CreateCommand extends Command<int> {
  CreateCommand(this._logger) {
    argParser
      ..addOption(
        'arch',
        abbr: 'a',
        help: 'Architecture to scaffold.',
        allowed: ['clean', 'mvc'],
        allowedHelp: {
          'clean': 'Clean Architecture (data/domain/presentation).',
          'mvc': 'Model-View-Controller.',
        },
      )
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Name of the first feature (Clean Architecture only).',
      )
      ..addOption(
        'state',
        abbr: 's',
        help: 'State management to wire up.',
        allowed: ['none', 'provider', 'riverpod', 'bloc', 'getx'],
        allowedHelp: {
          'none': 'Plain setState, no extra dependency.',
          'provider': 'ChangeNotifier + provider.',
          'riverpod': 'flutter_riverpod.',
          'bloc': 'flutter_bloc (events + states).',
          'getx': 'GetX reactive controllers.',
        },
      )
      ..addOption('org', help: 'Organization, e.g. com.example.')
      ..addFlag('l10n', help: 'Enable localization (l10n).')
      ..addFlag('theme', help: 'Add light/dark theme setup.')
      ..addFlag(
        'no-flutter-create',
        negatable: false,
        help: 'Only scaffold folders; skip running `flutter create`.',
      );
  }

  final Logger _logger;

  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Flutter project with a chosen architecture.';

  @override
  String get invocation => 'arch_gen create [name] [options]';

  bool get _interactive => stdin.hasTerminal;

  @override
  Future<int> run() async {
    final argResults = this.argResults!;

    // 1. Project name.
    var projectName = argResults.rest.isNotEmpty ? argResults.rest.first : '';
    if (projectName.isEmpty && _interactive) {
      projectName = _logger.prompt(
        '${lightCyan.wrap('?')} Project name:',
        defaultValue: 'my_app',
      );
    }
    projectName = projectName.trim();

    final nameError = _validatePackageName(projectName);
    if (nameError != null) {
      _logger.err(nameError);
      return ExitCode.usage.code;
    }

    final skipFlutterCreate = argResults.flag('no-flutter-create');
    final targetDir = Directory(p.join(Directory.current.path, projectName));
    if (targetDir.existsSync() && !skipFlutterCreate) {
      _logger.err('A directory named "$projectName" already exists here.');
      return ExitCode.cantCreate.code;
    }

    // 2. Organization.
    var org = argResults.option('org') ?? '';
    if (org.isEmpty && _interactive) {
      org = _logger.prompt(
        '${lightCyan.wrap('?')} Organization:',
        defaultValue: 'com.example',
      );
    }
    org = org.trim().isEmpty ? 'com.example' : org.trim();
    final orgError = _validateOrg(org);
    if (orgError != null) {
      _logger.err(orgError);
      return ExitCode.usage.code;
    }

    // Show the resolved full package id immediately.
    _logger.info(
      '${darkGray.wrap('Package id:')} ${lightYellow.wrap('$org.$projectName')}',
    );

    // 3. Architecture (arrow-key picker with recommended default).
    final Architecture architecture;
    final archFlag = argResults.option('arch');
    if (archFlag != null) {
      architecture = Architecture.fromId(archFlag)!;
    } else if (_interactive) {
      architecture = _logger.chooseOne<Architecture>(
        '${lightCyan.wrap('?')} Choose an architecture '
        '${darkGray.wrap('(↑/↓ to move, enter to select)')}',
        choices: Architecture.values,
        defaultValue: Architecture.clean,
        display: (a) => a.menuLabel,
      );
    } else {
      architecture = Architecture.clean;
    }

    // 4. First feature name (Clean Architecture only).
    var feature = argResults.option('feature') ?? '';
    if (architecture == Architecture.clean && feature.isEmpty && _interactive) {
      feature = _logger.prompt(
        '${lightCyan.wrap('?')} First feature name:',
        defaultValue: 'home',
      );
    }
    feature = feature.trim().isEmpty ? 'home' : feature.trim();

    // 5. State management (arrow-key picker, Riverpod recommended).
    final StateManagement stateManagement;
    final stateFlag = argResults.option('state');
    if (stateFlag != null) {
      stateManagement = StateManagement.fromId(stateFlag)!;
    } else if (_interactive) {
      stateManagement = _logger.chooseOne<StateManagement>(
        '${lightCyan.wrap('?')} Choose state management '
        '${darkGray.wrap('(↑/↓ to move, enter to select)')}',
        choices: StateManagement.values,
        defaultValue: StateManagement.riverpod,
        display: (s) => s.menuLabel,
      );
    } else {
      stateManagement = StateManagement.none;
    }

    // 6. Feature toggles: theming + localization.
    final enableTheme = _resolveToggle(
      argResults,
      'theme',
      'Add a light/dark theme setup?',
      defaultValue: true,
    );
    final enableL10n = _resolveToggle(
      argResults,
      'l10n',
      'Enable localization (multi-language / l10n)?',
      defaultValue: false,
    );

    final config = ProjectConfig(
      projectName: projectName,
      org: org,
      architecture: architecture,
      feature: feature,
      stateManagement: stateManagement,
      enableL10n: enableL10n,
      enableTheme: enableTheme,
    );

    _printSummary(config);

    // 6. flutter create (unless skipped).
    if (!skipFlutterCreate) {
      if (!await FlutterCli.isInstalled()) {
        _logger.err(
          'Flutter was not found on your PATH. Install Flutter, or re-run '
          'with --no-flutter-create to scaffold folders only.',
        );
        return ExitCode.unavailable.code;
      }

      _logger.info('${lightCyan.wrap('▸')} Running `flutter create`...\n');
      final code = await FlutterCli.create(
        projectName: projectName,
        workingDirectory: Directory.current.path,
        org: org,
      );
      if (code != 0) {
        _logger.err('`flutter create` failed (exit $code).');
        return code;
      }
      _logger.info('');
    } else {
      targetDir.createSync(recursive: true);
    }

    // 7. Scaffold the architecture (overwrites generated stubs like main.dart
    //    and test/widget_test.dart so everything is wired up and green).
    final progress = _logger.progress('Scaffolding ${architecture.label}');
    final plan = switch (architecture) {
      Architecture.clean => CleanArchitectureGenerator().build(config),
      Architecture.mvc => MvcGenerator().build(config),
    };
    final created = Scaffold(targetDir.path).apply(plan, overwrite: true);
    progress.complete('Scaffolded ${created.length} paths');

    // 8. Patch pubspec (state-management dep + l10n) and run pub get / codegen
    //    (only meaningful with a real Flutter project).
    var pubGetRan = false;
    if (!skipFlutterCreate) {
      var needsPubGet = false;

      final sm = stateManagement;
      if (sm.packageName != null) {
        needsPubGet |= PubspecPatcher.addDependency(
          targetDir.path,
          sm.packageName!,
          sm.versionConstraint!,
        );
      }
      if (enableL10n) {
        needsPubGet |= PubspecPatcher.enableL10n(targetDir.path);
      }

      if (needsPubGet) {
        final depProgress = _logger.progress(
          'Installing dependencies (flutter pub get)',
        );
        final code = await FlutterCli.pubGet(targetDir.path);
        pubGetRan = code == 0;
        if (code == 0) {
          depProgress.complete('Dependencies ready');
        } else {
          depProgress.fail('`flutter pub get` failed — run it manually');
        }
      }
    }

    _printNextSteps(config, skipPubGet: pubGetRan);
    return ExitCode.success.code;
  }

  /// Resolves a yes/no toggle: use the flag if provided, otherwise ask
  /// interactively, otherwise fall back to [defaultValue].
  bool _resolveToggle(
    ArgResults argResults,
    String flag,
    String question, {
    required bool defaultValue,
  }) {
    if (argResults.wasParsed(flag)) return argResults.flag(flag);
    if (_interactive) {
      return _logger.confirm(
        '${lightCyan.wrap('?')} $question',
        defaultValue: defaultValue,
      );
    }
    return defaultValue;
  }

  void _printSummary(ProjectConfig config) {
    String yn(bool v) => v ? lightGreen.wrap('yes')! : darkGray.wrap('no')!;
    _logger
      ..info('')
      ..info('${styleBold.wrap('Project')}       ${config.projectName}')
      ..info('${styleBold.wrap('Package id')}    ${config.packageId}')
      ..info('${styleBold.wrap('Architecture')}  ${config.architecture.label}');
    if (config.architecture == Architecture.clean) {
      _logger.info('${styleBold.wrap('Feature')}       ${config.feature}');
    }
    _logger
      ..info('${styleBold.wrap('State mgmt')}     ${config.stateManagement.label}')
      ..info('${styleBold.wrap('Theme')}         ${yn(config.enableTheme)}')
      ..info('${styleBold.wrap('Localization')}  ${yn(config.enableL10n)}')
      ..info('');
  }

  void _printNextSteps(ProjectConfig config, {required bool skipPubGet}) {
    _logger
      ..info('')
      ..success('✓ ${config.architecture.label} project '
          '"${config.projectName}" is ready!')
      ..info('')
      ..info(styleBold.wrap('Next steps:')!)
      ..info('  cd ${config.projectName}');
    if (!skipPubGet) _logger.info('  flutter pub get');
    _logger.info('  flutter run');
  }

  /// Returns an error message if [name] is not a valid Dart package name.
  String? _validatePackageName(String name) {
    if (name.isEmpty) return 'Project name cannot be empty.';
    final valid = RegExp(r'^[a-z][a-z0-9_]*$');
    if (!valid.hasMatch(name)) {
      return 'Invalid name "$name". Use lowercase letters, digits and '
          'underscores, starting with a letter (e.g. my_app).';
    }
    return null;
  }

  /// Returns an error message if [org] is not a valid reverse-domain string.
  String? _validateOrg(String org) {
    final valid = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$');
    if (!valid.hasMatch(org)) {
      return 'Invalid organization "$org". Use reverse-domain form, '
          'e.g. com.example or io.github.you.';
    }
    return null;
  }
}
