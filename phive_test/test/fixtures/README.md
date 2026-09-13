# Version-2 metadata fixture

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
