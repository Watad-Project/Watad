// Checks the Watad rules that the Dart analyzer cannot express.
//
// Run from the repository root:   dart run tool/check_architecture.dart
//
// CI runs it on every pull request. Each problem names its rule; the rules are
// explained in AGENTS.md and docs/APP_ARCHITECTURE.md (§18 lists them all).
// Fix the code, never this script: changing it needs a maintainer.
import 'dart:convert';
import 'dart:io';

const String _appPackage = 'package:watad/';
const String _packagesDoc = 'docs/APP_PACKAGES.md';
const String _componentsDoc = 'docs/APP_COMPONENTS.md';

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

class _Checker {
  final List<_Problem> problems = [];

  late final List<_DartFile> _libFiles = _dartFiles('lib');
  late final List<_DartFile> _testFiles = _dartFiles('test');

  void run() {
    _checkStructure();
    for (final file in _libFiles) {
      final location = _Location(file.path);
      _checkImports(file, location);
      _checkNaming(file, location);
      _checkServiceLocator(file, location);
      _checkTheme(file);
      _checkRtl(file);
    }
    _checkSecrets();
    _checkPackageRegistry();
    _checkComponentRegistry();
    _checkTranslations();
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
    for (var i = 0; i < file.lines.length; i++) {
      final uri = _directive.firstMatch(file.lines[i])?.group(1);
      if (uri == null) continue;
      final line = i + 1;
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
              'Navigate by route name, or move shared code to lib/core/ '
              '(APP_ARCHITECTURE.md §5).',
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
          (from.coreFolder == 'router' && to.isRoutesFile);
      if (!allowed) {
        _add(
          'isolation',
          file.path,
          'lib/core/ must not depend on features. Only lib/core/di/ imports '
              '*_injection.dart files and only lib/core/router/ imports '
              '*_routes.dart files (APP_ARCHITECTURE.md §5).',
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

  // naming: role prefixes on file names and public type names.

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
    for (var i = 0; i < file.lines.length; i++) {
      for (final pattern in _typeDeclarations) {
        final name = pattern.firstMatch(file.lines[i])?.group(1);
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
    for (var i = 0; i < file.lines.length; i++) {
      if (_serviceLocator.hasMatch(_stripComment(file.lines[i]))) {
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

  // theme: no hard-coded colors in features.

  void _checkTheme(_DartFile file) {
    if (!file.path.startsWith('lib/features/')) return;
    for (var i = 0; i < file.lines.length; i++) {
      if (_colorLiteral.hasMatch(_stripComment(file.lines[i]))) {
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
    final code = file.lines.map(_stripComment).join('\n');
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
      for (var i = 0; i < file.lines.length; i++) {
        for (final pattern in _typeDeclarations) {
          final name = pattern.firstMatch(file.lines[i])?.group(1);
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

  // i18n: every translation file has the same keys.

  void _checkTranslations() {
    final directory = Directory('assets/translations');
    if (!directory.existsSync()) return;
    final keysByFile = <String, Set<String>>{};
    final files =
        _children(directory)
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final path = _normalize(file.path);
      try {
        final decoded = jsonDecode(file.readAsStringSync());
        if (decoded is Map<String, dynamic>) {
          keysByFile[path] = _flattenKeys(decoded);
        } else {
          _add('i18n', path, 'A translation file must be a JSON object.');
        }
      } on FormatException catch (error) {
        _add('i18n', path, 'Invalid JSON: ${error.message}');
      }
    }
    final allKeys = keysByFile.values.fold<Set<String>>(
      <String>{},
      (all, keys) => all..addAll(keys),
    );
    for (final entry in keysByFile.entries) {
      final missing = allKeys.difference(entry.value).toList()..sort();
      for (final key in missing) {
        _add(
          'i18n',
          entry.key,
          'Missing key "$key". Every key must exist in every file in '
              'assets/translations/ (APP_ARCHITECTURE.md §14).',
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

String _normalize(String path) {
  final forward = path.replaceAll(r'\', '/');
  return forward.startsWith('./') ? forward.substring(2) : forward;
}

String _name(FileSystemEntity entity) =>
    _normalize(entity.path).split('/').last;

String _filePrefix(String role) => role == 'shared' ? '' : '${role}_';

String _typePrefix(String role) =>
    role == 'shared' ? '' : '${role[0].toUpperCase()}${role.substring(1)}';

String _stripComment(String line) {
  final index = line.indexOf('//');
  return index == -1 ? line : line.substring(0, index);
}

int _lineAt(String text, int offset) =>
    '\n'.allMatches(text.substring(0, offset)).length + 1;

/// The text between the parenthesis at [open] and the one that closes it.
String _arguments(String code, int open) {
  var depth = 0;
  for (var i = open; i < code.length; i++) {
    if (code[i] == '(') {
      depth++;
    } else if (code[i] == ')') {
      depth--;
      if (depth == 0) return code.substring(open + 1, i);
    }
  }
  return code.substring(open + 1);
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
