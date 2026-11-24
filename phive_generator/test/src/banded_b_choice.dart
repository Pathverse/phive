import 'package:phive/phive.dart';

/// Banded fixture: shares its simple name with the other band's fixture.
@PHiveAutoType(autoFields: true)
class Choice {
  /// Choice identifier.
  final String id;

  /// Display label.
  final String label;

  /// Creates a choice.
  const Choice(this.id, this.label);
}
