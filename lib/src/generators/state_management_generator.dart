import 'state_management.dart';

/// The presentation artifacts produced for a chosen [StateManagement]:
/// the home page/view content, any state-holder files, and the hints needed
/// to wire `main.dart` (app widget type, extra imports, runApp wrapper).
class StatePresentation {
  const StatePresentation({
    required this.pageContent,
    required this.stateFiles,
    this.appWidget = 'MaterialApp',
    this.mainExtraImports = const [],
    this.runAppWrapOpen = '',
    this.runAppWrapClose = '',
  });

  /// Full contents of the page/view file.
  final String pageContent;

  /// State-holder files: file name -> contents (placed in the state folder).
  final Map<String, String> stateFiles;

  final String appWidget;
  final List<String> mainExtraImports;
  final String runAppWrapOpen;
  final String runAppWrapClose;

  /// Imports the smoke test needs — only those required by the runApp wrapper
  /// (e.g. ProviderScope). The app-widget import (e.g. GetMaterialApp) isn't
  /// referenced in the test, so it's excluded to avoid unused-import warnings.
  List<String> get testImports =>
      runAppWrapOpen.isEmpty ? const [] : mainExtraImports;
}

/// Builds a small, self-contained counter example wired with [sm].
///
/// [pageClassName] / [pageTitle] keep the page compatible with the routing
/// already produced by the architecture generator. [importPrefix] is the
/// relative path (with trailing slash) from the page file to the state folder.
StatePresentation buildStatePresentation({
  required StateManagement sm,
  required String pageClassName,
  required String pageTitle,
  required String importPrefix,
}) {
  switch (sm) {
    case StateManagement.none:
      return _none(pageClassName, pageTitle);
    case StateManagement.provider:
      return _provider(pageClassName, pageTitle, importPrefix);
    case StateManagement.riverpod:
      return _riverpod(pageClassName, pageTitle, importPrefix);
    case StateManagement.bloc:
      return _bloc(pageClassName, pageTitle, importPrefix);
    case StateManagement.getx:
      return _getx(pageClassName, pageTitle, importPrefix);
  }
}

const _headline = 'Theme.of(context).textTheme.headlineMedium';

StatePresentation _none(String cls, String title) {
  return StatePresentation(
    stateFiles: const {},
    pageContent: '''
import 'package:flutter/material.dart';

class $cls extends StatefulWidget {
  const $cls({super.key});

  @override
  State<$cls> createState() => _${cls}State();
}

class _${cls}State extends State<$cls> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$title')),
      body: Center(
        child: Text('Count: \$_count', style: $_headline),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _count++),
        child: const Icon(Icons.add),
      ),
    );
  }
}
''',
  );
}

StatePresentation _provider(String cls, String title, String prefix) {
  return StatePresentation(
    stateFiles: {
      'counter_provider.dart': '''
import 'package:flutter/foundation.dart';

class CounterProvider extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}
''',
    },
    pageContent: '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '${prefix}counter_provider.dart';

class $cls extends StatelessWidget {
  const $cls({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CounterProvider(),
      child: Scaffold(
        appBar: AppBar(title: const Text('$title')),
        body: Center(
          child: Consumer<CounterProvider>(
            builder: (context, provider, _) =>
                Text('Count: \${provider.count}', style: $_headline),
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () => context.read<CounterProvider>().increment(),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
''',
  );
}

StatePresentation _riverpod(String cls, String title, String prefix) {
  return StatePresentation(
    appWidget: 'MaterialApp',
    mainExtraImports: const [
      "import 'package:flutter_riverpod/flutter_riverpod.dart';",
    ],
    runAppWrapOpen: 'ProviderScope(child: ',
    runAppWrapClose: ')',
    stateFiles: {
      'counter_provider.dart': '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

final counterProvider =
    NotifierProvider<CounterNotifier, int>(CounterNotifier.new);
''',
    },
    pageContent: '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '${prefix}counter_provider.dart';

class $cls extends ConsumerWidget {
  const $cls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('$title')),
      body: Center(
        child: Text('Count: \$count', style: $_headline),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(counterProvider.notifier).increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
''',
  );
}

StatePresentation _bloc(String cls, String title, String prefix) {
  return StatePresentation(
    stateFiles: {
      'counter_event.dart': '''
sealed class CounterEvent {}

class CounterIncremented extends CounterEvent {}
''',
      'counter_bloc.dart': '''
import 'package:flutter_bloc/flutter_bloc.dart';

import 'counter_event.dart';

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<CounterIncremented>((event, emit) => emit(state + 1));
  }
}
''',
    },
    pageContent: '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '${prefix}counter_bloc.dart';
import '${prefix}counter_event.dart';

class $cls extends StatelessWidget {
  const $cls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterBloc(),
      child: Scaffold(
        appBar: AppBar(title: const Text('$title')),
        body: Center(
          child: BlocBuilder<CounterBloc, int>(
            builder: (context, count) =>
                Text('Count: \$count', style: $_headline),
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () =>
                context.read<CounterBloc>().add(CounterIncremented()),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
''',
  );
}

StatePresentation _getx(String cls, String title, String prefix) {
  return StatePresentation(
    appWidget: 'GetMaterialApp',
    mainExtraImports: const ["import 'package:get/get.dart';"],
    stateFiles: {
      'counter_controller.dart': '''
import 'package:get/get.dart';

class CounterController extends GetxController {
  final count = 0.obs;

  void increment() => count.value++;
}
''',
    },
    pageContent: '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '${prefix}counter_controller.dart';

class $cls extends StatelessWidget {
  const $cls({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CounterController());
    return Scaffold(
      appBar: AppBar(title: const Text('$title')),
      body: Center(
        child: Obx(
          () => Text('Count: \${controller.count.value}', style: $_headline),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
''',
  );
}
