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