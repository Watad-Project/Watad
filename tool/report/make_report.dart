// Builds the testing results page for the graduation report (section 5.5.1,
// GRA-74), then opens it in the browser:
//
//   1. runs the tests you choose (all of them, the main parts, or the project
//      work only) and keeps every test's name, result and time;
//   2. opens the main screens 20 times each and times them
//      (tool/report/ui_render_benchmark_test.dart);
//   3. reads the database time of each action and the server response times
//      from Supabase (read only, with your personal access token);
//   4. writes build/report/index.html.
//
// Run it with tool/report/report.sh (macOS, Linux) or tool\report\report.bat
// (Windows), or: dart run tool/report/make_report.dart [options]
//
//   --all | --main | --work   which tests to run (asks when none is given)
//   --no-bench                skip the screen timing
//   --no-supabase             skip the Supabase numbers
//   --no-open                 don't open the page at the end
//
// The Supabase numbers need a personal access token, from
// https://supabase.com/dashboard/account/tokens. Set SUPABASE_ACCESS_TOKEN, or
// paste it when asked. It is used for this run only and never saved. The
// script only reads: SQL goes to the read-only endpoint.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

const String _outDir = 'build/report';
const String _benchFile = '$_outDir/bench.json';
const String _testsFile = '$_outDir/tests.json';
const String _pageFile = '$_outDir/index.html';
const String _benchTest = 'tool/report/ui_render_benchmark_test.dart';

class _Scope {
  const _Scope(this.flag, this.title, this.about, this.paths);

  final String flag;
  final String title;
  final String about;
  final List<String> paths;
}

const List<_Scope> _scopes = [
  _Scope('--all', 'All tests', 'the whole app, about 4 to 5 minutes', []),
  _Scope(
    '--main',
    'Main parts',
    'projects, tasks, payments, marketplace, chat, sign-in, blockchain and '
        'evidence',
    [
      'test/features/projects',
      'test/features/tasks',
      'test/features/payments',
      'test/features/marketplace',
      'test/features/chat',
      'test/features/auth',
      'test/features/blockchain',
      'test/features/evidence',
    ],
  ),
  _Scope(
    '--work',
    'Project work only',
    'adding tasks, progress updates, approval and rejection',
    ['test/features/projects', 'test/features/tasks'],
  ),
];

/// The tests shown in Figure 5.5.2: (group, file, part of the test's name).
const List<(String, String, String)> _workSteps = [
  (
    'Add a task (contractor)',
    'contractor_tasks_routes_test',
    'opens add-task page from schedule',
  ),
  (
    'Add a task (contractor)',
    'contractor_add_task_bloc_test',
    'submits valid task',
  ),
  (
    'Add a task (contractor)',
    'contractor_tasks_routes_test',
    'renders add-task page without overflow',
  ),
  (
    'Send a task update (contractor)',
    'contractor_task_update_page_test',
    'chooses task, switches state, attaches photo, and submits update',
  ),
  (
    'Send a task update (contractor)',
    'contractor_submit_task_update_use_case_test',
    'rejects more than 3 evidence photos',
  ),
  (
    'Send a task update (contractor)',
    'contractor_submit_task_update_use_case_test',
    'rejects marking a task done before its start date',
  ),
  (
    'Send a task update (contractor)',
    'contractor_task_update_status_page_test',
    'renders pending card and updates live',
  ),
  (
    'Approve or reject the update (client)',
    'client_projects_routes_test',
    'accepting approves the task; the status fills',
  ),
  (
    'Approve or reject the update (client)',
    'client_task_update_bloc_test',
    'accepting approves the task and reads it back',
  ),
  (
    'Approve or reject the update (client)',
    'client_projects_routes_test',
    'accepting asks first, then accepts at the amount shown',
  ),
  (
    'Approve or reject the update (client)',
    'client_projects_routes_test',
    'rejecting sends the reason as read',
  ),
  (
    'Approve or reject the update (client)',
    'client_projects_routes_test',
    'a refused rejection stays on the form',
  ),
];

/// The actions of Figure 5.5.4: (key, label, is a read).
const List<(String, String, bool)> _dbActions = [
  ('add_task', 'Add a task', false),
  ('submit_update', 'Send a task update', false),
  ('decide_update', 'Approve or reject an update', false),
  ('accept_offer', 'Accept an offer', false),
  ('send_offer', 'Send an offer', false),
  ('post_project', 'Post a project', false),
  ('bank_transfer', 'Pay by bank transfer', false),
  ('checkout', 'Marketplace checkout', false),
  ('pay_order', 'Pay an order', false),
  ('send_message', 'Send a message', false),
  ('start_chat', 'Start a chat', false),
  ('read_tasks', 'Read project tasks', true),
  ('read_projects', 'Read my projects', true),
  ('read_market', 'Browse the market', true),
];

const String _dbSql = '''
select case
  when query ilike '%insert into "public"."project_tasks"%' then 'add_task'
  when query ilike '%"submit_task_update"(%' then 'submit_update'
  when query ilike '%"decide_task_update"(%' then 'decide_update'
  when query ilike '%"accept_offer"(%' then 'accept_offer'
  when query ilike '%insert into "public"."project_offers"%' then 'send_offer'
  when query ilike '%insert into "public"."projects"%' then 'post_project'
  when query ilike '%"submit_bank_transfer"(%' then 'bank_transfer'
  when query ilike '%"checkout"(%' then 'checkout'
  when query ilike '%"simulate_order_payment"(%' then 'pay_order'
  when query ilike '%"start_chat"(%' then 'start_chat'
  when query ilike '%insert into "public"."messages"%' then 'send_message'
  when query ilike '%from "public"."v_project_tasks"%' then 'read_tasks'
  when query ilike '%from "public"."v_my_projects"%' then 'read_projects'
  when query ilike '%from "public"."v_marketplace_items"%' then 'read_market'
  end as action,
  sum(calls)::bigint as calls,
  round((sum(total_exec_time) / sum(calls))::numeric, 2)::float8 as mean_ms,
  round(max(max_exec_time)::numeric, 2)::float8 as max_ms
from extensions.pg_stat_statements
group by 1
having sum(calls) > 0
''';

const String _sinceSql =
    'select stats_reset::date::text as since '
    'from extensions.pg_stat_statements_info';

/// The requests of Figure 5.5.5: (method, path, label).
const List<(String, String, String)> _apiRequests = [
  ('POST', '/rest/v1/project_tasks', 'Add a task'),
  ('POST', '/rest/v1/rpc/submit_task_update', 'Send a task update'),
  ('POST', '/rest/v1/rpc/decide_task_update', 'Approve or reject an update'),
  ('GET', '/rest/v1/v_project_tasks', 'Read project tasks'),
  ('GET', '/rest/v1/v_my_projects', 'Read my projects'),
  ('GET', '/rest/v1/v_marketplace_items', 'Browse the market'),
  ('GET', '/rest/v1/v_chat_messages', 'Read a chat'),
  ('POST', '/rest/v1/messages', 'Send a message'),
  ('GET', '/rest/v1/v_public_profiles', 'Open a public profile'),
  ('GET', '/rest/v1/v_my_chats', 'Chats list'),
];

// Requests from the app only: supabase-dart sends a "Dart/…" user agent.
const String _appRequests = '''
source = 'edge_logs'
  and log_attributes['request.path'] like '/rest/v1/%'
  and log_attributes['request.headers.user_agent'] like 'Dart%'
''';

const String _apiSql =
    '''
select log_attributes['request.method'] as m,
  log_attributes['request.path'] as p,
  count() as n,
  quantile(0.5)(toFloat64OrZero(log_attributes['response.origin_time'])) as p50,
  quantile(0.95)(toFloat64OrZero(log_attributes['response.origin_time'])) as p95
from logs
where $_appRequests
group by m, p
order by n desc
limit 200
''';

const String _apiAllSql =
    '''
select count() as n,
  quantile(0.5)(toFloat64OrZero(log_attributes['response.origin_time'])) as p50,
  quantile(0.95)(toFloat64OrZero(log_attributes['response.origin_time'])) as p95
from logs
where $_appRequests
''';

// ---------------------------------------------------------------------------

Future<void> main(List<String> args) async {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Run this from the root of the Watad repository.');
    exitCode = 2;
    return;
  }
  Directory(_outDir).createSync(recursive: true);

  final scope = _chooseScope(args);
  final runBench = !args.contains('--no-bench');
  final token = args.contains('--no-supabase') ? null : _askToken();

  _title('1/4  Tests: ${scope.title} (${scope.about})');
  final tests = await _runTests(scope);

  _BenchResult? bench;
  if (runBench) {
    _title('2/4  Screen rendering time (9 screens, 20 runs each)');
    bench = await _runBench();
  } else {
    _title('2/4  Screen rendering time: skipped (--no-bench)');
  }

  _Supabase? supabase;
  if (token == null || token.isEmpty) {
    _title('3/4  Supabase: skipped (no access token)');
  } else {
    _title('3/4  Supabase: reading database and API response times');
    supabase = await _readSupabase(token);
  }

  _title('4/4  Writing the page');
  final machine = await _machine();
  final page = _page(scope, tests, bench, supabase, machine);
  File(_pageFile).writeAsStringSync(page);
  final path = File(_pageFile).absolute.path;
  stdout.writeln('  $path');

  if (!args.contains('--no-open')) await _open(path);
  if (tests.failed.isNotEmpty) exitCode = 1;
}

void _title(String text) => stdout.writeln('\n$text');

_Scope _chooseScope(List<String> args) {
  for (final scope in _scopes) {
    if (args.contains(scope.flag)) return scope;
  }
  if (!stdin.hasTerminal) return _scopes.first;
  stdout.writeln('Watad testing results (report section 5.5.1)\n');
  stdout.writeln('Which tests should run?');
  for (var i = 0; i < _scopes.length; i++) {
    stdout.writeln('  ${i + 1}. ${_scopes[i].title}: ${_scopes[i].about}');
  }
  stdout.write('Choose 1, 2 or 3 [1]: ');
  final answer = int.tryParse(stdin.readLineSync()?.trim() ?? '') ?? 1;
  return _scopes[(answer - 1).clamp(0, _scopes.length - 1)];
}

String? _askToken() {
  final fromEnv = Platform.environment['SUPABASE_ACCESS_TOKEN'];
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
  if (!stdin.hasTerminal) return null;
  stdout
    ..writeln(
      '\nThe Supabase numbers (figures 5.5.4 and 5.5.5) need a personal '
      'access token,',
    )
    ..writeln(
      'from https://supabase.com/dashboard/account/tokens. It is only used '
      'to read, and never saved.',
    )
    ..write('Paste it and press Enter, or press Enter to skip: ');
  _echo(false);
  final token = stdin.readLineSync()?.trim();
  _echo(true);
  stdout.writeln();
  return token;
}

void _echo(bool on) {
  try {
    stdin.echoMode = on;
  } on StdinException {
    // Not a terminal that can hide input; the token shows as typed.
  }
}

// ---------------------------------------------------------------------------
// 1. Tests

class _Test {
  const _Test(this.file, this.name, this.passed, this.ms);

  final String file;
  final String name;
  final bool passed;
  final int ms;
}

class _TestRun {
  _TestRun(this.tests, this.totalMs, this.command);

  final List<_Test> tests;
  final int totalMs;
  final String command;

  late final List<_Test> failed = [
    for (final test in tests)
      if (!test.passed) test,
  ];
  late final int files = {for (final test in tests) test.file}.length;
}

Future<_TestRun> _runTests(_Scope scope) async {
  final process = await Process.start('flutter', [
    'test',
    '--reporter',
    'json',
    ...scope.paths,
  ], runInShell: true);
  final raw = File(_testsFile).openWrite();
  final suites = <int, String>{};
  final started = <int, (String, int, int)>{};
  final tests = <_Test>[];
  var totalMs = 0;
  var passed = 0;
  var failed = 0;

  final errors = process.stderr.transform(utf8.decoder).join();
  await for (final line
      in process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
    raw.writeln(line);
    final Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on FormatException {
      continue;
    }
    if (decoded is! Map<String, dynamic>) continue;
    switch (decoded['type']) {
      case 'suite':
        final suite = decoded['suite'] as Map<String, dynamic>;
        suites[suite['id'] as int] = _relative(suite['path'] as String? ?? '');
      case 'testStart':
        final test = decoded['test'] as Map<String, dynamic>;
        started[test['id'] as int] = (
          test['name'] as String,
          test['suiteID'] as int,
          decoded['time'] as int,
        );
      case 'testDone':
        if (decoded['hidden'] == true) continue;
        final start = started[decoded['testID'] as int];
        if (start == null) continue;
        final ok = decoded['result'] == 'success';
        ok ? passed++ : failed++;
        tests.add(
          _Test(
            suites[start.$2] ?? '',
            start.$1,
            ok,
            (decoded['time'] as int) - start.$3,
          ),
        );
        // A terminal shows one line that counts up; a log gets the total.
        if (stdout.hasTerminal) {
          stdout.write('\r  $passed passed, $failed failed   ');
        }
      case 'done':
        totalMs = decoded['time'] as int? ?? 0;
    }
  }
  await raw.close();
  await process.exitCode;
  stdout.writeln(stdout.hasTerminal ? '' : '  $passed passed, $failed failed');
  if (tests.isEmpty) {
    stderr.writeln(await errors);
    throw StateError('flutter test ran no tests.');
  }
  final command = ['flutter test', ...scope.paths].join(' ');
  return _TestRun(tests, totalMs, command);
}

String _relative(String path) {
  final root = Directory.current.absolute.path.replaceAll(r'\', '/');
  var relative = path.replaceAll(r'\', '/');
  if (relative.startsWith('$root/')) {
    relative = relative.substring(root.length + 1);
  }
  return relative;
}

String _area(String file) {
  final feature = RegExp(r'^test/features/([^/]+)/').firstMatch(file);
  if (feature != null) return feature.group(1)!;
  if (file.startsWith('test/core/')) return 'core';
  return 'app';
}

// ---------------------------------------------------------------------------
// 2. Screen rendering time

class _Screen {
  const _Screen(this.name, this.first, this.full);

  final String name;
  final List<double> first;
  final List<double> full;

  /// The client home checks the user's role before its first frame, so only
  /// its full time means something.
  bool get hasFirst => name != 'Client home';
}

class _BenchResult {
  const _BenchResult(this.screens);

  final List<_Screen> screens;
}

Future<_BenchResult?> _runBench() async {
  final file = File(_benchFile);
  if (file.existsSync()) file.deleteSync();
  final result = await Process.run('flutter', [
    'test',
    _benchTest,
  ], runInShell: true);
  if (!file.existsSync()) {
    stderr
      ..writeln('  The benchmark did not run:')
      ..writeln(result.stdout)
      ..writeln(result.stderr);
    return null;
  }
  final screens = <_Screen>[];
  for (final line in file.readAsLinesSync()) {
    if (line.trim().isEmpty) continue;
    final row = jsonDecode(line) as Map<String, dynamic>;
    List<double> numbers(String key) => [
      for (final value in row[key] as List<dynamic>) (value as num).toDouble(),
    ];
    screens.add(
      _Screen(row['screen'] as String, numbers('first'), numbers('full')),
    );
  }
  stdout.writeln('  ${screens.length} screens timed');
  return _BenchResult(screens);
}

double _median(List<double> values) => _percentile(values, 0.5);

double _percentile(List<double> values, double p) {
  final sorted = [...values]..sort();
  final k = (sorted.length - 1) * p;
  final f = k.floor();
  final c = math.min(f + 1, sorted.length - 1);
  return sorted[f] + (sorted[c] - sorted[f]) * (k - f);
}

// ---------------------------------------------------------------------------
// 3. Supabase

class _DbRow {
  const _DbRow(this.label, this.read, this.calls, this.mean, this.max);

  final String label;
  final bool read;
  final int calls;
  final double mean;
  final double max;
}

class _ApiRow {
  const _ApiRow(this.label, this.name, this.count, this.p50, this.p95);

  final String label;
  final String name;
  final int count;
  final double p50;
  final double p95;
}

class _Supabase {
  _Supabase({
    required this.db,
    required this.since,
    required this.api,
    required this.apiAll,
    this.problems = const [],
  });

  final List<_DbRow> db;
  final String? since;
  final List<_ApiRow> api;
  final _ApiRow? apiAll;
  final List<String> problems;
}

String? _projectRef() {
  final fromEnv = Platform.environment['SUPABASE_PROJECT_REF'];
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
  final env = File('.env');
  if (env.existsSync()) {
    for (final line in env.readAsLinesSync()) {
      final match = RegExp(
        r'^\s*SUPABASE_URL\s*=\s*https?://([a-z0-9]+)\.supabase\.co',
      ).firstMatch(line);
      if (match != null) return match.group(1);
    }
  }
  final linked = File('supabase/.temp/project-ref');
  if (linked.existsSync()) return linked.readAsStringSync().trim();
  return null;
}

Future<Object?> _api(
  String token,
  String method,
  String path, {
  Map<String, String>? query,
  Object? body,
}) async {
  final client = HttpClient();
  try {
    final uri = Uri.https('api.supabase.com', path, query);
    final request = await client.openUrl(method, uri);
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token')
      ..set(HttpHeaders.acceptHeader, 'application/json');
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode >= 400) {
      throw HttpException('${response.statusCode} $text', uri: uri);
    }
    return text.isEmpty ? null : jsonDecode(text);
  } finally {
    client.close();
  }
}

Future<List<Map<String, dynamic>>> _sql(
  String token,
  String ref,
  String sql,
) async {
  final rows = await _api(
    token,
    'POST',
    '/v1/projects/$ref/database/query/read-only',
    body: {'query': sql},
  );
  return [
    for (final row in rows! as List<dynamic>) row as Map<String, dynamic>,
  ];
}

Future<List<Map<String, dynamic>>> _logs(
  String token,
  String ref,
  String sql,
) async {
  final end = DateTime.now().toUtc();
  final start = end.subtract(const Duration(hours: 24));
  final answer = await _api(
    token,
    'GET',
    '/v1/projects/$ref/analytics/endpoints/logs.all',
    query: {
      'sql': sql,
      'iso_timestamp_start': start.toIso8601String(),
      'iso_timestamp_end': end.toIso8601String(),
    },
  ) as Map<String, dynamic>?;
  final error = answer?['error'];
  if (error != null) throw HttpException(jsonEncode(error));
  return [
    for (final row in answer?['result'] as List<dynamic>? ?? const [])
      row as Map<String, dynamic>,
  ];
}

double _num(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s) ?? 0,
  _ => 0,
};

Future<_Supabase?> _readSupabase(String token) async {
  final ref = _projectRef();
  if (ref == null) {
    stderr.writeln('  No project: set SUPABASE_URL in .env.');
    return null;
  }
  final problems = <String>[];

  final db = <_DbRow>[];
  String? since;
  try {
    final rows = {
      for (final row in await _sql(token, ref, _dbSql))
        row['action'] as String?: row,
    };
    for (final (key, label, read) in _dbActions) {
      final row = rows[key];
      if (row == null) continue;
      db.add(
        _DbRow(
          label,
          read,
          _num(row['calls']).round(),
          _num(row['mean_ms']),
          _num(row['max_ms']),
        ),
      );
    }
    final sinceRows = await _sql(token, ref, _sinceSql);
    if (sinceRows.isNotEmpty) since = sinceRows.first['since'] as String?;
    stdout.writeln('  database: ${db.length} actions');
  } on Exception catch (error) {
    problems.add('Database statistics could not be read: $error');
    stderr.writeln('  ${problems.last}');
  }

  final api = <_ApiRow>[];
  _ApiRow? apiAll;
  try {
    final rows = {
      for (final row in await _logs(token, ref, _apiSql))
        '${row['m']} ${row['p']}': row,
    };
    for (final (method, path, label) in _apiRequests) {
      final row = rows['$method $path'];
      if (row == null) continue;
      final name = method == 'GET'
          ? path.split('/').last
          : '$method ${path.replaceFirst('/rest/v1/', '')}';
      api.add(
        _ApiRow(
          label,
          name,
          _num(row['n']).round(),
          _num(row['p50']),
          _num(row['p95']),
        ),
      );
    }
    final all = await _logs(token, ref, _apiAllSql);
    if (all.isNotEmpty && _num(all.first['n']) > 0) {
      apiAll = _ApiRow(
        'All app requests',
        '',
        _num(all.first['n']).round(),
        _num(all.first['p50']),
        _num(all.first['p95']),
      );
    }
    stdout.writeln('  API: ${api.length} request types');
  } on Exception catch (error) {
    problems.add('API logs could not be read: $error');
    stderr.writeln('  ${problems.last}');
  }

  return _Supabase(
    db: db,
    since: since,
    api: api,
    apiAll: apiAll,
    problems: problems,
  );
}

// ---------------------------------------------------------------------------
// The machine, for the captions

Future<String> _machine() async {
  final parts = <String>[];
  try {
    final result = await Process.run('flutter', [
      '--version',
      '--machine',
    ], runInShell: true);
    final text = result.stdout as String;
    final json =
        jsonDecode(text.substring(text.indexOf('{'))) as Map<String, dynamic>;
    parts.add(
      'Flutter ${json['frameworkVersion']}, Dart '
      '${(json['dartSdkVersion'] as String).split(' ').first}',
    );
  } on Object {
    // Leave the version out.
  }
  String? cpu;
  String os = Platform.operatingSystem;
  try {
    if (Platform.isMacOS) {
      cpu = (await Process.run('sysctl', [
        '-n',
        'machdep.cpu.brand_string',
      ])).stdout.toString().trim();
      final version = (await Process.run('sw_vers', [
        '-productVersion',
      ])).stdout.toString().trim();
      os = 'macOS $version';
    } else if (Platform.isWindows) {
      cpu = Platform.environment['PROCESSOR_IDENTIFIER'];
      os = 'Windows';
    } else if (Platform.isLinux) {
      final info = File('/proc/cpuinfo').readAsLinesSync();
      cpu = info
          .firstWhere((l) => l.startsWith('model name'), orElse: () => '')
          .split(':')
          .last
          .trim();
      os = 'Linux';
    }
  } on Object {
    // Leave the processor out.
  }
  return [if (cpu != null && cpu.isNotEmpty) cpu, os, ...parts].join(', ');
}

Future<void> _open(String path) async {
  try {
    if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', path]);
    } else {
      await Process.run('xdg-open', [path]);
    }
  } on Object {
    // Opening is a convenience; the path is printed above.
  }
}

// ---------------------------------------------------------------------------
// 4. The page

const HtmlEscape _escape = HtmlEscape();
String _e(String text) => _escape.convert(text);

String _ms(double? value, [int digits = 1]) =>
    value == null ? '—' : '${value.toStringAsFixed(digits)} ms';

String _thousands(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

const List<String> _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _date(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

String _bars(
  List<(String, double, String)> items,
  double maxValue, {
  double? mark,
  String markLabel = '',
}) {
  const width = 760.0;
  const labelWidth = 230.0;
  const barWidth = width - labelWidth - 120;
  const rowHeight = 30.0;
  final height = rowHeight * items.length + (mark != null ? 34 : 12);
  final out = StringBuffer(
    '<svg viewBox="0 0 $width $height" width="100%" role="img" '
    'class="chart">',
  );
  for (var i = 0; i < items.length; i++) {
    final (label, value, sub) = items[i];
    final y = i * rowHeight + 6;
    final length = math.max(2, barWidth * value / maxValue);
    out
      ..write(
        '<text x="${labelWidth - 10}" y="${y + 16}" text-anchor="end" '
        'class="bl">${_e(label)}</text>',
      )
      ..write(
        '<rect x="$labelWidth" y="${y + 4}" '
        'width="${length.toStringAsFixed(1)}" height="18" rx="3" '
        'class="bar"/>',
      )
      ..write(
        '<text x="${(labelWidth + length + 6).toStringAsFixed(1)}" '
        'y="${y + 17}" class="bv">${value.toStringAsFixed(0)} ms'
        '${sub.isEmpty ? '' : ', ${_e(sub)}'}</text>',
      );
  }
  if (mark != null) {
    final x = (labelWidth + barWidth * mark / maxValue).toStringAsFixed(1);
    out
      ..write('<line x1="$x" y1="2" x2="$x" y2="${height - 24}" class="mark"/>')
      ..write(
        '<text x="${double.parse(x) + 4}" y="${height - 8}" '
        'class="ml">${_e(markLabel)}</text>',
      );
  }
  out.write('</svg>');
  return out.toString();
}

String _table(List<String> head, List<List<String>> body) {
  final out = StringBuffer('<table><thead><tr>');
  for (final cell in head) {
    out.write('<th>${_e(cell)}</th>');
  }
  out.write('</tr></thead><tbody>');
  for (final row in body) {
    out.write('<tr>');
    for (final cell in row) {
      out.write('<td>$cell</td>');
    }
    out.write('</tr>');
  }
  out.write('</tbody></table>');
  return out.toString();
}

const String _dots =
    '<div class="dots"><i style="background:#ff5f57"></i>'
    '<i style="background:#febc2e"></i>'
    '<i style="background:#28c840"></i></div>';

String _duration(int ms) {
  final seconds = (ms / 1000).round();
  return '${seconds ~/ 60} min ${seconds % 60} s';
}

String _clock(int ms) {
  final seconds = (ms / 1000).round();
  return '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';
}

String _summaryTerminal(_TestRun run) {
  final passed = run.tests.length - run.failed.length;
  final areas = <String, int>{};
  for (final test in run.tests) {
    areas.update(_area(test.file), (n) => n + 1, ifAbsent: () => 1);
  }
  final sorted = areas.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final lines = <String>[
    '<span class="pr">\$</span> ${_e(run.command)}',
    '',
    '<span class="dim">00:00 +0: loading ${run.files} test files…</span>',
    '<span class="dim">…</span>',
    if (run.failed.isEmpty)
      '<span class="ok">${_clock(run.totalMs)} +$passed: '
          'All tests passed!</span>'
    else
      '<span class="bad">${_clock(run.totalMs)} +$passed '
          '-${run.failed.length}: Some tests failed.</span>',
    '',
    '<span class="grp">Tests per part of the app</span>',
  ];
  for (final entry in sorted.take(14)) {
    lines.add(
      '  ${entry.key.padRight(22)} '
      '<span class="ok">${entry.value.toString().padLeft(4)} tests</span>',
    );
  }
  final rest = sorted.skip(14).fold<int>(0, (sum, e) => sum + e.value);
  if (rest > 0) {
    lines.add(
      '  ${'other'.padRight(22)} '
      '<span class="ok">${rest.toString().padLeft(4)} tests</span>',
    );
  }
  if (run.failed.isNotEmpty) {
    lines
      ..add('')
      ..add('<span class="bad">Failed</span>');
    for (final test in run.failed.take(20)) {
      lines.add(
        '  <span class="bad">✗</span> ${_e(test.name)} '
        '<span class="dim">${_e(test.file)}</span>',
      );
    }
  }
  lines
    ..add('')
    ..add(
      '  Total: <b>$passed passed</b>, ${run.failed.length} failed, in '
      '${run.files} test files (${_duration(run.totalMs)})',
    );
  return lines.join('\n');
}

List<(String, List<_Test>)> _workStepTests(_TestRun run) {
  final groups = <String, List<_Test>>{};
  for (final (group, file, name) in _workSteps) {
    final match = run.tests.where(
      (t) => t.file.contains(file) && t.name.contains(name),
    );
    if (match.isEmpty) continue;
    (groups[group] ??= []).add(match.first);
  }
  return [for (final entry in groups.entries) (entry.key, entry.value)];
}

String _workTerminal(List<(String, List<_Test>)> groups) {
  final lines = <String>[
    '<span class="pr">\$</span> flutter test test/features/tasks '
        'test/features/projects/client',
    '',
  ];
  var count = 0;
  var allPassed = true;
  for (final (group, tests) in groups) {
    lines.add('<span class="grp">${_e(group)}</span>');
    for (final test in tests) {
      count++;
      allPassed &= test.passed;
      final mark = test.passed
          ? '<span class="ok">✓</span>'
          : '<span class="bad">✗</span>';
      lines
        ..add(
          '  $mark ${_e(test.name)} '
          '<span class="dim">(${test.ms} ms)</span>',
        )
        ..add('      <span class="dim">${_e(test.file)}</span>');
    }
    lines.add('');
  }
  lines.add(
    allPassed
        ? '<span class="ok">$count tests shown, all passed.</span>'
        : '<span class="bad">$count tests shown, some failed.</span>',
  );
  return lines.join('\n');
}

String _page(
  _Scope scope,
  _TestRun run,
  _BenchResult? bench,
  _Supabase? supabase,
  String machine,
) {
  final passed = run.tests.length - run.failed.length;
  final today = _date(DateTime.now());
  final scopeText = scope.paths.isEmpty
      ? 'The whole test suite of the Flutter app'
      : '${scope.title} of the Flutter app (${scope.about})';

  // Figure 5.5.2
  final work = _workStepTests(run);

  // Figure 5.5.3
  final screens = [...?bench?.screens]
    ..sort((a, b) => _median(a.full).compareTo(_median(b.full)));
  final fulls = [for (final s in screens) _median(s.full)];
  final firsts = [
    for (final s in screens)
      if (s.hasFirst) _median(s.first),
  ];

  // Figures 5.5.4 and 5.5.5
  final actions = [
    for (final row in supabase?.db ?? const <_DbRow>[])
      if (!row.read) row,
  ];
  final reads = [
    for (final row in supabase?.db ?? const <_DbRow>[])
      if (row.read) row,
  ];
  _DbRow? action(String label) =>
      supabase?.db.where((r) => r.label == label).firstOrNull;
  final addTask = action('Add a task');
  final decide = action('Approve or reject an update');
  final readTasks = action('Read project tasks');
  final api = supabase?.api ?? const <_ApiRow>[];
  final apiAll = supabase?.apiAll;
  final workApi = api.where(
    (r) => const {
      'Add a task',
      'Send a task update',
      'Approve or reject an update',
    }.contains(r.label),
  );

  final sentences = <String>[
    'We tested Watad with ${_thousands(run.tests.length)} automated tests '
        '(unit, widget and screen tests) in ${run.files} test files. '
        '${run.failed.isEmpty ? 'All of them passed' : '$passed passed and ${run.failed.length} failed'} '
        'in ${_duration(run.totalMs).replaceAll('min', 'minutes').replaceAll(' s', ' seconds')} '
        '(Figure 5.5.1).',
    if (work.isNotEmpty)
      "The tests follow the main steps of a project's work: the contractor "
          'adds a task, sends a progress update with photos, and the client '
          'approves or rejects it (Figure 5.5.2).',
    if (scope.paths.isEmpty)
      'They also cover payments, the marketplace, chat, the blockchain '
          'monitor and the admin tools.',
    if (screens.isNotEmpty)
      'We also measured speed. On the test machine, the main screens draw '
          'their first frame in ${firsts.reduce(math.min).toStringAsFixed(0)} '
          'to ${firsts.reduce(math.max).toStringAsFixed(0)} ms and are fully '
          'shown in ${fulls.reduce(math.min).toStringAsFixed(0)} to '
          '${fulls.reduce(math.max).toStringAsFixed(0)} ms, as the median of '
          '20 runs (Figure 5.5.3).',
    if (actions.isNotEmpty)
      'On the server, the database does each action in '
          '${actions.map((r) => r.mean).reduce(math.min).toStringAsFixed(0)} '
          'to ${actions.map((r) => r.mean).reduce(math.max).toStringAsFixed(0)} '
          'ms on average'
          '${addTask == null ? '' : ': adding a task takes ${addTask.mean.toStringAsFixed(0)} ms'}'
          '${decide == null ? '' : ', approving or rejecting an update ${decide.mean.toStringAsFixed(0)} ms'}'
          '${readTasks == null ? '' : ", and reading a project's tasks about ${readTasks.mean.toStringAsFixed(0)} ms"}'
          ' (Figure 5.5.4).',
    if (apiAll != null)
      'Seen from Supabase, a whole request, database included, takes about '
          '${(apiAll.p50 / 1000).toStringAsFixed(2)} s for half of the '
          'requests and under ${(apiAll.p95 / 1000).toStringAsFixed(1)} s '
          'for 95% of them (Figure 5.5.5).',
    if (run.failed.isEmpty)
      'These results show that the app works as expected and answers fast '
          'enough for daily use.',
  ];

  final summary = [
    '${run.failed.isEmpty ? 'All ${_thousands(run.tests.length)}' : '$passed of ${_thousands(run.tests.length)}'} '
        'automated tests passed (Figures 5.5.1 and 5.5.2).',
    if (fulls.isNotEmpty)
      'The main screens are shown in under '
          '${(fulls.reduce(math.max) + 1).toStringAsFixed(0)} ms on the test '
          'machine${apiAll == null ? '' : ', and the server answers in about ${(apiAll.p50 / 1000).toStringAsFixed(2)} s'} '
          '(${apiAll == null ? 'Figure 5.5.3' : 'Figures 5.5.3 to 5.5.5'}).',
  ].join(' ');

  String notMeasured(String what) =>
      '<p class="empty">Not measured in this run: $what</p>';

  const noToken =
      'no Supabase access token was given. Run the script again and paste '
      'one when asked.';

  final fig3 = screens.isEmpty
      ? notMeasured('the benchmark was skipped or did not run.')
      : '''
${_bars([for (final s in screens) (s.name, _median(s.full), '')], math.max(fulls.reduce(math.max) * 1.15, 20), mark: 16.7, markLabel: '16.7 ms = one frame at 60 fps')}
${_table(['Screen', 'First frame, median', 'First frame, 95%', 'Fully shown, median', 'Fully shown, 95%'], [
          for (final s in screens) [_e(s.name), _ms(s.hasFirst ? _median(s.first) : null), _ms(s.hasFirst ? _percentile(s.first, .95) : null), _ms(_median(s.full)), _ms(_percentile(s.full, .95))],
        ])}
<p class="cap"><b>Figure 5.5.3.</b> The main screens draw their first frame in ${firsts.reduce(math.min).toStringAsFixed(0)} to ${firsts.reduce(math.max).toStringAsFixed(0)} ms and are fully shown in ${fulls.reduce(math.min).toStringAsFixed(0)} to ${fulls.reduce(math.max).toStringAsFixed(0)} ms. Measured in Flutter's test engine (${_e(machine)}) with sample data, so it shows the app's own work (building, layout and drawing) without the network. The client home first checks the user's role, so only its full time is shown.</p>''';

  final since = supabase?.since == null
      ? 'since the statistics were last reset'
      : 'since ${_date(DateTime.parse(supabase!.since!))}';
  final fig4 = supabase == null
      ? notMeasured(noToken)
      : actions.isEmpty && reads.isEmpty
      ? notMeasured(_e(supabase.problems.join(' ')))
      : '''
${_bars([for (final r in actions) (r.label, r.mean, '${r.calls} calls')], math.max(actions.isEmpty ? 0 : actions.map((r) => r.mean).reduce(math.max) * 1.15, 20))}
${_table(['Action', 'Calls', 'Average', 'Slowest'], [
          for (final r in actions) [_e(r.label), '${r.calls}', _ms(r.mean), _ms(r.max)],
          for (final r in reads) ['${_e(r.label)} <span class="tag">read</span>', '${r.calls}', _ms(r.mean, 2), _ms(r.max)],
        ])}
<p class="cap"><b>Figure 5.5.4.</b> ${addTask == null ? '' : 'Adding a task takes ${addTask.mean.toStringAsFixed(0)} ms on average. '}${decide == null ? '' : 'Approving or rejecting an update takes ${decide.mean.toStringAsFixed(0)} ms. '}This includes the database's own checks, the notification to the other user and marking the project for the blockchain copy.${readTasks == null ? '' : " Reading a project's tasks takes about ${readTasks.mean.toStringAsFixed(readTasks.mean < 10 ? 1 : 0)} ms."}</p>''';

  final missingWork = workApi.isEmpty
      ? ' No task was added or approved in these 24 hours, so for those '
            'actions see their database time in Figure 5.5.4; the request '
            'around it adds about '
            '${apiAll == null ? '0.25' : (apiAll.p50 / 1000).toStringAsFixed(2)} s.'
      : '';
  final fig5 = supabase == null
      ? notMeasured(noToken)
      : api.isEmpty
      ? notMeasured(
          supabase.problems.isEmpty
              ? 'no requests from the app in the last 24 hours.'
              : _e(supabase.problems.join(' ')),
        )
      : '''
${_bars([for (final r in api) (r.label, r.p50, '')], math.max(api.map((r) => r.p50).reduce(math.max) * 1.2, 20))}
${_table(['Request', 'Supabase name', 'Requests', 'Median', '95%'], [
          for (final r in api) [_e(r.label), '<code>${_e(r.name)}</code>', '${r.count}', _ms(r.p50, 0), _ms(r.p95, 0)],
          if (apiAll != null) ['<b>All app requests</b>', '', '<b>${apiAll.count}</b>', '<b>${_ms(apiAll.p50, 0)}</b>', '<b>${_ms(apiAll.p95, 0)}</b>'],
        ])}
<p class="cap"><b>Figure 5.5.5.</b> ${apiAll == null ? '' : 'Half of the requests are answered in about ${(apiAll.p50 / 1000).toStringAsFixed(2)} s, and 95% of them in under ${(apiAll.p95 / 1000).toStringAsFixed(1)} s. '}This includes the database, but not the user's own mobile network.$missingWork</p>''';

  final fig2 = work.isEmpty
      ? notMeasured('the tests of the project work were not in this run.')
      : '''
<div class="term">$_dots${_workTerminal(work)}</div>
<p class="cap"><b>Figure 5.5.2.</b> The steps of a project's work are tested from start to end: the contractor adds a task and sends an update with photos, and the client approves or rejects it. The tests also check that wrong input is refused, for example more than 3 photos, or a task marked done before it starts.</p>''';

  return '''
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Watad Testing Results</title>
<style>
:root{--bg:#f6f4f1;--card:#fff;--ink:#1c1a18;--body:#5f5852;--line:#e6e1dc;--accent:#e8722c;--ok:#24895b;--bad:#bf3c2f;--term:#16181d;--termink:#e7e7e7}
*{box-sizing:border-box} body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif}
main{max-width:960px;margin:0 auto;padding:32px 16px 64px}
h1{font-size:26px;margin:0 0 4px} .lead{color:var(--body);margin:0 0 28px}
.fig{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:22px 24px;margin:0 0 28px}
.fig h2{font-size:17px;margin:0 0 4px} .fig .sub{color:var(--body);font-size:13px;margin:0 0 14px}
.cap{color:var(--body);font-size:13px;margin:12px 0 0;border-top:1px solid var(--line);padding-top:10px} .cap b{color:var(--ink)}
.empty{color:var(--body);font-style:italic;margin:6px 0 0}
.term{background:var(--term);color:var(--termink);border-radius:10px;padding:14px 18px 16px;font:12.5px/1.6 ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;white-space:pre-wrap;overflow-x:auto}
.term .pr{color:#9aa0a6} .term .ok{color:#5fd38d} .term .bad{color:#ff7b72} .term .dim{color:#8b949e} .term .grp{color:#f0a868;font-weight:600}
.dots{display:flex;gap:6px;margin:0 0 10px} .dots i{width:10px;height:10px;border-radius:50%;display:block}
table{width:100%;border-collapse:collapse;font-size:13.5px;margin-top:6px} th,td{text-align:left;padding:7px 10px;border-bottom:1px solid var(--line)}
th{color:var(--body);font-weight:600;font-size:12.5px} td:not(:first-child),th:not(:first-child){text-align:right;font-variant-numeric:tabular-nums}
code{font:12px ui-monospace,SFMono-Regular,Menlo,monospace}
.tag{font-size:11px;color:var(--body);border:1px solid var(--line);border-radius:4px;padding:0 4px;margin-left:4px}
.kpis{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin:0 0 14px}
.kpi{border:1px solid var(--line);border-radius:10px;padding:12px} .kpi b{display:block;font-size:22px} .kpi span{color:var(--body);font-size:12.5px}
.kpi.bad b{color:var(--bad)}
.chart .bl{font-size:12.5px;fill:var(--ink)} .chart .bv{font-size:12px;fill:var(--body)} .chart .bar{fill:var(--accent)}
.chart .mark{stroke:var(--bad);stroke-dasharray:4 3;stroke-width:1.2} .chart .ml{font-size:11.5px;fill:var(--bad)}
.text p{margin:0 0 10px} .tools li{margin:0 0 6px}
@media (max-width:640px){.kpis{grid-template-columns:repeat(2,1fr)} .fig{padding:16px}}
@media print{body{background:#fff} .fig{break-inside:avoid}}
</style></head><body><main>
<h1>Watad, testing results</h1>
<p class="lead">For the report, section 5.5.1 (Unit Testing). Each box is one figure, ready to screenshot. Measured on $today.</p>

<section class="fig" id="fig1">
<h2>Figure 5.5.1: The automated test run</h2><p class="sub">${_e(scopeText)}, run with <code>flutter test</code>.</p>
<div class="kpis">
<div class="kpi"><b>${_thousands(passed)}</b><span>tests passed</span></div>
<div class="kpi${run.failed.isEmpty ? '' : ' bad'}"><b>${run.failed.length}</b><span>tests failed</span></div>
<div class="kpi"><b>${run.files}</b><span>test files</span></div>
<div class="kpi"><b>${_duration(run.totalMs)}</b><span>to run them all</span></div>
</div>
<div class="term">$_dots${_summaryTerminal(run)}</div>
<p class="cap"><b>Figure 5.5.1.</b> ${run.failed.isEmpty ? 'All ${_thousands(run.tests.length)} automated tests pass.' : '$passed of ${_thousands(run.tests.length)} automated tests pass; ${run.failed.length} fail.'} They test the data, the rules, the screens and the navigation of ${scope.paths.isEmpty ? 'every part of the app' : 'these parts of the app'}.</p>
</section>

<section class="fig" id="fig2">
<h2>Figure 5.5.2: Tests of a project's work steps</h2><p class="sub">Adding a task, sending a progress update, and the client's approval or rejection. Real test names and times from the same run.</p>
$fig2
</section>

<section class="fig" id="fig3">
<h2>Figure 5.5.3: Screen rendering time</h2><p class="sub">Median time until each screen is fully shown, 20 runs each (lower is better).</p>
$fig3
</section>

<section class="fig" id="fig4">
<h2>Figure 5.5.4: Database time of each action (Supabase)</h2><p class="sub">Average time the database takes for each action, from all real use of the app $since.</p>
$fig4
</section>

<section class="fig" id="fig5">
<h2>Figure 5.5.5: Server response time (Supabase)</h2><p class="sub">Time from when Supabase receives a request from the app until the answer is ready, last 24 hours.</p>
$fig5
</section>

<section class="fig text" id="text">
<h2>Text for section 5.5.1</h2>
<p>${_e(sentences.join(' '))}</p>
<h2 style="margin-top:16px">New sentence for the 5.5 summary</h2>
<p>${_e(summary)}</p>
<p class="cap">This replaces "All 13 unit tests passed (Table 5.5.1)".</p>
</section>

<section class="fig tools" id="tools">
<h2>What was used</h2>
<ul>
<li><b>Flutter test</b> (<code>flutter test --reporter json</code>; ${_e(machine)}) ran the ${_thousands(run.tests.length)} automated tests. Its JSON report gave the test names, results and times in Figures 5.5.1 and 5.5.2.</li>
<li><b>A rendering benchmark</b> (<code>tool/report/ui_render_benchmark_test.dart</code>) opened each main screen of the app 20 times with sample data, and a <code>Stopwatch</code> timed the first frame and the time until the screen stopped changing (Figure 5.5.3).</li>
<li><b>Supabase <code>pg_stat_statements</code></b>, PostgreSQL's query statistics, read through the Management API's read-only SQL endpoint, gave the number of calls and the average and slowest database time of each action (Figure 5.5.4).</li>
<li><b>Supabase API logs</b>, read through the Management API, gave the response time (<code>origin_time</code>) of each request from the app over the last 24 hours, from which we took the median and the 95th percentile (Figure 5.5.5).</li>
<li><b>Dart</b> (<code>tool/report/make_report.dart</code>) computed the medians and percentiles and wrote this HTML page with SVG charts. Run it again with <code>tool/report/report.sh</code> or <code>tool\\report\\report.bat</code>.</li>
</ul>
<p class="cap">The Supabase numbers were only read; nothing was written to the live database to take them. They come from the real use of the app.</p>
</section>
</main></body></html>
''';
}
