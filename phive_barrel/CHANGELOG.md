## Unreleased

- Support flutter_secure_storage 11 alongside 10. Seed keys and base64url
  encoding are unchanged. Version 11 requires Android API 24 or newer;
  legacy secure-storage data must complete its 10.x migration before upgrading.

- Apply Dart 3.13 formatting to existing library sources.

- Add a runnable TTL example covering fresh reads and deletion on expiry.

- Include the full Apache-2.0 and BSD-3-Clause license texts while preserving
  the existing dual-license choice.

## 0.8.0

- Validate AES seed lengths and return read-only seed snapshots.
- Reject malformed AES-CBC IVs, ciphertext and padding with `FormatException`.
  Valid records written by earlier versions remain readable.
- Share GCM cipher setup across the string and universal hooks.
- Require PHive runtime `^0.8.0`.

## 0.7.0

- Align the PHive runtime dependency to ^0.7.0; encryption and TTL hook APIs are unchanged.
- Compatibility update for the PHive header-based metadata redesign.
- Barrel hooks now operate against PHive's versioned `global` and `perField` metadata header model rather than legacy payload wrappers.

## 0.3.0
- added true classhooks

## 0.2.1

- Fixed `TTL.preWrite` to skip null field values — no TTL metadata is written when a nullable field holds null, preventing spurious payload wrapping. Requires `phive ^0.2.1`.

## 0.2.0
- Compatibility updates for PHive 0.2.0.

## 0.1.0

- Initial hook bundle release for PHive.
- Added TTL, AES, GCM, and universal encryption hooks.
- Added behavior-driven TTL expiry cleanup.
- Added secure
