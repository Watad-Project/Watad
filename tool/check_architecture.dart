// Checks the Watad rules that the Dart analyzer cannot express.
//
// Run from the repository root:   dart run tool/check_architecture.dart
//
// CI runs it on every pull request, and a pull request that fails it is not
// merged. Each problem names its rule; the rules are explained in AGENTS.md
// and docs/APP_ARCHITECTURE.md (§18 lists them all).
// Fix the code, never this script: changing it needs a maintainer.
import 'dart:convert';
import 'dart:io';

const String _appPackage = 'package:watad/';
const String _packagesDoc = 'docs/APP_PACKAGES.md';
const String _componentsDoc = 'docs/APP_COMPONENTS.md';
const String _backendDoc = 'docs/ARCHITECTURE.md';
const String _routerFolder = 'lib/core/router';
const String _appRouterFile = 'lib/core/router/app_router.dart';
const String _namesFolder = 'lib/core/router/routes';
const String _injectionFile = 'lib/core/di/injection.dart';

const Set<String> _libTopLevel = {'main.dart', 'app.dart', 'core', 'features'};

const Set<String> _coreFolders = {
  'components',
  'config',
  'di',
  'enums',
  'error',
  'localization',
  'router',
  'supabase',
  'theme',
  'usecase',
  'utils',
};

/// Core folders that domain/ may import, so they must stay pure Dart.
const Set<String> _pureCoreFolders = {'enums', 'error', 'usecase', 'utils'};

const Set<String> _roles = {'client', 'contractor', 'admin', 'shared'};

const Map<String, Set<String>> _layerFolders = {
  'datasource': {'local', 'models', 'remote', 'repositories'},
  'domain': {'entities', 'repositories', 'usecases'},
  'presentation': {'bloc', 'pages', 'widgets'},
};

final List<RegExp> _typeDeclarations = [
  RegExp(
    r'^(?:(?:abstract|base|final|interface|sealed|mixin)\s+)*class\s+([A-Za-z_$][\w$]*)',
  ),
  RegExp(r'^enum\s+([A-Za-z_$][\w$]*)'),
  RegExp(r'^(?:base\s+)?mixin\s+(?!class\b)([A-Za-z_$][\w$]*)'),
  RegExp(r'^extension\s+type\s+(?:const\s+)?([A-Za-z_$][\w$]*)'),
  RegExp(r'^extension\s+(?!type\b)([A-Za-z_$][\w$]*)\s+on\b'),
  RegExp(r'^typedef\s+([A-Za-z_$][\w$]*)'),
];

final RegExp _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
);

final RegExp _secret = RegExp(
  r'service_role|BLOCKCHAIN_API_KEY|BLOCKCHAIN_API_URL|x-sync-secret|'
  r'blockchain_sync_secret|blockchain_sync_(?:claim|complete|snapshot)|'
  r'sb_secret_|eyJhbGciOi',
  caseSensitive: false,
);

final RegExp _supabaseUrl = RegExp(r'[a-z0-9]{20}\.supabase\.co');

final RegExp _publishableKey = RegExp(r'sb_publishable_[A-Za-z0-9_-]{8,}');

final RegExp _serviceLocator = RegExp(r'\bgetIt\b|\bGetIt\.(?:instance|I)\b');

final RegExp _colorLiteral = RegExp(
  r'\bColor\(\s*0x|\bColor\.from(?:ARGB|RGBO)\(',
);

/// `assets/translations/<group>.<language>.json`, e.g. `auth.ar.json`.
final RegExp _translationFile = RegExp(
  r'^([a-z][a-z0-9_]*)\.([a-z]{2})\.json$',
);

/// Translation groups that are not features (APP_ARCHITECTURE.md §14).
const Set<String> _translationGroups = {'common', 'errors', 'validation'};

/// A translation key: `<group>.<key>`, e.g. `common.retry`.
final RegExp _translationKey = RegExp(r'^[a-z][a-z0-9_]*(?:\.[a-z0-9_]+)+$');

/// A single-quoted string literal on one line; group 1 is its content.
final RegExp _stringLiteral = RegExp(r"'((?:[^'\\\n]|\\.)*)'");

/// `static const String loginName = 'login';` in a names file.
final RegExp _routeConstant = RegExp(
  r"static\s+const\s+String\s+(\w+)\s*=\s*'([^'\\\n]*)'\s*;",
);

/// One kebab-case path segment, or a path parameter like `:projectId`.
final RegExp _pathSegment = RegExp(
  r'^(?:[a-z0-9]+(?:-[a-z0-9]+)*|:[a-z][A-Za-z0-9]*)$',
);

/// Words that make a `double` or `num` look like money (golden rule 8).
const Set<String> _moneyWords = {
  'amount',
  'amounts',
  'balance',
  'budget',
  'cost',
  'costs',
  'fee',
  'fees',
  'price',
  'prices',
  'salary',
  'subtotal',
};

void main() {
  if (!File('pubspec.yaml').existsSync() || !Directory('lib').existsSync()) {
    stderr.writeln(
      'Run from the repository root: dart run tool/check_architecture.dart',
    );
    exitCode = 2;
    return;
  }

  final checker = _Checker()..run();
  if (checker.problems.isEmpty) {
    stdout.writeln('Architecture checks passed.');
    return;
  }
  for (final problem in checker.problems) {
    stdout
      ..writeln('x [${problem.rule}] ${problem.location}')
      ..writeln('    ${problem.message}');
  }
  stdout
    ..writeln()
    ..writeln(
      '${checker.problems.length} problem(s). The rules are in AGENTS.md and '
      'docs/APP_ARCHITECTURE.md §18. Fix the code, not the rules.',
    );
  exitCode = 1;
}

class _Problem {
  const _Problem(this.rule, this.path, this.message, [this.line]);

  final String rule;
  final String path;
  final String message;
  final int? line;

  String get location => line == null ? path : '$path:$line';
}

class _DartFile {
  _DartFile(this.path, this.content) : lines = content.split('\n');

  /// Repository-relative path with forward slashes, e.g. lib/app.dart.
  final String path;
  final String content;
  final List<String> lines;

  /// The lines without comments, so a rule never matches an example in a
  /// doc comment.
  late final List<String> codeLines = lines.map(_stripComment).toList();

  late final String code = codeLines.join('\n');

  late final bool isPart = RegExp(
    r'^part\s+of\b',
    multiLine: true,
  ).hasMatch(code);

  /// The public types declared at the top level.
  late final List<String> publicTypes = [
    for (final line in codeLines)
      for (final pattern in _typeDeclarations)
        if (pattern.firstMatch(line)?.group(1) case final name?
            when !name.startsWith('_'))
          name,
  ];

  /// The import and export URIs with their line numbers.
  late final List<({String uri, int line})> directives = [
    for (var i = 0; i < lines.length; i++)
      if (_directive.firstMatch(lines[i])?.group(1) case final uri?)
        (uri: uri, line: i + 1),
  ];
}

/// Where a path under lib/ sits in the architecture.
class _Location {
  _Location(String libPath) : segments = libPath.split('/');

  final List<String> segments;

  String get fileName => segments.last;

  /// main, app, core, features or other.
  String get area {
    if (segments.length == 2) {
      return switch (segments[1]) {
        'main.dart' => 'main',
        'app.dart' => 'app',
        _ => 'other',
      };
    }
    return switch (segments[1]) {
      'core' => 'core',
      'features' => 'features',
      _ => 'other',
    };
  }

  bool get _inFeature => area == 'features';

  String? get coreFolder =>
      area == 'core' && segments.length > 3 ? segments[2] : null;

  String? get feature => _inFeature && segments.length > 3 ? segments[2] : null;

  String? get role => _inFeature && segments.length > 4 ? segments[3] : null;

  /// datasource, domain or presentation; null for a file in the role folder.
  String? get layer => _inFeature && segments.length > 5 ? segments[4] : null;

  /// The first folder inside the layer; null for a file directly in it.
  String? get sub => _inFeature && segments.length > 6 ? segments[5] : null;

  bool get isInjectionFile =>
      _inFeature &&
      segments.length == 5 &&
      fileName.endsWith('_injection.dart');

  bool get isRoutesFile =>
      layer == 'presentation' &&
      segments.length == 6 &&
      fileName.endsWith('_routes.dart');
}

/// A role folder that has a routes list: the files that belong together.
class _RouteFolder {
  _RouteFolder(this.feature, this.role);

  final String feature;
  final String role;

  String get folder => 'lib/features/$feature/$role';

  /// e.g. client_projects_routes.dart, for both the list and the names file.
  String get fileName => '${_filePrefix(role)}${feature}_routes.dart';

  String get listPath => '$folder/presentation/$fileName';

  String get namesPath => '$_namesFolder/$fileName';

  String get pagesPath => '$folder/presentation/pages';

  String get testPath =>
      'test/features/$feature/$role/presentation/'
      '${fileName.replaceFirst('.dart', '_test.dart')}';

  /// e.g. clientProjectsRoutes.
  String get listName =>
      '${_snakeToCamel('${_filePrefix(role)}$feature')}Routes';

  /// e.g. ClientProjectsRoutes.
  String get className =>
      '${_snakeToPascal('${_filePrefix(role)}$feature')}Routes';
}

/// What the app may do with the backend, read from docs/ARCHITECTURE.md.
class _Backend {
  _Backend({
    required this.tables,
    required this.views,
    required this.writes,
    required this.rpcs,
    required this.buckets,
  });

  /// The tables of §3 the app may see (not the server-only ones).
  final Set<String> tables;

  /// The views of §7.
  final Set<String> views;

  /// The direct writes of §3a, by table.
  final Map<String, ({Set<String> insert, Set<String> update, bool delete})>
  writes;

  /// The RPCs of §6 that the app may call.
  final Set<String> rpcs;

  /// The storage buckets of §8.
  final Set<String> buckets;

  bool get isComplete =>
      tables.isNotEmpty &&
      views.isNotEmpty &&
      writes.isNotEmpty &&
      rpcs.isNotEmpty &&
      buckets.isNotEmpty;
}

class _Checker {
  final List<_Problem> problems = [];

  late final List<_DartFile> _libFiles = _dartFiles('lib');
  late final List<_DartFile> _testFiles = _dartFiles('test');

  late final Set<String> _featureFolders =
      Directory('lib/features').existsSync()
      ? _children(Directory('lib/features'))
            .whereType<Directory>()
            .map(_name)
            .toSet()
      : <String>{};

  /// The keys of every translation group, by group and language.
  final Map<String, Map<String, Set<String>>> _translations = {};

  late final _Backend _backend = _readBackend();

  void run() {
    _checkStructure();
    for (final file in _libFiles) {
      final location = _Location(file.path);
      _checkImports(file, location);
      _checkNaming(file, location);
      _checkFileName(file, location);
      _checkLayerContents(file, location);
      _checkNavigation(file, location);
      _checkDataAccess(file, location);
      _checkServiceLocator(file, location);
      _checkTheme(file);
      _checkRtl(file);
      _checkHardCodedText(file, location);
      _checkMoney(file);
      _checkPrint(file);
    }
    _checkIgnoreComments();
    if (!_backend.isComplete) {
      _add(
        'data',
        _backendDoc,
        'Could not read the tables of §3, §3a, §6, §7 and §8. This check '
            'reads them to verify every Supabase call: keep their format.',
      );
    }
    _checkRouting();
    _checkInjection();
    _checkSecrets();
    _checkPackageRegistry();
    _checkComponentRegistry();
    _checkTranslations();
    _checkTranslationKeys();
    _checkTests();
  }

  void _add(String rule, String path, String message, [int? line]) =>
      problems.add(_Problem(rule, path, message, line));

  // structure: lib/, lib/core/ and lib/features/<feature>/<role>/<layer>/.

  void _checkStructure() {
    for (final entity in _children(Directory('lib'))) {
      if (!_libTopLevel.contains(_name(entity))) {
        _add(
          'structure',
          _normalize(entity.path),
          'lib/ may only contain main.dart, app.dart, core/ and features/ '
              '(APP_ARCHITECTURE.md §4).',
        );
      }
    }
    _checkLibFolder(Directory('lib'));

    final core = Directory('lib/core');
    if (core.existsSync()) {
      for (final entity in _children(core)) {
        if (entity is! Directory || !_coreFolders.contains(_name(entity))) {
          _add(
            'structure',
            _normalize(entity.path),
            'lib/core/ may only contain these folders: '
                '${_coreFolders.join(', ')} (APP_ARCHITECTURE.md §6). '
                'A new core folder needs a maintainer.',
          );
        }
      }
    }

    final features = Directory('lib/features');
    if (!features.existsSync()) return;
    for (final feature in _children(features)) {
      final featurePath = _normalize(feature.path);
      if (feature is! Directory) {
        _add(
          'structure',
          featurePath,
          'No files directly in lib/features/. '
              'Code goes in lib/features/<feature>/<role>/.',
        );
        continue;
      }
      if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(_name(feature))) {
        _add(
          'structure',
          featurePath,
          'Feature folders are snake_case, e.g. projects or '
              'business_verification.',
        );
      }
      for (final role in _children(feature)) {
        if (role is! Directory || !_roles.contains(_name(role))) {
          _add(
            'structure',
            _normalize(role.path),
            'A feature folder may only contain the role folders client/, '
                'contractor/, admin/ and shared/ (APP_ARCHITECTURE.md §3).',
          );
          continue;
        }
        _checkRoleFolder(role, _name(feature), _name(role));
      }
    }
  }

  /// No empty folders, and nothing but Dart files, anywhere in lib/.
  void _checkLibFolder(Directory directory) {
    for (final entity in _children(directory)) {
      final path = _normalize(entity.path);
      if (entity is Directory) {
        if (_children(entity).isEmpty && path != 'lib/features') {
          _add(
            'structure',
            path,
            'Empty folder. Create a folder together with its first file, '
                'never "for later" (APP_ARCHITECTURE.md §3, §4).',
          );
        }
        _checkLibFolder(entity);
      } else if (!path.endsWith('.dart')) {
        _add(
          'structure',
          path,
          'lib/ holds only Dart files. Assets go in assets/, docs in docs/.',
        );
      }
    }
  }

  void _checkRoleFolder(Directory role, String feature, String roleName) {
    final prefix = _filePrefix(roleName);
    final injectionFile = '$prefix${feature}_injection.dart';
    final routesFile = '$prefix${feature}_routes.dart';

    for (final entity in _children(role)) {
      final name = _name(entity);
      final path = _normalize(entity.path);
      if (entity is! Directory) {
        if (name != injectionFile) {
          _add(
            'structure',
            path,
            'The only file allowed directly in $roleName/ is $injectionFile '
                '(APP_ARCHITECTURE.md §12). Other code goes in datasource/, '
                'domain/ or presentation/.',
          );
        }
        continue;
      }
      final allowed = _layerFolders[name];
      if (allowed == null) {
        _add(
          'structure',
          path,
          'A role folder may only contain datasource/, domain/ and '
              'presentation/ (APP_ARCHITECTURE.md §4).',
        );
        continue;
      }
      for (final child in _children(entity)) {
        final childName = _name(child);
        final childPath = _normalize(child.path);
        if (child is Directory) {
          if (!allowed.contains(childName)) {
            _add(
              'structure',
              childPath,
              '$name/ may only contain the folders ${allowed.join(', ')} '
                  '(APP_ARCHITECTURE.md §4).',
            );
          }
        } else if (name != 'presentation' || childName != routesFile) {
          _add(
            'structure',
            childPath,
            name == 'presentation'
                ? 'The only file allowed directly in presentation/ is '
                      '$routesFile (APP_ARCHITECTURE.md §11).'
                : 'No files directly in $name/. Use one of its folders: '
                      '${allowed.join(', ')}.',
          );
        }
      }
    }
  }

  // layers, isolation and packages: what each file may import.

  void _checkImports(_DartFile file, _Location from) {
    for (final (:uri, :line) in file.directives) {
      if (!uri.contains(':')) {
        _add(
          'layers',
          file.path,
          'Use package:watad/... imports, not relative ones ($uri).',
          line,
        );
        continue;
      }
      _checkPackageImport(file, from, uri, line);
      if (uri.startsWith(_appPackage)) {
        final to = _Location('lib/${uri.substring(_appPackage.length)}');
        _checkAppImport(file, from, to, line);
      }
    }
  }

  void _checkPackageImport(
    _DartFile file,
    _Location from,
    String uri,
    int line,
  ) {
    final package = uri.startsWith('package:')
        ? uri.substring('package:'.length).split('/').first
        : null;
    final isDartUi = uri == 'dart:ui';

    if (package == 'supabase_flutter' &&
        !(from.area == 'main' ||
            from.coreFolder == 'supabase' ||
            from.coreFolder == 'di' ||
            from.layer == 'datasource')) {
      _add(
        'packages',
        file.path,
        'supabase_flutter may only be imported in lib/main.dart, '
            'lib/core/supabase/, lib/core/di/ and datasource/. Everything else '
            'goes through a repository (APP_ARCHITECTURE.md §5).',
        line,
      );
    }
    if (package == 'get_it' &&
        !(from.coreFolder == 'di' || from.isInjectionFile)) {
      _add(
        'packages',
        file.path,
        'get_it may only be imported in lib/core/di/ and *_injection.dart '
            'files. Take dependencies through the constructor '
            '(APP_ARCHITECTURE.md §12).',
        line,
      );
    }
    if (package == 'pinput' && from.coreFolder != 'components') {
      _add(
        'packages',
        file.path,
        'pinput may only be used inside lib/core/components/. Use the '
            'AppOtpInput component (APP_COMPONENTS.md).',
        line,
      );
    }
    if (package == 'flutter_dotenv' &&
        !(from.area == 'main' || from.coreFolder == 'config')) {
      _add(
        'packages',
        file.path,
        'flutter_dotenv may only be used in lib/main.dart (to load .env) and '
            'lib/core/config/ (to read it). Everything else uses Env.',
        line,
      );
    }

    const uiPackages = {
      'flutter',
      'flutter_bloc',
      'bloc',
      'go_router',
      'easy_localization',
      'cupertino_icons',
    };
    final isPure =
        from.layer == 'domain' || _pureCoreFolders.contains(from.coreFolder);
    if (isPure && (isDartUi || uiPackages.contains(package))) {
      final where = from.layer == 'domain'
          ? 'domain/'
          : 'lib/core/${from.coreFolder}/';
      _add(
        'layers',
        file.path,
        '$where must be pure Dart: do not import $uri '
            '(APP_ARCHITECTURE.md §5).',
        line,
      );
    }
    if (from.layer == 'datasource' &&
        (isDartUi || uiPackages.contains(package))) {
      _add(
        'layers',
        file.path,
        'datasource/ must not import UI packages ($uri) '
            '(APP_ARCHITECTURE.md §5).',
        line,
      );
    }
    if (from.layer == 'presentation' &&
        from.sub == 'bloc' &&
        (isDartUi ||
            const {
              'flutter',
              'go_router',
              'easy_localization',
            }.contains(package))) {
      _add(
        'layers',
        file.path,
        'Blocs must not import $uri: no widgets, navigation or translation '
            'inside a bloc (APP_ARCHITECTURE.md §10).',
        line,
      );
    }
  }

  void _checkAppImport(_DartFile file, _Location from, _Location to, int line) {
    if (from.area == 'core') {
      _checkCoreImport(file, from, to, line);
      return;
    }
    if (from.area != 'features') return; // main.dart and app.dart wire it all.
    if (from.layer != null && !_layerFolders.containsKey(from.layer)) return;

    if (to.area == 'main' || to.area == 'app') {
      _add(
        'isolation',
        file.path,
        'Features must not import lib/main.dart or lib/app.dart.',
        line,
      );
      return;
    }

    if (to.area == 'features') {
      if (to.feature != from.feature) {
        _add(
          'isolation',
          file.path,
          'Feature "${from.feature}" must not import feature "${to.feature}". '
              'Navigate with its names file in lib/core/router/routes/, or '
              'move shared code to lib/core/ (APP_ARCHITECTURE.md §5, §11).',
          line,
        );
        return;
      }
      final roleToOwnShared = from.role != 'shared' && to.role == 'shared';
      if (to.role != from.role && !roleToOwnShared) {
        _add(
          'isolation',
          file.path,
          from.role == 'shared'
              ? 'shared/ must not import a role folder (${to.role}/).'
              : '${from.role}/ must not import ${to.role}/. Code that both '
                    "roles need goes in this feature's shared/ "
                    '(APP_ARCHITECTURE.md §3).',
          line,
        );
        return;
      }
      if (from.isInjectionFile) return; // It wires its own role folder.
      if (to.isInjectionFile) {
        _add(
          'isolation',
          file.path,
          'Only lib/core/di/ may import *_injection.dart files.',
          line,
        );
        return;
      }
      if (to.isRoutesFile) {
        _add(
          'isolation',
          file.path,
          'Only lib/core/router/app_router.dart imports a routes list. '
              'Navigate with the names file in lib/core/router/routes/ '
              '(APP_ARCHITECTURE.md §11).',
          line,
        );
        return;
      }
      final allowed = switch (from.layer) {
        'domain' => const {'domain'},
        'datasource' => const {'domain', 'datasource'},
        'presentation' => const {'domain', 'presentation'},
        _ => const <String>{},
      };
      if (!allowed.contains(to.layer)) {
        _add(
          'layers',
          file.path,
          '${from.layer}/ must not import ${to.layer}/. The direction is '
              'presentation -> domain <- datasource (APP_ARCHITECTURE.md §5).',
          line,
        );
      }
      return;
    }

    if (to.area != 'core') return;
    final core = to.coreFolder;
    if (from.layer == 'domain' && !_pureCoreFolders.contains(core)) {
      _add(
        'layers',
        file.path,
        'domain/ may only import the pure core folders '
            '(${_pureCoreFolders.join(', ')}), not lib/core/$core/.',
        line,
      );
    } else if (from.layer == 'datasource' &&
        const {
          'components',
          'di',
          'localization',
          'router',
          'theme',
        }.contains(core)) {
      _add(
        'layers',
        file.path,
        'datasource/ must not import lib/core/$core/ (UI or app wiring).',
        line,
      );
    } else if (from.layer == 'presentation' && core == 'supabase') {
      _add(
        'layers',
        file.path,
        'presentation/ must not import lib/core/supabase/. Only datasource/ '
            'talks to Supabase.',
        line,
      );
    } else if (from.layer == 'presentation' &&
        core == 'di' &&
        !from.isRoutesFile) {
      _add(
        'di',
        file.path,
        'Only the *_routes.dart file may import lib/core/di/ (to create '
            'blocs). Pages, widgets and blocs get dependencies through their '
            'constructors (APP_ARCHITECTURE.md §12).',
        line,
      );
    } else if ('lib/${to.segments.skip(1).join('/')}' == _appRouterFile) {
      _add(
        'routing',
        file.path,
        'Features never use appRouter. Navigate through the context: '
            'context.goNamed(<Feature>Routes.<page>Name) '
            '(APP_ARCHITECTURE.md §11).',
        line,
      );
    }
  }

  void _checkCoreImport(
    _DartFile file,
    _Location from,
    _Location to,
    int line,
  ) {
    if (to.area == 'features') {
      final allowed =
          (from.coreFolder == 'di' && to.isInjectionFile) ||
          (file.path == _appRouterFile && to.isRoutesFile);
      if (!allowed) {
        _add(
          'isolation',
          file.path,
          'lib/core/ must not depend on features. Only lib/core/di/ imports '
              '*_injection.dart files and only lib/core/router/app_router.dart '
              'imports *_routes.dart files (APP_ARCHITECTURE.md §5).',
          line,
        );
      }
    } else if (to.area == 'main' || to.area == 'app') {
      _add(
        'isolation',
        file.path,
        'lib/core/ must not import lib/main.dart or lib/app.dart.',
        line,
      );
    } else if (to.area == 'core' &&
        _pureCoreFolders.contains(from.coreFolder) &&
        !_pureCoreFolders.contains(to.coreFolder)) {
      _add(
        'layers',
        file.path,
        'lib/core/${from.coreFolder}/ is pure Dart and may only import the '
            'pure core folders (${_pureCoreFolders.join(', ')}).',
        line,
      );
    }
  }

  // naming: role prefixes, folder suffixes, and files named after their type.

  void _checkNaming(_DartFile file, _Location location) {
    final role = location.role;
    if (role == null || !_roles.contains(role)) return;

    final filePrefix = _filePrefix(role);
    if (role == 'shared') {
      if (RegExp('^(client|contractor|admin)_').hasMatch(location.fileName)) {
        _add(
          'naming',
          file.path,
          'Files in shared/ must not start with a role prefix '
              '(APP_ARCHITECTURE.md §7).',
        );
      }
    } else if (!location.fileName.startsWith(filePrefix)) {
      _add(
        'naming',
        file.path,
        'Files in $role/ must start with "$filePrefix", e.g. '
            '$filePrefix${location.fileName} (APP_ARCHITECTURE.md §7).',
      );
    }

    final typePrefix = _typePrefix(role);
    for (var i = 0; i < file.codeLines.length; i++) {
      for (final pattern in _typeDeclarations) {
        final name = pattern.firstMatch(file.codeLines[i])?.group(1);
        if (name == null || name.startsWith('_')) continue;
        if (role == 'shared') {
          if (RegExp('^(Client|Contractor|Admin)[A-Z]').hasMatch(name)) {
            _add(
              'naming',
              file.path,
              'Types in shared/ must not start with a role prefix: $name '
                  '(APP_ARCHITECTURE.md §7).',
              i + 1,
            );
          }
        } else if (!name.startsWith(typePrefix)) {
          _add(
            'naming',
            file.path,
            'Public types in $role/ must start with "$typePrefix": rename '
                '$name to $typePrefix$name (APP_ARCHITECTURE.md §7).',
            i + 1,
          );
        }
      }
    }
  }

  /// A file is named after its main type, with its folder's suffix.
  void _checkFileName(_DartFile file, _Location location) {
    final name = location.fileName;
    if (location.coreFolder == 'components') {
      if (!name.startsWith('app_')) {
        _add(
          'naming',
          file.path,
          'Component files are named app_<name>.dart and declare '
              'App<Name> (APP_ARCHITECTURE.md §7).',
        );
      }
      _expectTypeNamedLikeFile(file, name);
      return;
    }
    final sub = location.sub;
    if (sub == null) return;

    final suffixes = switch ((location.layer, sub)) {
      ('datasource', 'remote') => const ['_remote_data_source.dart'],
      ('datasource', 'models') => const ['_model.dart'],
      ('datasource', 'repositories') => const ['_repository_impl.dart'],
      ('domain', 'repositories') => const ['_repository.dart'],
      ('domain', 'usecases') => const ['_use_case.dart'],
      ('presentation', 'bloc') => const [
        '_bloc.dart',
        '_cubit.dart',
        '_event.dart',
        '_state.dart',
      ],
      ('presentation', 'pages') => const ['_page.dart'],
      _ => const <String>[],
    };
    if (suffixes.isNotEmpty && !suffixes.any(name.endsWith)) {
      _add(
        'naming',
        file.path,
        'Files in ${location.layer}/$sub/ end with ${suffixes.join(' or ')} '
            '(APP_ARCHITECTURE.md §7).',
      );
    }
    if (file.isPart) return;
    _expectTypeNamedLikeFile(file, name);

    if (sub == 'widgets') {
      for (final type in file.publicTypes.where((t) => t.endsWith('Widget'))) {
        _add(
          'naming',
          file.path,
          'Feature widgets have no Widget suffix: rename $type to '
              '${type.substring(0, type.length - 'Widget'.length)} '
              '(APP_ARCHITECTURE.md §7).',
        );
      }
    }
  }

  void _expectTypeNamedLikeFile(_DartFile file, String fileName) {
    final base = fileName.substring(0, fileName.length - '.dart'.length);
    if (file.publicTypes.any((type) => _squash(type) == _squash(base))) return;
    _add(
      'naming',
      file.path,
      'A file is named after its main type: $fileName must declare '
          '${_snakeToPascal(base)} (APP_ARCHITECTURE.md §7).',
    );
  }

  // layers: what each folder's files must look like (APP_ARCHITECTURE.md §8
  // to §10).

  void _checkLayerContents(_DartFile file, _Location location) {
    if (location.area != 'features') return;
    final code = file.code;
    void flag(String message, [int? line]) =>
        _add('layers', file.path, message, line);

    switch ((location.layer, location.sub)) {
      case ('domain', 'entities'):
        if (RegExp(r'\b(?:fromJson|toJson)\b|Map<String,\s*dynamic>')
            .hasMatch(code)) {
          flag(
            'Entities are plain Dart: no fromJson, toJson or '
            'Map<String, dynamic>. JSON goes in a model in datasource/models/ '
            '(APP_ARCHITECTURE.md §8).',
          );
        }
        _checkFinalFields(file);
      case ('domain', 'repositories'):
        _checkRepositoryInterface(file);
      case ('domain', 'usecases'):
        if (!RegExp(r'\bimplements\s+UseCase<').hasMatch(code)) {
          flag(
            'A use case implements UseCase<T, P> and does one action in '
            'call() (APP_ARCHITECTURE.md §8).',
          );
        }
        _checkNoTryCatch(file);
      case ('datasource', 'models'):
        final model = RegExp(
          r'^(?:\w+\s+)*class\s+(\w+)Model\s+extends\s+(\w+)\b',
          multiLine: true,
        ).firstMatch(code);
        if (model == null || model.group(1) != model.group(2)) {
          flag(
            'A model is `class <Entity>Model extends <Entity>` '
            '(APP_ARCHITECTURE.md §9).',
          );
        }
        if (!RegExp(
          r'factory\s+\w+Model\.fromJson\(\s*Map<String,\s*dynamic>\s+json\s*\)',
        ).hasMatch(code)) {
          flag(
            'A model has `factory <Entity>Model.fromJson('
            'Map<String, dynamic> json)` (APP_ARCHITECTURE.md §9).',
          );
        }
        _checkFinalFields(file);
      case ('datasource', 'remote'):
        final interface = RegExp(
          r'^abstract\s+interface\s+class\s+(\w+RemoteDataSource)\b',
          multiLine: true,
        ).firstMatch(code)?.group(1);
        if (interface == null) {
          flag(
            'A remote data source is an `abstract interface class '
            '<Prefix><Feature>RemoteDataSource` (APP_ARCHITECTURE.md §9).',
          );
        } else if (!RegExp(
          '^(?:\\w+\\s+)*class\\s+${interface}Impl\\s+implements\\s+'
          '$interface\\b',
          multiLine: true,
        ).hasMatch(code)) {
          flag(
            'Add `class ${interface}Impl implements $interface` next to the '
            'interface (APP_ARCHITECTURE.md §9).',
          );
        }
        _checkNoTryCatch(file);
      case ('datasource', 'repositories'):
        final implementation = RegExp(
          r'^(?:\w+\s+)*class\s+(\w+)Impl\s+implements\s+(\w+)\b',
          multiLine: true,
        ).firstMatch(code);
        if (implementation == null ||
            implementation.group(1) != implementation.group(2)) {
          flag(
            'A repository implementation is `class <X>RepositoryImpl '
            'implements <X>Repository` (APP_ARCHITECTURE.md §9).',
          );
        }
        var offset = code.indexOf('@override');
        while (offset != -1) {
          final next = code.indexOf('@override', offset + 1);
          final method = code.substring(offset, next == -1 ? null : next);
          if (!method.contains('guardSupabase')) {
            flag(
              'Wrap every repository call in guardSupabaseCall, so it returns '
              'a Result and never throws (APP_ARCHITECTURE.md §13).',
              _lineAt(code, offset),
            );
          }
          offset = next;
        }
        _checkNoTryCatch(file);
      case ('presentation', 'bloc'):
        _checkBlocFile(file, location);
      case ('presentation', 'pages') || ('presentation', 'widgets'):
        final provider = RegExp(r'\b(?:Multi)?BlocProvider\s*(?:<[^>]*>)?\(');
        for (final match in provider.allMatches(code)) {
          flag(
            'Pages and widgets never create a bloc: the route builder in the '
            'routes list does (APP_ARCHITECTURE.md §10, §11). '
            'BlocProvider.value is fine.',
            _lineAt(code, match.start),
          );
        }
      default:
        break;
    }
  }

  void _checkRepositoryInterface(_DartFile file) {
    final code = file.code;
    if (!RegExp(
      r'^abstract\s+interface\s+class\s+\w+Repository\b',
      multiLine: true,
    ).hasMatch(code)) {
      _add(
        'layers',
        file.path,
        'A repository in domain/ is an `abstract interface class '
            '<Prefix><Feature>Repository` (APP_ARCHITECTURE.md §8).',
      );
    }
    final method = RegExp(
      r'^  (?=\S)(?!static\b)([\w<>?, ]+?)\s+(\w+)\s*\(',
      multiLine: true,
    );
    for (final match in method.allMatches(code)) {
      final type = match.group(1)!;
      if (type.startsWith('Future<Result<') ||
          type.startsWith('Stream<Result<')) {
        continue;
      }
      _add(
        'layers',
        file.path,
        '${match.group(2)} must return Future<Result<T>> (or '
            'Stream<Result<T>> for realtime) (APP_ARCHITECTURE.md §8, §13).',
        _lineAt(code, match.start),
      );
    }
  }

  void _checkBlocFile(_DartFile file, _Location location) {
    final name = location.fileName;
    final code = file.code;
    void flag(String message, [int? line]) =>
        _add('layers', file.path, message, line);

    if (name.endsWith('_event.dart') || name.endsWith('_state.dart')) {
      if (!file.isPart) {
        flag(
          "Events and states are part files: start with `part of '<name>"
          "_bloc.dart';` (APP_ARCHITECTURE.md §10).",
        );
      }
      final declaration = RegExp(r'^((?:\w+\s+)*)class\s+(\w+)');
      for (var i = 0; i < file.codeLines.length; i++) {
        final match = declaration.firstMatch(file.codeLines[i]);
        if (match == null) continue;
        final modifiers = match.group(1)!;
        if (!modifiers.contains('sealed') && !modifiers.contains('final')) {
          flag(
            '${match.group(2)}: events and states are a sealed base class '
            'with final class subclasses (APP_ARCHITECTURE.md §10).',
            i + 1,
          );
        }
      }
      return;
    }

    if (name.endsWith('_bloc.dart')) {
      final base = name.substring(0, name.length - '_bloc.dart'.length);
      for (final part in ['${base}_event.dart', '${base}_state.dart']) {
        if (!code.contains("part '$part';")) {
          flag("A bloc declares `part '$part';` (APP_ARCHITECTURE.md §10).");
        }
      }
      if (!RegExp(r'\bextends\s+Bloc<').hasMatch(code)) {
        flag('A bloc extends Bloc<Event, State> (APP_ARCHITECTURE.md §10).');
      }
    }
    if (name.endsWith('_cubit.dart')) {
      if (!RegExp(r'\bextends\s+Cubit<').hasMatch(code)) {
        flag('A cubit extends Cubit<State> (APP_ARCHITECTURE.md §10).');
      }
      for (final (:uri, :line) in file.directives) {
        if (uri.contains('/domain/usecases/')) {
          flag(
            'A cubit holds UI-only state and never calls a use case. Use a '
            'Bloc (APP_ARCHITECTURE.md §10).',
            line,
          );
        }
      }
    }
    for (final (:uri, :line) in file.directives) {
      if (uri.contains('/domain/repositories/')) {
        flag(
          'A bloc receives use cases only, never a repository '
          '(APP_ARCHITECTURE.md §10).',
          line,
        );
      }
    }
    _checkNoTryCatch(file);
  }

  /// Entities and models are immutable.
  void _checkFinalFields(_DartFile file) {
    final field = RegExp(
      r'^  (?=\S)(?!final\b|static\b|const\b|late\s+final\b|factory\b|return\b)'
      r'(?:late\s+)?[A-Za-z_][\w<>?, .]*\s+_?[a-z]\w*\s*(?:=[^;]*)?;\s*$',
    );
    for (var i = 0; i < file.codeLines.length; i++) {
      final line = file.codeLines[i];
      if (!field.hasMatch(line) ||
          line.contains('(') ||
          line.contains('=>') ||
          RegExp(r'\b(?:get|set)\b').hasMatch(line)) {
        continue;
      }
      _add(
        'layers',
        file.path,
        'Entity and model fields are final (APP_ARCHITECTURE.md §8).',
        i + 1,
      );
    }
  }

  /// Data sources throw, repositories return Result through
  /// guardSupabaseCall, and use cases and blocs switch on the Result.
  void _checkNoTryCatch(_DartFile file) {
    final tryCatch = RegExp(
      r'\btry\s*\{|\bcatch\s*\(|\bon\s+\w+(?:<[^>]*>)?\s+catch\b',
    );
    for (var i = 0; i < file.codeLines.length; i++) {
      if (!tryCatch.hasMatch(file.codeLines[i])) continue;
      _add(
        'layers',
        file.path,
        'No try/catch here: data sources throw, repositories turn errors '
            'into Failed through guardSupabaseCall, and use cases and blocs '
            'switch on the Result (APP_ARCHITECTURE.md §13).',
        i + 1,
      );
    }
  }

  // routing: one router, one names file per role folder, navigation by name.

  /// How a file navigates.
  void _checkNavigation(_DartFile file, _Location location) {
    if (location.coreFolder == 'router') return;
    final code = file.code;
    void flag(int offset, String message) => _add(
      'routing',
      file.path,
      '$message (APP_ARCHITECTURE.md §11).',
      _lineAt(code, offset),
    );

    final navigatorPush = RegExp(
      r'\bNavigator\s*\.\s*(?:of\s*\([^)]*\)\s*\.\s*)?push\w*\s*\(',
    );
    for (final match in navigatorPush.allMatches(code)) {
      flag(
        match.start,
        'Navigate with go_router by name (context.pushNamed / goNamed), '
        'not Navigator.push',
      );
    }
    final pageRoute = RegExp(
      r'\b(?:MaterialPageRoute|CupertinoPageRoute|PageRouteBuilder)\b',
    );
    for (final match in pageRoute.allMatches(code)) {
      flag(
        match.start,
        'No ${match.group(0)}: every page is a GoRoute in its role '
        "folder's routes list",
      );
    }
    final byPath = RegExp(
      r'\b(?:context|router|GoRouter\s*\.\s*of\s*\([^)]*\))\s*\.\s*'
      r'(?:go|push|replace|pushReplacement)\s*\(',
    );
    for (final match in byPath.allMatches(code)) {
      flag(
        match.start,
        'Navigate by name: context.goNamed(<Feature>Routes.<page>Name), '
        'never by path',
      );
    }
    final byName = RegExp(r'\b(?:go|push|replace|pushReplacement)Named\s*\(');
    for (final match in byName.allMatches(code)) {
      final arguments = _arguments(code, match.end - 1);
      if (RegExp(r'''^\s*['"]''').hasMatch(arguments)) {
        flag(
          match.start,
          'Use the …Name constant from lib/core/router/routes/, not a string',
        );
      }
      if (RegExp(r'\bextra\s*:').hasMatch(arguments)) {
        flag(
          match.start,
          'Pass ids as path parameters, not objects through extra:',
        );
      }
    }
    if (location.area != 'features') return;
    for (final match in RegExp(r'\bredirect\s*:').allMatches(code)) {
      flag(
        match.start,
        'Features never add redirects: the guards live only in _guard in '
        'lib/core/router/app_router.dart',
      );
    }
    for (final match in RegExp(r'\bGoRouter\s*\(').allMatches(code)) {
      flag(
        match.start,
        'There is one GoRouter, in lib/core/router/app_router.dart',
      );
    }
  }

  /// lib/core/router/, the names files, the routes lists and the spreads in
  /// app_router.dart.
  void _checkRouting() {
    void flag(String path, String message, [int? line]) =>
        _add('routing', path, '$message (APP_ARCHITECTURE.md §11).', line);

    final router = Directory(_routerFolder);
    if (router.existsSync()) {
      for (final entity in _children(router)) {
        final name = _name(entity);
        final ok =
            (entity is File && name == 'app_router.dart') ||
            (entity is Directory && name == 'routes');
        if (!ok) {
          flag(
            _normalize(entity.path),
            'lib/core/router/ holds only app_router.dart and routes/. Route '
            'names and paths live in one names file per role folder in '
            'routes/',
          );
        }
      }
    }

    // The role folders that have a routes list, by file name.
    final folders = <String, _RouteFolder>{};
    for (final feature in _featureFolders) {
      for (final role in _roles) {
        final folder = _RouteFolder(feature, role);
        if (File(folder.listPath).existsSync()) {
          folders[folder.fileName] = folder;
        } else if (Directory(folder.pagesPath).existsSync()) {
          flag(
            folder.pagesPath,
            'These pages have no routes list. Add ${folder.listPath} with a '
            'GoRoute for each page',
          );
        }
      }
    }

    final names = Directory(_namesFolder);
    if (names.existsSync()) {
      for (final entity in _children(names)) {
        if (entity is! File || !folders.containsKey(_name(entity))) {
          flag(
            _normalize(entity.path),
            'A names file belongs to a role folder with a routes list and has '
            'its file name: lib/features/<feature>/<role>/presentation/'
            '<prefix><feature>_routes.dart',
          );
        }
      }
    }

    final routeNames = <String, String>{};
    final routePaths = <String, String>{};
    for (final folder in folders.values) {
      final constants = _checkNamesFile(folder);
      for (final MapEntry(key: constant, value: value) in constants.entries) {
        final seen = constant.endsWith('Name') ? routeNames : routePaths;
        final other = seen[value];
        if (other != null) {
          flag(
            folder.namesPath,
            '"$value" is already used by $other. Route names and paths are '
            'unique in the app',
          );
        }
        seen[value] = '${folder.className}.$constant';
      }
      _checkRoutesList(folder, constants);
      if (!File(folder.testPath).existsSync()) {
        _add(
          'tests',
          folder.listPath,
          'Missing ${folder.testPath}: open each route by name and check its '
              'path and page (APP_ARCHITECTURE.md §11, §16).',
        );
      }
    }
    _checkAppRouter(folders);
  }

  /// Checks a names file and returns its constants (name → value).
  Map<String, String> _checkNamesFile(_RouteFolder folder) {
    final path = folder.namesPath;
    void flag(String message, [int? line]) =>
        _add('routing', path, '$message (APP_ARCHITECTURE.md §11).', line);

    final file = File(path);
    if (!file.existsSync()) {
      flag(
        'Missing names file for ${folder.listPath}. Create it with '
        '`abstract final class ${folder.className}` holding a …Name and a '
        '…Path for each route',
      );
      return const {};
    }
    final dart = _DartFile(path, file.readAsStringSync());
    final code = dart.code;

    if (dart.directives.isNotEmpty || RegExp(r'^\s*part\b').hasMatch(code)) {
      flag('A names file has no imports, exports or parts');
    }
    final header = RegExp(
      'abstract\\s+final\\s+class\\s+${folder.className}\\s*\\{',
    );
    if (dart.publicTypes.length != 1 || !header.hasMatch(code)) {
      flag(
        'A names file declares exactly one type: '
        '`abstract final class ${folder.className}`',
      );
    }
    final leftover = code
        .replaceAll(_routeConstant, '')
        .replaceFirst(header, '')
        .replaceAll(RegExp(r'[\s}]'), '');
    if (leftover.isNotEmpty) {
      flag(
        'A names file holds only `static const String …Name` and `…Path` '
        'constants with a string literal value',
      );
    }

    final constants = <String, String>{};
    for (final match in _routeConstant.allMatches(code)) {
      constants[match.group(1)!] = match.group(2)!;
    }
    final prefix = folder.role == 'shared' ? '' : '${folder.role}-';
    final pathStart = folder.role == 'shared'
        ? '/${_kebab(folder.feature)}'
        : '/${folder.role}/${_kebab(folder.feature)}';

    for (final MapEntry(key: constant, value: value) in constants.entries) {
      final isName = constant.endsWith('Name');
      if (!isName && !constant.endsWith('Path')) {
        flag('$constant: constants end with Name or Path');
        continue;
      }
      final page = constant.substring(0, constant.length - 4);
      final twin = '$page${isName ? 'Path' : 'Name'}';
      if (page.isEmpty || !constants.containsKey(twin)) {
        flag('$constant has no $twin: every route has both');
      }
      if (isName) {
        final expected = '$prefix${_camelToKebab(page)}';
        if (value != expected) {
          final role = prefix.isEmpty ? '' : ', starting with the role';
          flag(
            '$constant is "$value"; route names are the kebab-case page '
            'name$role: "$expected"',
          );
        }
        final pageFile =
            '${_filePrefix(folder.role)}${_camelToSnake(page)}_page.dart';
        if (!_hasFile(folder.pagesPath, pageFile)) {
          flag(
            '$constant has no page: add $pageFile to ${folder.pagesPath}/ '
            '(the constant is the page name without the role and "Page")',
          );
        }
      } else {
        final segments = value.split('/');
        final ok =
            (value == pathStart || value.startsWith('$pathStart/')) &&
            segments.skip(1).every(_pathSegment.hasMatch);
        if (!ok) {
          flag(
            '$constant is "$value"; paths in this folder start with '
            '$pathStart and use kebab-case segments and :id parameters',
          );
        }
      }
    }
    return constants;
  }

  /// The routes list uses its names file for every GoRoute, and routes every
  /// page of its folder.
  void _checkRoutesList(_RouteFolder folder, Map<String, String> constants) {
    final path = folder.listPath;
    void flag(String message, [int? line]) =>
        _add('routing', path, '$message (APP_ARCHITECTURE.md §11).', line);

    final dart = _libFiles.firstWhere(
      (file) => file.path == path,
      orElse: () => _DartFile(path, File(path).readAsStringSync()),
    );
    final code = dart.code;

    final lists = RegExp(r'final\s+List<RouteBase>\s+(\w+)\s*=')
        .allMatches(code)
        .map((match) => match.group(1))
        .toList();
    if (lists.length != 1 || lists.single != folder.listName) {
      flag(
        'A routes list file declares one '
        '`final List<RouteBase> ${folder.listName}`',
      );
    }

    final namesImport = '${_appPackage}core/router/routes/${folder.fileName}';
    final uris = dart.directives.map((directive) => directive.uri).toSet();
    if (!uris.contains(namesImport)) {
      flag("Import its names file: '$namesImport'");
    }
    for (final (:uri, :line) in dart.directives) {
      if (uri.startsWith('${_appPackage}core/router/routes/') &&
          uri != namesImport) {
        flag('A routes list uses only its own names file', line);
      }
    }

    final cls = folder.className;
    for (final match in RegExp(r'\bGoRoute\s*\(').allMatches(code)) {
      final arguments = _arguments(code, match.end - 1);
      final line = _lineAt(code, match.start);
      final name = RegExp(r'\bname\s*:\s*([^,\n)]+)').firstMatch(arguments);
      final routePath = RegExp(r'\bpath\s*:\s*([^,\n)]+)')
          .firstMatch(arguments);
      final nameValue = name?.group(1)!.trim();
      final pathValue = routePath?.group(1)!.trim();
      final page = RegExp('^$cls\\.(\\w+)Name\$')
          .firstMatch(nameValue ?? '')
          ?.group(1);
      if (page == null) {
        flag(
          'Every GoRoute has `name: $cls.<page>Name` from its names file',
          line,
        );
      } else if (pathValue != '$cls.${page}Path') {
        flag('This GoRoute takes `path: $cls.${page}Path`', line);
      }
    }
    for (final constant in constants.keys.where((c) => c.endsWith('Name'))) {
      if (!code.contains('$cls.$constant')) {
        flag('$cls.$constant has no GoRoute in this list');
      }
    }

    final pages = Directory(folder.pagesPath);
    if (!pages.existsSync()) return;
    for (final page in pages.listSync(recursive: true).whereType<File>()) {
      final pagePath = _normalize(page.path);
      if (!pagePath.endsWith('_page.dart')) continue;
      final uri = '$_appPackage${pagePath.substring('lib/'.length)}';
      if (!uris.contains(uri)) {
        flag('A page is one route: ${_name(page)} has no GoRoute in this list');
      }
    }
  }

  /// app_router.dart spreads every routes list once, sorted by file name.
  void _checkAppRouter(Map<String, _RouteFolder> folders) {
    final file = File(_appRouterFile);
    if (!file.existsSync()) {
      if (folders.isNotEmpty) {
        _add(
          'routing',
          _appRouterFile,
          'Missing foundation file. Stop and tell a maintainer '
              '(APP_ARCHITECTURE.md §6).',
        );
      }
      return;
    }
    final dart = _DartFile(_appRouterFile, file.readAsStringSync());
    final uris = dart.directives.map((directive) => directive.uri).toSet();
    for (final folder in folders.values) {
      final uri = '$_appPackage${folder.listPath.substring('lib/'.length)}';
      if (!uris.contains(uri) ||
          !RegExp('\\.\\.\\.${folder.listName}\\b').hasMatch(dart.code)) {
        _add(
          'routing',
          _appRouterFile,
          'Spread ${folder.listName} (from ${folder.listPath}) in '
              'createAppRouter() (APP_ARCHITECTURE.md §11).',
        );
      }
    }
    final byList = {
      for (final folder in folders.values) folder.listName: folder.fileName,
    };
    final spread = [
      for (final match in RegExp(r'\.\.\.(\w+)').allMatches(dart.code))
        ?byList[match.group(1)],
    ];
    final sorted = [...spread]..sort();
    if (spread.join() != sorted.join()) {
      _add(
        'routing',
        _appRouterFile,
        'Spread the routes lists one per line, sorted by file name: '
            '${sorted.join(', ')} (APP_ARCHITECTURE.md §11).',
      );
    }
  }

  // data: what the app reads and writes, checked against docs/ARCHITECTURE.md.

  void _checkDataAccess(_DartFile file, _Location location) {
    final code = file.code;
    void flag(int offset, String message) =>
        _add('data', file.path, message, _lineAt(code, offset));

    final wiring =
        location.area == 'main' ||
        location.coreFolder == 'di' ||
        location.coreFolder == 'supabase';
    if (!wiring) {
      for (final match in RegExp(
        r'\bSupabase\s*\.\s*instance\b',
      ).allMatches(code)) {
        flag(
          match.start,
          'Take SupabaseClient through the constructor. Supabase.instance is '
          'used only in lib/main.dart and lib/core/di/ (APP_ARCHITECTURE.md '
          '§9, §12).',
        );
      }
    }
    if (location.layer != 'datasource') return;
    final backend = _backend;
    if (!backend.isComplete) return; // Reported once, in run().

    final from = RegExp(r'([\w)\]]+)\s*\.\s*from\s*\(');
    for (final match in from.allMatches(code)) {
      final receiver = match.group(1)!;
      if (RegExp('^[A-Z]').hasMatch(receiver)) continue; // List.from, …
      final open = match.end - 1;
      final close = _closingParen(code, open);
      final literal = RegExp(r"^\s*'([a-z0-9_-]+)'\s*$")
          .firstMatch(code.substring(open + 1, close))
          ?.group(1);

      if (receiver == 'storage') {
        if (literal == null || !backend.buckets.contains(literal)) {
          flag(
            match.start,
            'Use a storage bucket of ARCHITECTURE.md §8, written as a string '
            'literal.',
          );
        }
        continue;
      }
      if (literal == null) {
        flag(
          match.start,
          'Write the table or view name as a string literal, so reviewers '
          'and this check can see it (APP_ARCHITECTURE.md §9).',
        );
        continue;
      }
      final isView = backend.views.contains(literal);
      if (!isView && !backend.tables.contains(literal)) {
        flag(
          match.start,
          '"$literal" is not a table (ARCHITECTURE.md §3) or view (§7). Never '
          'guess a name; a new view needs a migration and a doc update.',
        );
        continue;
      }

      final end = code.indexOf(';', close);
      final chain = code.substring(close + 1, end == -1 ? code.length : end);
      final ops = {
        for (final op in RegExp(
          r'\.\s*(select|insert|update|upsert|delete|stream)\s*(?:<[^>]*>)?\s*\(',
        ).allMatches(chain))
          op.group(1)!: op,
      };
      final write = backend.writes[literal];

      if (ops.containsKey('delete') && !(write?.delete ?? false)) {
        flag(
          match.start,
          'The app may not delete from "$literal". Soft-delete by default '
          '(AGENTS.md golden rule 6, ARCHITECTURE.md §3a).',
        );
      }
      for (final op in const ['insert', 'upsert', 'update']) {
        final call = ops[op];
        if (call == null) continue;
        final allowed = switch (op) {
          'insert' => write?.insert,
          'update' => write?.update,
          _ => write?.insert.intersection(write.update),
        };
        if (allowed == null || allowed.isEmpty) {
          flag(
            match.start,
            'The app may not $op "$literal". Write through an RPC '
            '(ARCHITECTURE.md §3a, §6).',
          );
          continue;
        }
        final value = _arguments(chain, call.end - 1).trim();
        if (!value.startsWith('{') && !value.startsWith('[')) {
          flag(
            match.start,
            'Build the $op map by hand with the exact columns; never '
            'serialize an entity (APP_ARCHITECTURE.md §9).',
          );
          continue;
        }
        for (final key in RegExp(r"'(\w+)'\s*:").allMatches(value)) {
          final column = key.group(1)!;
          if (_columnAllowed(allowed, column)) continue;
          flag(
            match.start,
            '"$literal.$column" is not an $op column in ARCHITECTURE.md §3a. '
            'Locked columns change only through RPCs (AGENTS.md golden rule '
            '3).',
          );
        }
      }
      final reads = ops.keys.every((op) => op == 'select' || op == 'stream');
      if (reads && !ops.containsKey('stream') && !isView) {
        flag(
          match.start,
          'Read "$literal" through a v_* view (ARCHITECTURE.md §7), not the '
          'table (AGENTS.md golden rule 3).',
        );
      }
    }

    final rpc = RegExp(r'\.\s*rpc\s*(?:<[^>]*>)?\s*\(');
    for (final match in rpc.allMatches(code)) {
      final name = RegExp(r"^\s*'(\w+)'")
          .firstMatch(_arguments(code, match.end - 1))
          ?.group(1);
      if (name == null || !backend.rpcs.contains(name)) {
        flag(
          match.start,
          'Call an app RPC of ARCHITECTURE.md §6 by its name as a string '
          'literal. Server-only functions are never called from the app.',
        );
      }
    }
  }

  _Backend _readBackend() {
    final file = File(_backendDoc);
    final lines = file.existsSync() ? file.readAsLinesSync() : <String>[];
    final names = RegExp('`([a-z0-9_*-]+)[`(]');
    Set<String> namesIn(String cell) =>
        names.allMatches(cell).map((match) => match.group(1)!).toSet();

    final tables = <String>{
      for (final cells in _sectionRows(lines, '3. Tables by domain'))
        if (cells.length > 3 && !cells[3].contains('server only'))
          ...namesIn(cells[2]),
    };
    final views = <String>{
      for (final cells in _sectionRows(lines, '7. Views'))
        if (cells.length > 2)
          ...namesIn(cells[2]).where((n) => n.startsWith('v_')),
    };
    final rpcs = <String>{
      for (final cells in _sectionRows(lines, '6. RPC catalogue'))
        if (cells.length > 2 && !cells[1].contains('server'))
          ...namesIn(cells[2]),
    };
    final buckets = <String>{
      for (final cells in _sectionRows(lines, '8. Storage buckets'))
        if (cells.length > 1) ...namesIn(cells[1]),
    };
    final writes =
        <String, ({Set<String> insert, Set<String> update, bool delete})>{};
    for (final cells in _sectionRows(lines, '3a. Direct writes')) {
      if (cells.length < 5) continue;
      final table = namesIn(cells[1]);
      if (table.length != 1) continue;
      final insertCell = cells[2].trim();
      final updateCell = cells[3].trim();
      final insert = insertCell.startsWith('none')
          ? <String>{}
          : namesIn(insertCell);
      final update = updateCell.startsWith('none')
          ? <String>{}
          : updateCell.startsWith('same')
          ? {...insert, ...namesIn(updateCell)}
          : namesIn(updateCell);
      writes[table.single] = (
        insert: insert,
        update: update,
        delete: cells[4].trim().startsWith('yes'),
      );
    }
    return _Backend(
      tables: tables,
      views: views,
      writes: writes,
      rpcs: rpcs,
      buckets: buckets,
    );
  }

  // di: the service locator stays in the wiring files.

  void _checkServiceLocator(_DartFile file, _Location location) {
    final allowed =
        location.area == 'main' ||
        location.area == 'app' ||
        location.coreFolder == 'di' ||
        location.coreFolder == 'router' ||
        location.isInjectionFile ||
        location.isRoutesFile;
    if (allowed) return;
    for (var i = 0; i < file.codeLines.length; i++) {
      if (_serviceLocator.hasMatch(file.codeLines[i])) {
        _add(
          'di',
          file.path,
          'getIt may only be used in lib/core/di/, lib/core/router/, '
              '*_injection.dart and *_routes.dart files. Take dependencies '
              'through the constructor (APP_ARCHITECTURE.md §12).',
          i + 1,
        );
      }
    }
  }

  /// One injection file per role folder that has something to register,
  /// called from configureDependencies() in alphabetical order.
  void _checkInjection() {
    void flag(String path, String message, [int? line]) =>
        _add('di', path, '$message (APP_ARCHITECTURE.md §12).', line);

    final functions = <String, String>{}; // function → injection file
    for (final feature in _featureFolders) {
      for (final role in _roles) {
        final folder = 'lib/features/$feature/$role';
        if (!Directory(folder).existsSync()) continue;
        final prefix = _filePrefix(role);
        final path = '$folder/$prefix${feature}_injection.dart';
        final function =
            'register${_snakeToPascal('$prefix$feature')}Dependencies';
        final needsOne = [
          '$folder/datasource',
          '$folder/domain/usecases',
          '$folder/presentation/bloc',
        ].any((sub) => Directory(sub).existsSync());
        final file = File(path);
        if (!file.existsSync()) {
          if (needsOne) {
            flag(
              folder,
              'Missing $path with `void $function(GetIt getIt)` registering '
              "this folder's classes",
            );
          }
          continue;
        }
        functions[function] = path;
        final dart = _DartFile(path, file.readAsStringSync());
        if (!RegExp('void\\s+$function\\s*\\(\\s*GetIt\\s+getIt\\s*\\)')
            .hasMatch(dart.code)) {
          flag(path, 'Declare `void $function(GetIt getIt)`');
        }
        for (final match in RegExp(
          r'\bregister(?:Lazy)?Singleton\b',
        ).allMatches(dart.code)) {
          final open = dart.code.indexOf('(', match.end);
          if (open == -1) continue;
          if (RegExp(r'\w+(?:Bloc|Cubit)\s*\(')
              .hasMatch(_arguments(dart.code, open))) {
            flag(
              path,
              'Register blocs and cubits with registerFactory, so each '
              'BlocProvider gets a fresh one',
              _lineAt(dart.code, match.start),
            );
          }
        }
        final blocs = Directory('$folder/presentation/bloc');
        if (blocs.existsSync()) {
          for (final bloc
              in blocs.listSync(recursive: true).whereType<File>()) {
            final source = _DartFile(
              _normalize(bloc.path),
              bloc.readAsStringSync(),
            );
            for (final type in source.publicTypes.where(
              (t) => t.endsWith('Bloc') || t.endsWith('Cubit'),
            )) {
              if (!RegExp('registerFactory[^;]*\\b$type\\s*\\(')
                  .hasMatch(dart.code)) {
                flag(path, 'Register $type with registerFactory');
              }
            }
          }
        }
      }
    }
    if (functions.isEmpty) return;

    final injection = File(_injectionFile);
    if (!injection.existsSync()) {
      flag(
        _injectionFile,
        'Missing foundation file. Stop and tell a maintainer; do not create '
        'it inside a feature task (APP_ARCHITECTURE.md §6)',
      );
      return;
    }
    final code = _DartFile(_injectionFile, injection.readAsStringSync()).code;
    for (final MapEntry(key: function, value: path) in functions.entries) {
      if (!RegExp('\\b$function\\s*\\(\\s*getIt\\s*\\)').hasMatch(code)) {
        flag(_injectionFile, 'Call $function(getIt) (from $path)');
      }
    }
    final calls = [
      for (final match in RegExp(
        r'\b(register\w+Dependencies)\s*\(\s*getIt\s*\)',
      ).allMatches(code))
        match.group(1)!,
    ];
    final sorted = [...calls]..sort();
    if (calls.join() != sorted.join()) {
      flag(
        _injectionFile,
        'Call the register functions in alphabetical order: '
        '${sorted.join(', ')}',
      );
    }
  }

  // theme: no hard-coded colors in features.

  void _checkTheme(_DartFile file) {
    if (!file.path.startsWith('lib/features/')) return;
    for (var i = 0; i < file.codeLines.length; i++) {
      if (_colorLiteral.hasMatch(file.codeLines[i])) {
        _add(
          'theme',
          file.path,
          'No hard-coded colors in features. Use Theme.of(context) or the '
              'tokens in lib/core/theme/ (APP_ARCHITECTURE.md §10).',
          i + 1,
        );
      }
    }
  }

  // rtl: layouts must work in Arabic.

  void _checkRtl(_DartFile file) {
    final code = file.code;
    void flag(int offset, String message) => _add(
      'rtl',
      file.path,
      '$message (APP_ARCHITECTURE.md §14).',
      _lineAt(code, offset),
    );

    for (final match in RegExp(r'\bEdgeInsets\.only\(').allMatches(code)) {
      final arguments = _arguments(code, match.end - 1);
      if (RegExp(r'\b(?:left|right)\s*:').hasMatch(arguments)) {
        flag(
          match.start,
          'Use EdgeInsetsDirectional.only(start:, end:) instead of '
          'EdgeInsets.only(left:, right:)',
        );
      }
    }
    for (final match in RegExp(r'\bEdgeInsets\.fromLTRB\(').allMatches(code)) {
      flag(
        match.start,
        'Use EdgeInsetsDirectional.fromSTEB instead of EdgeInsets.fromLTRB',
      );
    }
    for (final match in RegExp(r'\bBorderRadius\.only\(').allMatches(code)) {
      final arguments = _arguments(code, match.end - 1);
      if (RegExp(r'\b(?:top|bottom)(?:Left|Right)\s*:').hasMatch(arguments)) {
        flag(
          match.start,
          'Use BorderRadiusDirectional.only(topStart:, ...) instead of '
          'BorderRadius.only(topLeft:, ...)',
        );
      }
    }
    final alignment = RegExp(
      r'\bAlignment\.(?:top|center|bottom)(?:Left|Right)\b',
    );
    for (final match in alignment.allMatches(code)) {
      flag(
        match.start,
        'Use AlignmentDirectional (...Start / ...End) instead of '
        '${match.group(0)}',
      );
    }
    for (final match in RegExp(
      r'\bTextAlign\.(?:left|right)\b',
    ).allMatches(code)) {
      flag(
        match.start,
        'Use TextAlign.start / TextAlign.end instead of ${match.group(0)}',
      );
    }
  }

  // i18n: no hard-coded text, and every key used exists.

  void _checkHardCodedText(_DartFile file, _Location location) {
    final code = file.code;
    void flag(int offset, String message) => _add(
      'i18n',
      file.path,
      '$message (APP_ARCHITECTURE.md §14).',
      _lineAt(code, offset),
    );

    for (final match in RegExp(r'[؀-ۿ]+').allMatches(code)) {
      flag(
        match.start,
        'Hard-coded Arabic text. Put it in assets/translations/'
        '<group>.ar.json and use its key',
      );
    }
    final ui =
        location.coreFolder == 'components' ||
        (location.area == 'features' && location.layer == 'presentation');
    if (!ui) return;
    final visible = RegExp(
      r'(?:\b(?:Text|TextSpan|Tooltip|Tab)\s*\(\s*|'
      r'\b(?:label|title|subtitle|hintText|labelText|helperText|errorText|'
      r'tooltip|semanticLabel|semanticsLabel|message|text)\s*:\s*)'
      r"'((?:[^'\\\n]|\\.)*)'",
    );
    for (final match in visible.allMatches(code)) {
      if (RegExp(r'^\s*\.\s*(?:tr|plural)\s*\(')
          .hasMatch(code.substring(match.end))) {
        continue; // A key: 'auth.login_title'.tr().
      }
      final text = match.group(1)!.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
      if (RegExp('[A-Za-z]').hasMatch(text)) {
        flag(
          match.start,
          'Hard-coded text "${match.group(1)}". Use a translation key: '
          "context.tr('<group>.<key>')",
        );
      }
    }
  }

  void _checkTranslationKeys() {
    final groups = {
      ..._translationGroups,
      ..._featureFolders,
      ..._translations.keys,
    };
    for (final file in _libFiles) {
      if (_Location(file.path).layer == 'datasource') continue;
      final code = file.code;
      for (final match in _stringLiteral.allMatches(code)) {
        final value = match.group(1)!;
        final before = code.substring(
          match.start < 40 ? 0 : match.start - 40,
          match.start,
        );
        final isTranslated =
            RegExp(r'^\s*\.\s*(?:tr|plural)\s*\(')
                .hasMatch(code.substring(match.end)) ||
            RegExp(r'\b(?:tr|plural)\s*\(\s*$').hasMatch(before);
        void flag(String message) => _add(
          'i18n',
          file.path,
          '$message (APP_ARCHITECTURE.md §14).',
          _lineAt(code, match.start),
        );

        if (!_translationKey.hasMatch(value)) {
          if (isTranslated && !value.contains(r'$')) {
            flag(
              '"$value" is not a translation key. Keys are '
              '<group>.<key>, e.g. common.retry',
            );
          }
          continue;
        }
        final group = value.split('.').first;
        if (!groups.contains(group)) {
          if (isTranslated) {
            flag(
              '"$group" is not a translation group: use common, errors, '
              'validation or a feature folder name',
            );
          }
          continue;
        }
        final byLanguage = _translations[group];
        if (byLanguage == null) {
          flag(
            '"$value" needs assets/translations/$group.ar.json and '
            '$group.en.json',
          );
          continue;
        }
        final key = value.substring(group.length + 1);
        final known = byLanguage.values.any(
          (keys) =>
              keys.contains(key) || keys.any((k) => k.startsWith('$key.')),
        );
        if (!known) {
          flag(
            'Missing translation key "$value". Add "$key" to every '
            'assets/translations/$group.<language>.json',
          );
        }
      }
    }
  }

  // money: amounts are Money, never double or num.

  void _checkMoney(_DartFile file) {
    if (file.path == 'lib/core/utils/money.dart') return;
    final numeric = RegExp(r'\b(?:double|num)\??\s+_?([a-z]\w*)');
    for (var i = 0; i < file.codeLines.length; i++) {
      for (final match in numeric.allMatches(file.codeLines[i])) {
        final name = match.group(1)!;
        if (!_camelWords(name).any(_moneyWords.contains)) continue;
        _add(
          'money',
          file.path,
          '"$name" is money: use Money (lib/core/utils/money.dart), never '
              'double or num (AGENTS.md golden rule 8).',
          i + 1,
        );
      }
    }
  }

  // hygiene: no print, and no silenced analyzer without a reason.

  void _checkPrint(_DartFile file) {
    for (var i = 0; i < file.codeLines.length; i++) {
      if (!RegExp(r'\b(?:print|debugPrint)\s*\(').hasMatch(file.codeLines[i])) {
        continue;
      }
      _add(
        'hygiene',
        file.path,
        'Never print. Log with log() from dart:developer '
            '(APP_ARCHITECTURE.md §13).',
        i + 1,
      );
    }
  }

  void _checkIgnoreComments() {
    final ignore = RegExp(r'//\s*ignore(?:_for_file)?\s*:');
    for (final file in [..._libFiles, ..._testFiles]) {
      for (var i = 0; i < file.lines.length; i++) {
        if (!ignore.hasMatch(file.lines[i])) continue;
        final above = i == 0 ? '' : file.lines[i - 1].trim();
        if (above.startsWith('//') && !ignore.hasMatch(above)) continue;
        _add(
          'hygiene',
          file.path,
          'Do not silence the analyzer. If there is truly no other way, '
              'explain why in a comment on the line above and in the PR '
              '(AGENTS.md §10).',
          i + 1,
        );
      }
    }
  }

  // secrets: server-only keys and functions never reach the app.

  void _checkSecrets() {
    for (final file in [..._libFiles, ..._testFiles]) {
      for (var i = 0; i < file.lines.length; i++) {
        final line = file.lines[i];
        final secret = _secret.firstMatch(line)?.group(0);
        if (secret != null) {
          _add(
            'secrets',
            file.path,
            'Found "$secret": a server-only secret, key or function. The app '
                'uses only the publishable (anon) key and never calls '
                'server-only functions. Remove it, even from comments '
                '(AGENTS.md, golden rules).',
            i + 1,
          );
        }
        if (file.path.startsWith('lib/') && _supabaseUrl.hasMatch(line)) {
          _add(
            'secrets',
            file.path,
            'Do not hard-code the Supabase URL. Read it through Env '
                '(lib/core/config/), which loads it from .env.',
            i + 1,
          );
        }
        if (_publishableKey.hasMatch(line)) {
          _add(
            'secrets',
            file.path,
            'Do not hard-code a key. Read it through Env (lib/core/config/), '
                'which loads it from .env.',
            i + 1,
          );
        }
      }
    }
    _checkEnvFiles();
  }

  /// .env.example holds placeholders only, and .env is never committed.
  void _checkEnvFiles() {
    const example = '.env.example';
    final exampleFile = File(example);
    if (exampleFile.existsSync()) {
      final lines = exampleFile.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (_secret.hasMatch(line.split('#').first) ||
            _supabaseUrl.hasMatch(line) ||
            _publishableKey.hasMatch(line)) {
          _add(
            'secrets',
            example,
            'Real values do not belong in $example. Keep placeholders here and '
                'the real values only in your git-ignored .env.',
            i + 1,
          );
        }
      }
    }
    try {
      final tracked = Process.runSync('git', ['ls-files', '.env']);
      if ('${tracked.stdout}'.trim().isNotEmpty) {
        _add(
          'secrets',
          '.env',
          '.env is committed. Remove it from git with "git rm --cached .env"; '
              'it must stay only on your machine.',
        );
      }
    } on ProcessException {
      // git is not installed: nothing to check.
    }
  }

  // registry: pubspec.yaml <-> APP_PACKAGES.md, components <-> APP_COMPONENTS.md.

  void _checkPackageRegistry() {
    final registered = _registeredNames(_packagesDoc, 'Registry');
    if (registered == null) {
      _add('registry', _packagesDoc, 'Missing file or "Registry" section.');
      return;
    }
    final banned = _registeredNames(_packagesDoc, 'Not allowed') ?? const {};
    final dependencies = _pubspecDependencies();
    for (final dependency in dependencies) {
      if (banned.contains(dependency)) {
        _add(
          'registry',
          'pubspec.yaml',
          '$dependency is on the "Not allowed" list in $_packagesDoc. '
              'Use the registered alternative.',
        );
      } else if (!registered.contains(dependency)) {
        _add(
          'registry',
          'pubspec.yaml',
          '$dependency is not registered. Add a row to the Registry table '
              'in $_packagesDoc in the same change.',
        );
      }
    }
    for (final name in registered.difference(dependencies)) {
      _add(
        'registry',
        _packagesDoc,
        '$name is registered but is not in pubspec.yaml. Remove its row.',
      );
    }
  }

  void _checkComponentRegistry() {
    final registered = _registeredNames(_componentsDoc, 'Registry');
    if (registered == null) {
      _add('registry', _componentsDoc, 'Missing file or "Registry" section.');
      return;
    }
    final declared = <String>{};
    final components = _libFiles.where(
      (file) => file.path.startsWith('lib/core/components/'),
    );
    for (final file in components) {
      for (var i = 0; i < file.codeLines.length; i++) {
        for (final pattern in _typeDeclarations) {
          final name = pattern.firstMatch(file.codeLines[i])?.group(1);
          if (name == null || name.startsWith('_')) continue;
          declared.add(name);
          if (!registered.contains(name)) {
            _add(
              'registry',
              file.path,
              '$name is not in $_componentsDoc. Add it to the Registry '
                  'table in the same change (APP_ARCHITECTURE.md §15).',
              i + 1,
            );
          }
        }
      }
    }
    for (final name in registered.difference(declared)) {
      _add(
        'registry',
        _componentsDoc,
        '$name is registered but does not exist in lib/core/components/. '
            'Fix or remove its row.',
      );
    }
  }

  // i18n: one file per group and language, with the same keys in every
  // language of a group.

  void _checkTranslations() {
    final directory = Directory('assets/translations');
    if (!directory.existsSync()) return;
    final languages = <String>{};

    for (final entity in _children(directory)) {
      final path = _normalize(entity.path);
      final match = entity is File
          ? _translationFile.firstMatch(_name(entity))
          : null;
      if (match == null) {
        _add(
          'i18n',
          path,
          'assets/translations/ holds only <group>.<language>.json files, '
              'e.g. auth.ar.json (APP_ARCHITECTURE.md §14).',
        );
        continue;
      }
      final group = match.group(1)!;
      final language = match.group(2)!;
      if (!_translationGroups.contains(group) &&
          !_featureFolders.contains(group)) {
        _add(
          'i18n',
          path,
          '"$group" is not a translation group. Name the file after '
              '${_translationGroups.join(', ')} or a folder in '
              'lib/features/ (APP_ARCHITECTURE.md §14).',
        );
      }
      languages.add(language);
      try {
        final decoded = jsonDecode((entity as File).readAsStringSync());
        if (decoded is Map<String, dynamic>) {
          (_translations[group] ??= {})[language] = _flattenKeys(decoded);
        } else {
          _add('i18n', path, 'A translation file must be a JSON object.');
        }
      } on FormatException catch (error) {
        _add('i18n', path, 'Invalid JSON: ${error.message}');
      }
    }

    for (final MapEntry(key: group, value: byLanguage)
        in _translations.entries) {
      final allKeys = byLanguage.values.fold<Set<String>>(
        <String>{},
        (all, keys) => all..addAll(keys),
      );
      for (final language in languages.toList()..sort()) {
        final path = 'assets/translations/$group.$language.json';
        final present = byLanguage[language];
        if (present == null) {
          _add(
            'i18n',
            path,
            'Missing file. Every group needs a file in every language '
                '(APP_ARCHITECTURE.md §14).',
          );
          continue;
        }
        for (final key in allKeys.difference(present).toList()..sort()) {
          _add(
            'i18n',
            path,
            'Missing key "$group.$key". Every key must exist in every '
                'language of its group (APP_ARCHITECTURE.md §14).',
          );
        }
      }
    }
  }

  // tests: test/ mirrors lib/, and the code that must be tested is.

  void _checkTests() {
    final libPaths = _libFiles.map((file) => file.path).toSet();
    for (final file in _testFiles) {
      if (file.path.startsWith('test/helpers/')) continue;
      if (!file.path.endsWith('_test.dart')) {
        _add(
          'tests',
          file.path,
          'Test files end with _test.dart. Shared test code goes in '
              'test/helpers/ (APP_ARCHITECTURE.md §16).',
        );
        continue;
      }
      final mirrored =
          'lib/${file.path.substring('test/'.length, file.path.length - '_test.dart'.length)}.dart';
      if (!libPaths.contains(mirrored)) {
        _add(
          'tests',
          file.path,
          'test/ mirrors lib/: this file tests $mirrored, which does not '
              'exist. Move or rename it (APP_ARCHITECTURE.md §16).',
        );
      }
      if (RegExp(r'\bSupabase\s*\.\s*initialize\s*\(').hasMatch(file.code)) {
        _add(
          'tests',
          file.path,
          'Tests never call the real Supabase project. Use hand-written '
              'fakes of the domain interfaces (APP_ARCHITECTURE.md §16).',
        );
      }
    }

    final testPaths = _testFiles.map((file) => file.path).toSet();
    for (final file in _libFiles) {
      final location = _Location(file.path);
      final what = switch (location) {
        _ when location.coreFolder == 'components' => 'component',
        _ when location.layer == 'datasource' && location.sub == 'models' =>
          'model (its fromJson, with a realistic row)',
        _
            when location.sub == 'bloc' &&
                (location.fileName.endsWith('_bloc.dart') ||
                    location.fileName.endsWith('_cubit.dart')) =>
          'bloc (its success and failure paths)',
        _ => null,
      };
      if (what == null) continue;
      final test =
          'test/${file.path.substring('lib/'.length, file.path.length - '.dart'.length)}_test.dart';
      if (!testPaths.contains(test)) {
        _add(
          'tests',
          file.path,
          'Missing $test: every $what is tested (APP_ARCHITECTURE.md §16).',
        );
      }
    }
  }
}

// Helpers.

List<_DartFile> _dartFiles(String root) {
  final directory = Directory(root);
  if (!directory.existsSync()) return const [];
  final files = <_DartFile>[];
  for (final entity in directory.listSync(recursive: true)) {
    final path = _normalize(entity.path);
    if (entity is! File || !path.endsWith('.dart')) continue;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    files.add(_DartFile(path, entity.readAsStringSync()));
  }
  return files..sort((a, b) => a.path.compareTo(b.path));
}

/// The visible entries of [directory], sorted, without .DS_Store and friends.
List<FileSystemEntity> _children(Directory directory) =>
    directory
        .listSync()
        .where((entity) => !_name(entity).startsWith('.'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

/// Whether [fileName] exists in [folder] or one of its sub-folders.
bool _hasFile(String folder, String fileName) {
  final directory = Directory(folder);
  return directory.existsSync() &&
      directory
          .listSync(recursive: true)
          .any((entity) => entity is File && _name(entity) == fileName);
}

String _normalize(String path) {
  final forward = path.replaceAll(r'\', '/');
  return forward.startsWith('./') ? forward.substring(2) : forward;
}

String _name(FileSystemEntity entity) =>
    _normalize(entity.path).split('/').last;

String _filePrefix(String role) => role == 'shared' ? '' : '${role}_';

String _typePrefix(String role) =>
    role == 'shared' ? '' : '${role[0].toUpperCase()}${role.substring(1)}';

/// client_projects → ClientProjects.
String _snakeToPascal(String snake) => snake
    .split('_')
    .where((word) => word.isNotEmpty)
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join();

/// client_projects → clientProjects.
String _snakeToCamel(String snake) {
  final pascal = _snakeToPascal(snake);
  return pascal.isEmpty
      ? pascal
      : '${pascal[0].toLowerCase()}${pascal.substring(1)}';
}

/// projectDetails → [project, details].
List<String> _camelWords(String camel) => camel
    .replaceAllMapped(RegExp('[A-Z]'), (match) => ' ${match.group(0)}')
    .trim()
    .toLowerCase()
    .split(RegExp(r'[\s_]+'));

/// projectDetails → project-details.
String _camelToKebab(String camel) => _camelWords(camel).join('-');

/// projectDetails → project_details.
String _camelToSnake(String camel) => _camelWords(camel).join('_');

/// business_verification → business-verification.
String _kebab(String snake) => snake.replaceAll('_', '-');

/// ClientProjectsBloc and client_projects_bloc both → clientprojectsbloc.
String _squash(String name) => name.replaceAll('_', '').toLowerCase();

bool _columnAllowed(Set<String> allowed, String column) =>
    allowed.contains(column) ||
    allowed.any(
      (name) =>
          name.endsWith('*') &&
          column.startsWith(name.substring(0, name.length - 1)),
    );

/// [line] without its `//` comment; `//` inside a string is kept.
String _stripComment(String line) {
  String? quote;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (quote != null) {
      if (char == r'\') {
        i++;
      } else if (char == quote) {
        quote = null;
      }
    } else if (char == "'" || char == '"') {
      quote = char;
    } else if (char == '/' && i + 1 < line.length && line[i + 1] == '/') {
      return line.substring(0, i);
    }
  }
  return line;
}

int _lineAt(String text, int offset) =>
    '\n'.allMatches(text.substring(0, offset)).length + 1;

/// The index of the parenthesis that closes the one at [open].
int _closingParen(String code, int open) {
  var depth = 0;
  for (var i = open; i < code.length; i++) {
    if (code[i] == '(') {
      depth++;
    } else if (code[i] == ')') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return code.length;
}

/// The text between the parenthesis at [open] and the one that closes it.
String _arguments(String code, int open) =>
    code.substring(open + 1, _closingParen(code, open));

/// The cells of the table rows in the `#…` section of [lines] whose heading
/// contains [heading], up to the next heading. The first cell is empty.
List<List<String>> _sectionRows(List<String> lines, String heading) {
  final start = lines.indexWhere(
    (line) => line.startsWith('#') && line.contains(heading),
  );
  if (start == -1) return const [];
  return [
    for (final line
        in lines.skip(start + 1).takeWhile((line) => !line.startsWith('#')))
      if (line.trim().startsWith('|') && !line.contains('---'))
        line.trim().split('|'),
  ];
}

Set<String> _pubspecDependencies() {
  final names = <String>{};
  final blockStart = RegExp(r'^(?:dependencies|dev_dependencies):\s*$');
  final entry = RegExp(r'^  ([a-z0-9_]+):');
  var inBlock = false;
  for (final line in File('pubspec.yaml').readAsLinesSync()) {
    if (blockStart.hasMatch(line)) {
      inBlock = true;
      continue;
    }
    if (line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('#')) {
      inBlock = false;
    }
    final name = entry.firstMatch(line)?.group(1);
    if (inBlock && name != null) names.add(name);
  }
  return names;
}

/// The `code` names in the first column of the tables in the `## ...` section
/// of [docPath] whose heading contains [heading]. Null if there is none.
Set<String>? _registeredNames(String docPath, String heading) {
  final file = File(docPath);
  if (!file.existsSync()) return null;
  final lines = file.readAsLinesSync();
  final start = lines.indexWhere(
    (line) => line.startsWith('## ') && line.contains(heading),
  );
  if (start == -1) return null;
  final names = <String>{};
  final code = RegExp(r'`([A-Za-z_][\w]*)`');
  for (final line in lines.skip(start + 1)) {
    if (line.startsWith('## ')) break;
    final cells = line.trim().split('|');
    if (!line.trim().startsWith('|') || cells.length < 3) continue;
    for (final match in code.allMatches(cells[1])) {
      names.add(match.group(1)!);
    }
  }
  return names;
}

Set<String> _flattenKeys(Map<String, dynamic> map, [String prefix = '']) {
  final keys = <String>{};
  for (final entry in map.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      keys.addAll(_flattenKeys(value, key));
    } else {
      keys.add(key);
    }
  }
  return keys;
}
