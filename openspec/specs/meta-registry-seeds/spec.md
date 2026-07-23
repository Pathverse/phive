# meta-registry-seeds Specification

## Purpose

`PhiveMetaRegistry` and `PhiveSeedProvider` own the process-wide key material that PHive encryption hooks depend on: a single registered seed provider, its asynchronous initialization, and synchronous keyed seed retrieval. This capability owns only the registration and retrieval contract — not the concrete provider implementations (secure storage, in-memory), which live in `phive_barrel` templates.

## Requirements

### Requirement: Process-wide seed provider registration

`PhiveMetaRegistry` SHALL hold a single process-wide `PhiveSeedProvider` used by PHive encryption hooks, set via `registerSeedProvider`. A `PhiveSeedProvider` SHALL expose asynchronous `init()` for dynamic seed loading and synchronous `getSeedSync(seedId)` for keyed retrieval from memory after initialization.

#### Scenario: A registered provider becomes the active source

- **WHEN** a consumer calls `PhiveMetaRegistry.registerSeedProvider(provider)`
- **THEN** subsequent seed retrievals resolve through that provider.

> Coverage gap: no behave scenario exercises seed-provider registration; encryption hooks that depend on it live in `phive_barrel` templates, which are out of scope for this change.

### Requirement: Initialization before encrypted reads or writes

`PhiveMetaRegistry.init()` SHALL await the registered provider's `init()` when a provider is present, and SHALL be a no-op when none is registered. Consumers SHALL await `init()` before performing encrypted reads or writes.

#### Scenario: Initialization delegates to the registered provider

- **WHEN** a provider is registered and `PhiveMetaRegistry.init()` is awaited
- **THEN** the provider's `init()` completes before any synchronous seed retrieval is attempted.

#### Scenario: Initialization with no provider is a no-op

- **WHEN** `PhiveMetaRegistry.init()` is awaited with no provider registered
- **THEN** it completes without error.

### Requirement: Synchronous key retrieval fails loudly when unready

`PhiveMetaRegistry.requireSeedSync(seedId)` SHALL return the loaded seed from the registered provider, and SHALL throw `StateError` when no provider is registered, instructing the caller to register a provider and await `init()` before using encryption hooks.

#### Scenario: Retrieval before registration is rejected

- **WHEN** `requireSeedSync` is called with no seed provider registered
- **THEN** it throws `StateError` directing the caller to register a provider and await `init()`.

#### Scenario: Retrieval after registration returns the seed

- **WHEN** a provider is registered and initialized, and `requireSeedSync(seedId)` is called
- **THEN** the provider's synchronously loaded seed is returned.
