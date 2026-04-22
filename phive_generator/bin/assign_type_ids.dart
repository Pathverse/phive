/// CLI tool: scans a Dart package for `@PHiveAutoType` classes and assigns
/// each a stable Hive typeId in `phive_type_registry.json`.
///
/// Usage:
///   dart run phive_generator:assign_type_ids [options]
///
/// Options:
///   --dir {path}        Directory to scan for .dart files. Default: lib/
///   --registry {path}   Registry file path. Default: phive_type_registry.json
///   --start {int}       Minimum typeId to assign (floor). Default: 0
///   --dry-run           Print changes without writing to disk.
///   --help              Show this help message.
///
/// The tool is idempotent: running it multiple times does not change already-
/// assigned ids.  New classes found in subsequent scans are appended with the
/// next available id.
///
/// Run this tool once after annotating new classes with `@PHiveAutoType`, then
/// commit `phive_type_registry.json` before invoking `build_runner`.
library;

import 'dart:io';

import 'package:phive_generator/src/type_registry.dart';

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  if (options == null) return; // --help was printed

  final scanDir = Directory(options.scanDir);
  if (!scanDir.existsSync()) {
    stderr.writeln('Error: scan directory "${options.scanDir}" does not exist.');
    exitCode = 1;
    return;
  }

  // ── Load existing registry ────────────────────────────────────────────────

  final registryFile = File(options.registryPath);
  var registry = registryFile.existsSync()
      ? TypeIdRegistry.fromJson(registryFile.readAsStringSync())
      : TypeIdRegistry.empty();

  // ── Scan source files for @PHiveAutoType class names ──────────────────────

  final discovered = _scanForAutoTypeClasses(scanDir);

  if (discovered.isEmpty) {
    stdout.writeln('No @PHiveAutoType classes found in "${options.scanDir}".');
    return;
  }

  final newClasses =
      discovered.where((name) => !registry.contains(name)).toList();

  if (newClasses.isEmpty) {
    stdout.writeln(
      'All ${discovered.length} discovered class(es) are already registered.',
    );
    _printRegistry(registry);
    return;
  }

  // ── Assign ids to new classes ─────────────────────────────────────────────

  final updated = registry.assignAll(newClasses, startAt: options.startAt);

  stdout.writeln(
    'Discovered ${discovered.length} class(es), '
    '${newClasses.length} newly assigned:',
  );
  for (final name in newClasses) {
    stdout.writeln('  + $name → typeId ${updated.lookupTypeId(name)}');
  }

  // ── Write registry ────────────────────────────────────────────────────────

  if (options.dryRun) {
    stdout.writeln('\n[dry-run] Registry NOT written to "${options.registryPath}".');
    stdout.writeln('Resulting registry would be:');
    stdout.writeln(updated.toJson());
    return;
  }

  registryFile.writeAsStringSync(updated.toJson());
  stdout.writeln('\nRegistry written to "${options.registryPath}".');
}

// ── Scanner ───────────────────────────────────────────────────────────────────

/// Finds all class names annotated with `@PHiveAutoType` under [dir].
///
/// Uses a two-step forward-scan strategy:
/// 1. Locate every `@PHiveAutoType` occurrence in the file.
/// 2. From each occurrence, scan forward up to [_scanWindowSize] characters
///    looking for the next `class ClassName` token.  The scan is aborted if
///    an opening brace `{` appears before the `class` keyword, which would
///    mean the annotation is inside an existing class body rather than
///    preceding a top-level declaration.
///
/// This handles all real-world layouts including multi-line annotation args,
/// Freezed `abstract class`, and stacked annotations such as
/// `@PHiveAutoType() @JsonSerializable() class MyModel`.
const int _scanWindowSize = 600;

List<String> _scanForAutoTypeClasses(Directory dir) {
  final annotationRe = RegExp(r'@PHiveAutoType');
  final classRe = RegExp(r'\bclass\s+(\w+)');

  final names = <String>{};
  final dartFiles = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in dartFiles) {
    final source = file.readAsStringSync();
    for (final ann in annotationRe.allMatches(source)) {
      final end = (ann.start + _scanWindowSize).clamp(0, source.length);
      final window = source.substring(ann.start, end);

      final classMatch = classRe.firstMatch(window);
      if (classMatch == null) continue;

      // Abort if a class body opens before the class keyword — the annotation
      // is inside an existing class rather than preceding a new declaration.
      final braceIdx = window.indexOf('{');
      if (braceIdx != -1 && braceIdx < classMatch.start) continue;

      final name = classMatch.group(1);
      if (name != null) names.add(name);
    }
  }

  return names.toList()..sort();
}

// ── Argument parsing ──────────────────────────────────────────────────────────

class _Options {
  final String scanDir;
  final String registryPath;
  final int startAt;
  final bool dryRun;

  const _Options({
    required this.scanDir,
    required this.registryPath,
    required this.startAt,
    required this.dryRun,
  });
}

_Options? _parseArgs(List<String> args) {
  var scanDir = 'lib';
  var registryPath = 'phive_type_registry.json';
  var startAt = 0;
  var dryRun = false;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--help':
      case '-h':
        _printHelp();
        return null;
      case '--dry-run':
        dryRun = true;
      case '--dir':
        if (i + 1 >= args.length) _die('--dir requires a value');
        scanDir = args[++i];
      case '--registry':
        if (i + 1 >= args.length) _die('--registry requires a value');
        registryPath = args[++i];
      case '--start':
        if (i + 1 >= args.length) _die('--start requires a value');
        startAt = int.tryParse(args[++i]) ?? _die('--start must be an integer');
      default:
        _die('Unknown argument: ${args[i]}');
    }
  }

  return _Options(
    scanDir: scanDir,
    registryPath: registryPath,
    startAt: startAt,
    dryRun: dryRun,
  );
}

Never _die(String message) {
  stderr.writeln('Error: $message');
  stderr.writeln('Run with --help for usage.');
  exit(1);
}

void _printHelp() {
  stdout.writeln('''
assign_type_ids — Assign Hive typeIds to @PHiveAutoType classes.

Usage:
  dart run phive_generator:assign_type_ids [options]

Options:
  --dir <path>        Directory to scan for .dart source files.
                      Default: lib/
  --registry <path>   Path to the registry JSON file.
                      Default: phive_type_registry.json
  --start <int>       Minimum typeId to assign (floor for new ids).
                      Default: 0
  --dry-run           Print changes without writing to disk.
  --help              Show this message.

Workflow:
  1. Annotate your models with @PHiveAutoType.
  2. Run this tool to populate phive_type_registry.json.
  3. Commit phive_type_registry.json.
  4. Run build_runner as normal.
''');
}

void _printRegistry(TypeIdRegistry registry) {
  if (registry.isEmpty) return;
  stdout.writeln('\nCurrent registry:');
  stdout.writeln(registry.toJson());
}
