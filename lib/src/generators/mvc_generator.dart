import '../models/project_config.dart';
import '../utils/scaffold.dart';
import '../utils/templates.dart';
import 'state_management_generator.dart';

/// Builds a classic MVC scaffold: models / views / controllers + helpers.
class MvcGenerator {
  ScaffoldPlan build(ProjectConfig config) {
    // The home view + its state holder are driven by the chosen state manager.
    // State files live in lib/controllers (the MVC-natural place).
    final presentation = buildStatePresentation(
      sm: config.stateManagement,
      pageClassName: 'HomeView',
      pageTitle: 'Home',
      importPrefix: '../../controllers/',
    );

    final directories = <String>[
      'lib/models',
      'lib/views/home',
      'lib/views/widgets',
      'lib/controllers',
      'lib/services',
      'lib/routes',
      'lib/utils',
      if (config.enableTheme) 'lib/theme',
      if (config.enableL10n) 'lib/l10n',
      'test',
    ];

    final files = <String, String>{
      'lib/utils/constants.dart': '''
class AppConstants {
  AppConstants._();

  static const String appName = '${config.projectName}';
}
''',
      'lib/models/item_model.dart': '''
class ItemModel {
  const ItemModel({required this.id, required this.title});

  final String id;
  final String title;

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title};
}
''',
      'lib/services/api_service.dart': '''
import '../models/item_model.dart';

/// Talks to your backend. Keep all I/O here, out of controllers.
class ApiService {
  Future<List<ItemModel>> fetchItems() async {
    // TODO: replace with a real API call.
    return const [
      ItemModel(id: '1', title: 'Hello from MVC'),
    ];
  }
}
''',
      'lib/views/home/home_view.dart': presentation.pageContent,
      for (final entry in presentation.stateFiles.entries)
        'lib/controllers/${entry.key}': entry.value,
      'lib/routes/app_routes.dart': '''
import 'package:flutter/material.dart';

import '../views/home/home_view.dart';

class AppRoutes {
  AppRoutes._();

  static const String home = '/';

  static Map<String, WidgetBuilder> get routes => {
        home: (_) => const HomeView(),
      };
}
''',
      'lib/main.dart': buildMainDart(
        config: config,
        routesImport: 'routes/app_routes.dart',
        constantsImport: 'utils/constants.dart',
        themeImport: 'theme/app_theme.dart',
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
      if (config.enableTheme) 'lib/theme/app_theme.dart': buildAppTheme(),
      if (config.enableL10n) ...buildL10nFiles(config),
    };

    return ScaffoldPlan(directories: directories, files: files);
  }
}
