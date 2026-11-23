# Proposal

## Why

The three public PHive packages should meet all current pub.dev quality checks. License texts and runnable examples are implemented; the local reports still deduct points for seven source-formatting mismatches and dependency constraints excluding build 5 and flutter_secure_storage 11.

## What Changes

- Retain the completed full Apache-2.0 OR BSD-3-Clause licenses and isolated runnable examples, including the approved parent-only runtime example override.
- Format the seven reported production files using the recorded Flutter/Dart toolchain, with no semantic edits.
- Extend generator compatibility to build 5 while retaining build 4 and analyzer 10 through 14 support. Verify compatible current and older resolved dependency stacks instead of raising every dependency floor.
- Refresh Hive dependencies to hive_ce 2.24.0, hive_ce_generator 1.12.1 on the latest generator stack, and hive_ce_flutter 2.6.0 in local Flutter consumers. Preserve public Hive minimum constraints; update local example/test constraints and the tracked demo lockfile. Verify persistence and generated adapters before declaring compatibility.
- Extend barrel compatibility to flutter_secure_storage 11 while retaining version 10 support. Preserve seed storage keys, encoded values, and existing encrypted records; document upstream platform and migration requirements.
- Verify the affected package suites, generated adapters, dependency lower bounds, real Android seed persistence across a 10-to-11 upgrade, and isolated package examples.
- Refresh Pana and publication dry runs for all three final candidates, targeting 160/160 each. Treat local results and later hosted results separately.
- Keep version bumps, publication, Git pushes, runtime API redesign, and unrelated refactoring outside this change.

## Capabilities

### New Capabilities

None. This is package maintenance: presentation, formatting and support for additional dependency versions. `.openspec.yaml` retains `skip_specs: true` because no new PHive runtime behavior is proposed.

### Modified Capabilities

None. Existing serialization, router, hook and seed contracts must continue to hold under the expanded dependency ranges. Any necessary behavioral redesign requires reconciliation before implementation.

## Impact

In addition to the already changed licenses, examples and documentation, affected files include seven public-library Dart files, generator/barrel dependency manifests, compatibility tests, and upgrade documentation. The local integration package's secure-storage constraint and consumer lockfiles may need focused updates to exercise the new stack; shared-demo behavior remains unchanged. Example-local dependencies and approved overrides remain isolated from published library manifests.

Observed local baseline after presentation work: phive 150/160, phive_generator 140/160, phive_barrel 140/160. Formatting accounts for 10 points per package; dependency freshness accounts for the remaining 10 in each companion. Earlier 8/8 completion applies to that first phase only.

No separate architecture prototype is needed: source inspection shows the generator consumes BuildStep without implementing it, and the seed provider uses the common constructor/read/write API. Upstream manifests admit the intended combinations. Compatibility and native persistence remain required implementation evidence, not assumptions of success.

Sources: [build changelog](https://pub.dev/packages/build/changelog), [secure-storage changelog](https://pub.dev/packages/flutter_secure_storage/changelog), and the local Pana reports retained with this change.
