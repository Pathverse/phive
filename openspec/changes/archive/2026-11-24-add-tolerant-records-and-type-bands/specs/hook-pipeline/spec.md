# Spec Delta

## MODIFIED Requirements

### Requirement: Single versioned metadata header with no legacy fallback

The metadata header SHALL occupy Hive index 0 of the binary record, with field values following at subsequent indices. `PTypeAdapter.extractMetadataHeader()` SHALL accept header version `2` (positional field values) and version `3` (one tagged field mapping), and SHALL report which version was read. It SHALL throw `StateError` for any other version; there SHALL be no fallback for older formats. Records written by pre-0.6.0 adapters using the `%PVR%`/`%PAR%` format SHALL be unreadable by current adapters, requiring a data migration on upgrade. Adapters without the tolerant layout hook SHALL continue to write version 2.

#### Scenario: A record at the current header version reads back

- **WHEN** a metadata-aware record written at header version 2 is read
- **THEN** `extractMetadataHeader()` succeeds and field indices are read after index 0.

#### Scenario: A tagged record reads back

- **WHEN** a record written by a tolerant adapter at header version 3 is read
- **THEN** `extractMetadataHeader()` succeeds, reports version 3, and the tagged field mapping is read after index 0

#### Scenario: A record at an unknown header version is rejected

- **WHEN** a record carries a metadata header version other than 2 or 3
- **THEN** `extractMetadataHeader()` throws `StateError` with no legacy fallback.

> Coverage gap: no behave scenario exercises the version-mismatch rejection path; `proof_hook_metadata` exercises only the current-version round trip.

## ADDED Requirements

### Requirement: Schema drift is a distinct corrective signal

Schema drift detected by a generated adapter SHALL be raised as a dedicated `PHiveActionException` subtype carrying the type and the offending field. It SHALL request no behavior by itself; the router's registration policy decides the response. It SHALL be distinguishable from expiry and other hook signals.

#### Scenario: Drift is not mistaken for expiry

- **WHEN** a read raises schema drift on a registration whose policy is the default
- **THEN** the caller receives the drift exception identifying the type and field, and no entry is deleted
