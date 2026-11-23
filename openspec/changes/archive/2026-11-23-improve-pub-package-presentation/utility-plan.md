# Utility plan

Status: not applicable; no reusable utility implementation is needed.

## Reuse assessment

| Responsibility | Existing facility | Decision and verification |
| --- | --- | --- |
| Recognize published licenses and examples | Pana's license/example report sections | Use the installed CLI and record its version and SDK; inspect actual category results. No custom score calculator. |
| Determine published contents | `flutter pub publish --dry-run` | Inspect each package's listed files and warnings. No custom packaging framework. |
| Demonstrate persistence | Public PHive routers, generated adapters, and Hive CE | Use the same public APIs consumers use. Execute examples against temporary storage and verify restored values. |
| Demonstrate generation | Existing `phive_generator` builders and `build_runner` | Regenerate example adapters and analyze/execute the result. No generator wrappers. |
| Demonstrate hook cleanup | Public `TTL` hook and router action handling | Show a successful read followed by expiry and deletion through real storage. No clock or hook abstraction changes. |

The expanded scope adds formatter use, dependency-matrix runs and a disposable native upgrade harness. Dart format, Pub, existing generator/provider APIs, and Flutter native integration facilities own those responsibilities. No new reusable utility contracts, custom detectors or runtime wrappers are needed. Utility maturation remains not applicable; dependency and integration work belongs to apply. Focused verification includes real generation and persisted-seed/decryption checks across an Android app upgrade. Utility ownership and public signatures remain with the existing packages.
