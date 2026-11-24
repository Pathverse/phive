# Check compatibility with existing records

Run this check from the phive_test package before changing serialization.

```sh
flutter pub get
flutter test --no-pub test/serialization_compatibility_test.dart
```

The test reads the saved bytes and checks the restored field values. Keep those
bytes fixed when regenerating adapters so the check continues to represent data
written by an earlier version.

<details>
<summary>Where the fixture bytes came from</summary>

## Version-2 metadata fixture

`explicit_metadata_v2.base64` is the adapter-body byte sequence captured with
`ExplicitMetadataAdapter.write` before the metadata-precedence fix, using Hive CE
2.20.0. It contains the existing version-2 header and four positional fields; it
does not contain a top-level Hive type ID or a box frame.

The original record has id `record`, overridden `stored-field`, inherited
`stored-sibling`, and nullable `stored-nullable`. Global metadata is
`marker: global`; field metadata overrides `overridden` with `marker: field`
and `nullable` with `marker: null`.

Keep this fixture fixed when regenerating adapters. The compatibility test must
read these bytes independently of the current adapter writer.

## Constant-index fixture

The `constant_index_legacy.base64` fixture was written by the previous
generator's adapter with a declared constant index of 8 for `first`
and literal index 1 for `second`. That writer inferred index 0 for
`first` and wrote `first-value` before `second-value`. The upgraded
model pins `first` to literal index 0 to retain the deployed sequence.

</details>
