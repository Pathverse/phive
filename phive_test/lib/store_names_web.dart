import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'models/naming_models.dart';
import 'proofs/naming_proof.dart';

@JS('phiveReport')
external void report(JSString value);

class _VariantA {
  int get value => 1;
}

class _VariantB {
  String get value => 'second build';
}

Future<void> main() async {
  const build = String.fromEnvironment('PROOF_BUILD', defaultValue: 'A');
  final variant = build == 'A' ? _VariantA().value : _VariantB().value;
  final backend = Uri.base.queryParameters['backend']!;
  final write = Uri.base.queryParameters['phase'] == 'write';
  final result = <String, Object?>{
    'build': build, 'variant': variant, 'backend': backend,
    'release': kReleaseMode,
    // This diagnostic deliberately observes minification; storage does not use it.
    // ignore: avoid_type_to_string
    'runtimeType': NamingCard('probe', 'parent').runtimeType.toString(),
  };
  try {
    requireNaming(kReleaseMode, 'Proof must run in release mode');
    registerNamingAdapters();
    final router = await openNamingRouter(backend);
    await namingRoundTrip(router, write: write);
    await Hive.close();
    result['ok'] = true;
  } catch (error, stack) {
    result.addAll({'ok': false, 'error': '$error', 'stack': '$stack'});
  }
  report(jsonEncode(result).toJS);
}
