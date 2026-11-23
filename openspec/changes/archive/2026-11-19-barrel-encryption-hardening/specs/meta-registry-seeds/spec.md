# Spec Delta

## ADDED Requirements

### Requirement: Seed retrieval enforces valid AES key sizes and immutability

`PhiveMetaRegistry.requireSeedSync(seedId)` SHALL validate that the retrieved seed has a valid AES key length (`16`, `24`, or `32` bytes), throwing `StateError` otherwise, and SHALL return an unmodifiable byte list so callers cannot mutate cached seed material in memory.

#### Scenario: Invalid AES key length is rejected

- **WHEN** a registered seed provider returns a seed whose byte length is not `16`, `24`, or `32`
- **THEN** `PhiveMetaRegistry.requireSeedSync(seedId)` throws `StateError` identifying the invalid key length.

#### Scenario: Returned seed bytes cannot be mutated in place

- **WHEN** a caller attempts to modify an element of the list returned by `PhiveMetaRegistry.requireSeedSync(seedId)` or `SecureStorageSeedProvider.getSeedSync(seedId)`
- **THEN** the modification throws `UnsupportedError` and the cached key material remains unchanged.

#### Scenario: A custom provider retains writable seed bytes

- **WHEN** a caller retrieves a valid seed through the registry and the provider later changes its source buffer
- **THEN** the bytes in the previously returned seed retain their original values.
