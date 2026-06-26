import 'package:mason_logger/mason_logger.dart';

/// Prints the arch_gen header banner with an optional [version].
void printBanner(Logger logger, {String version = ''}) {
  final v = version.isEmpty ? '' : '   ${darkGray.wrap('v$version')}';
  logger
    ..info('')
    ..info(lightCyan.wrap('   ▄▀█ █▀█ █▀▀ █░█ ▄▄ █▀▀ █▀▀ █▄░█')!)
    ..info('${lightCyan.wrap('   █▀█ █▀▄ █▄▄ █▀█ ░░ █▄█ ██▄ █░▀█')!}$v')
    ..info(darkGray.wrap('   Rich Flutter project scaffolder  ·  clean · mvc')!)
    ..info(darkGray.wrap('   ─────────────────────────────────────────────')!)
    ..info('');
}
