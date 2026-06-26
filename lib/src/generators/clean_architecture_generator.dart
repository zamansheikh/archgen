import '../models/project_config.dart';
import '../utils/scaffold.dart';
import '../utils/templates.dart';
import 'state_management_generator.dart';

/// Builds a Clean Architecture scaffold (feature-first with a shared core).
class CleanArchitectureGenerator {
  ScaffoldPlan build(ProjectConfig config) {
    final f = config.feature.toLowerCase();
    final pascal = _pascal(f);
    final sm = config.stateManagement;

    // Presentation layer is driven by the chosen state manager. The page lives
    // in presentation/pages and state files in presentation/<stateFolder>.
    final stateFolder = sm.stateFolder.isEmpty ? 'controllers' : sm.stateFolder;
    final presentation = buildStatePresentation(
      sm: sm,
      pageClassName: '${pascal}Page',
      pageTitle: pascal,
      importPrefix: '../$stateFolder/',
    );

    final directories = <String>[
      'lib/core/constants',
      'lib/core/errors',
      'lib/core/network',
      'lib/core/usecases',
      'lib/core/utils',
      'lib/config/routes',
      if (config.enableTheme) 'lib/config/theme',
      if (config.enableL10n) 'lib/l10n',
      'lib/features/$f/data/datasources',
      'lib/features/$f/data/models',
      'lib/features/$f/data/repositories',
      'lib/features/$f/domain/entities',
      'lib/features/$f/domain/repositories',
      'lib/features/$f/domain/usecases',
      'lib/features/$f/presentation/$stateFolder',
      'lib/features/$f/presentation/pages',
      'lib/features/$f/presentation/widgets',
      'test',
    ];

    final files = <String, String>{
      'lib/core/errors/failure.dart': '''
/// Base type for recoverable, user-facing errors in the domain layer.
abstract class Failure {
  const Failure(this.message);
  final String message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}
''',
      'lib/core/usecases/usecase.dart': '''
/// Contract every use case implements. [ResultType] is the success result,
/// [Params] is the input (use [NoParams] when none is required).
abstract class UseCase<ResultType, Params> {
  Future<ResultType> call(Params params);
}

class NoParams {
  const NoParams();
}
''',
      'lib/core/constants/app_constants.dart': '''
class AppConstants {
  AppConstants._();

  static const String appName = '${config.projectName}';
  static const Duration networkTimeout = Duration(seconds: 30);
}
''',
      'lib/config/routes/app_routes.dart': '''
import 'package:flutter/material.dart';

import '../../features/$f/presentation/pages/${f}_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String home = '/';

  static Map<String, WidgetBuilder> get routes => {
        home: (_) => const ${pascal}Page(),
      };
}
''',
      'lib/features/$f/domain/entities/${f}_entity.dart': '''
/// Pure business object for the "$f" feature — no framework imports.
class ${pascal}Entity {
  const ${pascal}Entity({required this.id, required this.title});

  final String id;
  final String title;
}
''',
      'lib/features/$f/domain/repositories/${f}_repository.dart': '''
import '../entities/${f}_entity.dart';

abstract class ${pascal}Repository {
  Future<List<${pascal}Entity>> getItems();
}
''',
      'lib/features/$f/domain/usecases/get_${f}_items.dart': '''
import '../../../../core/usecases/usecase.dart';
import '../entities/${f}_entity.dart';
import '../repositories/${f}_repository.dart';

class Get${pascal}Items extends UseCase<List<${pascal}Entity>, NoParams> {
  Get${pascal}Items(this._repository);

  final ${pascal}Repository _repository;

  @override
  Future<List<${pascal}Entity>> call(NoParams params) {
    return _repository.getItems();
  }
}
''',
      'lib/features/$f/data/models/${f}_model.dart': '''
import '../../domain/entities/${f}_entity.dart';

class ${pascal}Model extends ${pascal}Entity {
  const ${pascal}Model({required super.id, required super.title});

  factory ${pascal}Model.fromJson(Map<String, dynamic> json) {
    return ${pascal}Model(
      id: json['id'] as String,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title};
}
''',
      'lib/features/$f/data/repositories/${f}_repository_impl.dart': '''
import '../../domain/entities/${f}_entity.dart';
import '../../domain/repositories/${f}_repository.dart';
import '../datasources/${f}_remote_data_source.dart';

class ${pascal}RepositoryImpl implements ${pascal}Repository {
  ${pascal}RepositoryImpl(this._remote);

  final ${pascal}RemoteDataSource _remote;

  @override
  Future<List<${pascal}Entity>> getItems() => _remote.fetchItems();
}
''',
      'lib/features/$f/data/datasources/${f}_remote_data_source.dart': '''
import '../models/${f}_model.dart';

abstract class ${pascal}RemoteDataSource {
  Future<List<${pascal}Model>> fetchItems();
}

class ${pascal}RemoteDataSourceImpl implements ${pascal}RemoteDataSource {
  @override
  Future<List<${pascal}Model>> fetchItems() async {
    // TODO: replace with a real API call.
    return const [
      ${pascal}Model(id: '1', title: 'Hello from Clean Architecture'),
    ];
  }
}
''',
      'lib/features/$f/presentation/pages/${f}_page.dart':
          presentation.pageContent,
      for (final entry in presentation.stateFiles.entries)
        'lib/features/$f/presentation/$stateFolder/${entry.key}': entry.value,
      'lib/main.dart': buildMainDart(
        config: config,
        routesImport: 'config/routes/app_routes.dart',
        constantsImport: 'core/constants/app_constants.dart',
        themeImport: 'config/theme/app_theme.dart',
        initialRouteExpr: 'AppRoutes.home',
        routesMapExpr: 'AppRoutes.routes',
        appWidget: presentation.appWidget,
        extraPackageImports: presentation.mainExtraImports,
        runAppWrapOpen: presentation.runAppWrapOpen,
        runAppWrapClose: presentation.runAppWrapClose,
      ),
      'test/widget_test.dart': buildWidgetTest(
        config,
        extraPackageImports: presentation.testImports,
        wrapOpen: presentation.runAppWrapOpen,
        wrapClose: presentation.runAppWrapClose,
      ),
      if (config.enableTheme) 'lib/config/theme/app_theme.dart': buildAppTheme(),
      if (config.enableL10n) ...buildL10nFiles(config),
    };

    return ScaffoldPlan(directories: directories, files: files);
  }
}

String _pascal(String input) {
  return input
      .split(RegExp(r'[_\s-]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join();
}
