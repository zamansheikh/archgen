import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'commands/create_command.dart';
import 'utils/banner.dart';

const String _version = '0.1.0';

/// Top-level runner for the `arch_gen` executable.
class ArchGenCommandRunner extends CommandRunner<int> {
  ArchGenCommandRunner({Logger? logger})
      : _logger = logger ?? Logger(),
        super('arch_gen',
            'Scaffold a new Flutter project with a Clean Architecture or MVC structure.') {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the arch_gen version.',
    );
    addCommand(CreateCommand(_logger));
  }

  final Logger _logger;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevel = parse(args);
      if (topLevel['version'] == true) {
        _logger.info('arch_gen $_version');
        return ExitCode.success.code;
      }

      // Bare invocation (no command, no --help) → interactive main menu.
      if (topLevel.command == null && !topLevel.wasParsed('help')) {
        return _runInteractiveMenu();
      }

      if (topLevel.command?.name == 'create') {
        printBanner(_logger);
      }
      return await runCommand(topLevel) ?? ExitCode.success.code;
    } on UsageException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);
      return ExitCode.usage.code;
    }
  }

  /// Arrow-key main menu shown when `arch_gen` is run with no command.
  Future<int> _runInteractiveMenu() async {
    printBanner(_logger);

    if (!stdin.hasTerminal) {
      // No interactive TTY (piped/CI). Fall back to printing usage.
      printUsage();
      return ExitCode.success.code;
    }

    const create = 'Create a new Flutter project';
    const help = 'Show help';
    const quit = 'Exit';

    final choice = _logger.chooseOne<String>(
      '${lightCyan.wrap('?')} What would you like to do? '
      '${darkGray.wrap('(↑/↓ to move, enter to select)')}',
      choices: const [create, help, quit],
      defaultValue: create,
    );

    switch (choice) {
      case create:
        _logger.info('');
        return await runCommand(parse(['create'])) ?? ExitCode.success.code;
      case help:
        _logger.info('');
        printUsage();
        return ExitCode.success.code;
      default:
        _logger.info('Bye! 👋');
        return ExitCode.success.code;
    }
  }
}
