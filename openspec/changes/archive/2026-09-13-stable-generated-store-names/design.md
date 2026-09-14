## Context

See [proposal.md](proposal.md) for scope and the accepted store-recreation choice.
Both routers default primary names to `T.toString().toLowerCase()` and ref names
to `__ref_${P}_$T`. The shared `_emitRouterDescriptorBlock` only emits name
arguments when the collector finds an explicit override. `AutoTypeRouter` already
has a golden demonstrating omitted names; explicit-name goldens and example
models demonstrate existing override behavior.

`router_collection.dart` currently extracts override strings and parent type
source with regex. This source spelling is unsuitable as a canonical name: it
can include an import prefix, and string-expression extraction misses constants.
`phive_test` already resolves local sibling dependencies and exercises generated
adapters with both routers, but its native tests use `dart:io`. Its current
behave binding runs native Flutter tests; a bounded browser proof is needed.

Repository memory in `441f442`, lesson 2, records that cached object reads do not
prove deserialization. The new storage proofs must read actual persisted bytes.
No implementation or tests are run during propose.

## Goals / Non-Goals

**Goals:** Resolve generated storage identity before minification; preserve
explicit values; verify actual release persistence and explain upgrade effects.

**Non-Goals:** Runtime naming strategies, new annotations, global name registries,
hash-based defaults, collision-management redesign, automatic store migration,
class-rename migration, and all-platform release coverage. Direct registration
continues to require explicit names for release-stable persistence. Type-ID and
serialized record layout are unchanged.

## Decisions

### 1. Emit names in the shared generator, using the existing convention

Every generated primary registration supplies a literal lowercased declared
model name; every generated ref registration supplies a literal
`__ref_Parent_Child`. Both annotation modes already reach the same emitter.
Preserve the supplied ref-name case to avoid gratuitous changes to current
unminified naming; backend normalization remains its own existing behavior.

For example, a default `LessonCard` descriptor supplies:

```dart
router.register<LessonCard>(
  primaryKey: (item) => item.id,
  boxName: 'lessoncard',
);
router.createRef<LessonCard, Lesson>(
  resolve: (item) => item.lessonId,
  refBoxName: '__ref_Lesson_LessonCard',
);
```

A new runtime resolver would still need stable inputs unavailable from minified
type strings. A type-ID or hash scheme adds another identity policy without
improving this user's readability goal. Existing string overrides already cover
opaque naming and class-rename stability. Do not change manual fallbacks in this
slice; generated descriptors cease depending on them.

### 2. Separate storage names from source type expressions

Resolve the annotated parent type's declared simple name using analyzer metadata;
retain a valid in-scope Dart type expression for `createRef` separately. A prefix
such as `models.Lesson` must remain usable in code but must not enter the store
name. Resolve optional naming fields from evaluated annotation constants instead
of regex string fragments. Null selects a default; explicit strings win.
Serialize the resulting values as Dart literals with correct escaping, including
literal dollar signs. Use current generator dependencies where suitable.

Keep this parsing change restricted to router naming inputs. Do not rewrite hook
parsing or introduce new generic-type support. If a naming input cannot be
resolved from an otherwise supported annotation, emit an actionable generation
diagnostic rather than silently dropping a relationship or using a runtime name.
Existing annotation validation and descriptor-presence rules remain in force.

### 3. Verify at three boundaries

1. **Generator:** Golden and resolved-fixture tests for both annotation modes,
   omitted names, explicit/null/constant names, escaping, and prefixed parents.
   Include a model-rename fixture retaining explicit names. Assert generated
   naming arguments are literals rather than runtime type expressions.
2. **Native storage:** Add generated models with omitted names to `phive_test`,
   register their real adapters, write parents/children, close/reopen, and assert
   primary reads and container traversal on both routers. Inspect actual names
   with the appropriate backend normalization. Preserve explicit-name controls
   and a legacy-named sentinel store to demonstrate no implicit migration or
   deletion. Bind a `proof_generated_store_names` native acceptance scenario.
3. **Minified release:** Add a web-compatible entry point and minimal bootstrap
   in `phive_test`, isolated from existing `dart:io` test files. Build JavaScript
   with `flutter build web --release` targeting that fixture. A development-only
   Python Playwright runner builds/serves the fixture on loopback, uses a fresh
   browser context, runs a write phase, then loads a second release at the same
   origin and runs a read-only verification phase without clearing IndexedDB.
   Select a different reachable non-schema code variant for the second build;
   record both build identities and runtime type strings so minification is
   evidenced, without requiring any particular two-letter spelling or requiring
   that the minifier choose different names on every run.

The release fixture covers both routers and both annotation modes, default and
explicit names, primary retrieval and relationship traversal. Inspect actual
IndexedDB database/object-store names, not only descriptors or page success
text. Use isolated database namespaces per backend and exercise unexpected-name
failure reporting. Expose a small machine-readable pass/fail report; propagate
build/browser/assertion failures as a nonzero runner result. Serve the new build
without stale assets or a service worker while retaining the same origin and
browser context. Clean up only the harness's own temporary processes/artifacts.

Expose the runner through a dedicated behave release-proof step; the existing
native tag mapping continues to work unchanged for its current scenarios. A
missing browser or failed release build is missing evidence, not a passing or
silently skipped scenario. This is a bounded naming proof, not blanket coverage
of IndexedDB storage behavior. Browser tooling is a development dependency only.

### 4. Reuse and security

See [utility-plan.md](utility-plan.md). No new public utility API is required.
The source inspection and existing explicit-literal output establish the approach;
the release proof is verification during apply, not an exploratory prototype.

Document stable names as a persistence contract, not a security mechanism.
Readable defaults expose model terminology. Consumers may use explicit opaque
identifiers when desired; neither obscurity nor hashing the class name encrypts
data or prevents reverse engineering. References:
[Dart's type-string guidance](https://dart.dev/tools/linter-rules/avoid_type_to_string)
and [Flutter obfuscation limits](https://docs.flutter.dev/deployment/obfuscate).

## Risks / Trade-offs

- Existing minified stores have different names -> User accepts recreation;
  document the break, do not discover or remove old stores automatically.
- Class renames, lowercase name collisions, or same-named models in different
  libraries -> Document explicit names as stable identity and disambiguation.
  The default convention adds no global uniqueness guarantee.
- More than one logical relation for the same parent/child pair -> Continue to
  require explicit ref names where separate stores are intended; relationship
  selection semantics are outside this change.
- Emitted strings can be syntactically valid yet interpolate unexpectedly ->
  Exercise resolved constant values and literal escaping in generator tests.
- Debug tests mask minification -> Require actual JavaScript release execution
  and browser storage inspection before declaring implementation complete.

## Migration Plan

Regenerate adapters with the updated local generator, inspect name diffs, and
recreate/repopulate affected application stores using the consumer's existing
reset process. No consumer data is reset by this library change or planning step.
Explicitly named stores keep their identities; default names match the chosen
unminified convention but may differ from earlier compiled or prefixed names.

Roll back generator and generated outputs together if necessary. Rollback may
target old minified stores again and does not move data between old and new
names. Pin explicit names before a future model rename if continuity is needed.
