# System Patterns

## 1. Generator-Centric Architecture
The \phive_generator\ acts as an overload for \hive_ce_generator\. It maps the target class properties matching \@PHiveField\ to Hive fields internally (\%PHIVE[X]%\ schema or raw names), wraps the parsing rules inside \PTypeAdapter\ methods, and emits the final adapter class. Models utilizing Freezed must be abstract classes so mixins satisfy analyzer bounds.

## 2. Shared Context (\PHiveCtx\) Pattern
Since there are no more wrapper classes on the domain layer, the generator weaves a \PHiveCtx\ object during read/write cycles. 
- During \write\, \PHiveCtx.pendingMetadata\ and \PHiveCtx.value\ are manipulated by hooks before writing to the binary format.
- During \
ead\, \PHiveCtx.metadata\ is hydrated first, allowing post-read hooks to unpack details (like evaluating TTL).

## 3. The Hook Pipeline (\PHiveHook\)
Hooks hold no internal state (they are \const\ singletons). They apply changes entirely via mutating \PHiveCtx\.
- \preWrite(PHiveCtx ctx)\
- \postWrite(PHiveCtx ctx)\
- \preRead(PHiveCtx ctx)\
- \postRead(PHiveCtx ctx)\

## 4. PTypeAdapter Base Class
Generated adapters inherit from \PTypeAdapter<T>\. This isolates the boilerplate to instantiate contexts, run hooks iteratively based on annotations, and abstract Hive's BinaryReader / BinaryWriter syntax safely.

## 5. Model-Level Hooks
Hooks can also be attached at the model level via \@PHiveType(hooks: [])\, acting on a root \PHiveCtx\ that propagates or controls universal persistence rules (e.g., global expiration of the item).

Update: generator now parses model-level hooks and merges them with field hooks when emitting `runPreWrite/runPostWrite/runPostRead` blocks.

## 6. Exception Orchestration & PHiveConsumer
Instead of throwing fatal exceptions during \Hook\ execution (which would crash reading a Hive Box), \Hooks\ throw \PHiveActionException\ configurations. 
A \PHiveConsumer<T>\ object wraps the native \Hive.box()\ interface and catches these custom exceptions. It checks the exception's \codes\ array to automatically perform corrective actions (like code \3\ telling the Consumer to immediately delete the corrupted/expired key from the box so it isn't fetched again).

## 7. Consumer Adapter Pattern
\PHiveConsumer<T>\ utilizes a \PHiveConsumerAdapter\ implementation (like \DefaultHiveAdapter\) to abstract away stateful connections. The adapter automatically checks for open boxes and establishes scope, hiding \Hive\ entirely from the UI.

## 8. Context-Overload Adapter Pattern
Consumer extensibility now flows through `PHiveConsumerCtx`:
- adapters hydrate overload slots in ctx (`overloadableBox`, get/set/delete/clear methods),
- each adapter declares `providedSlots`,
- consumer validates slot collisions before runtime.

This enables stacking multiple adapters (default + collection/scope adapters) while preserving deterministic ownership of each overload point.

