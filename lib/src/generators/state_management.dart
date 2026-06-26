/// State-management options offered by arch_gen.
enum StateManagement {
  none(
    id: 'none',
    label: 'None',
    description: 'Plain setState — no extra dependency.',
    packageName: null,
    versionConstraint: null,
    stateFolder: '',
  ),
  provider(
    id: 'provider',
    label: 'Provider',
    description: 'ChangeNotifier + Provider. Simple and official.',
    packageName: 'provider',
    versionConstraint: '^6.1.5',
    stateFolder: 'providers',
  ),
  riverpod(
    id: 'riverpod',
    label: 'Riverpod',
    description: 'Compile-safe, testable. (Recommended)',
    packageName: 'flutter_riverpod',
    versionConstraint: '^3.3.2',
    stateFolder: 'providers',
  ),
  bloc(
    id: 'bloc',
    label: 'Bloc',
    description: 'Event-driven flutter_bloc with predictable states.',
    packageName: 'flutter_bloc',
    versionConstraint: '^9.1.1',
    stateFolder: 'bloc',
  ),
  getx(
    id: 'getx',
    label: 'GetX',
    description: 'Reactive controllers + routing in one package.',
    packageName: 'get',
    versionConstraint: '^4.7.3',
    stateFolder: 'controllers',
  );

  const StateManagement({
    required this.id,
    required this.label,
    required this.description,
    required this.packageName,
    required this.versionConstraint,
    required this.stateFolder,
  });

  final String id;
  final String label;
  final String description;

  /// Pub package to add, or null for [StateManagement.none].
  final String? packageName;
  final String? versionConstraint;

  /// Sub-folder under the presentation layer where state files are placed.
  final String stateFolder;

  String get menuLabel => '$label  —  $description';

  static StateManagement? fromId(String id) {
    for (final s in StateManagement.values) {
      if (s.id == id.toLowerCase()) return s;
    }
    return null;
  }
}
