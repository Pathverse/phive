# Proposal

## Why

`phive_barrel` currently exposes mutable key lists from `SecureStorageSeedProvider`'s in-memory cache, does not validate AES key lengths in `PhiveMetaRegistry.requireSeedSync`, silently falls back to raw padded bytes in `AESEncrypted` when PKCS7 padding is corrupted (or fails with an unguarded range error on non-block-aligned ciphertexts), and duplicates AES-GCM cipher setup and redundant `Uint8List.fromList` buffer copies across `GCMEncrypted`, `AESEncrypted`, and `UniversalEncrypted`.

## What Changes

- **Immutable seed views & AES key length validation**:
  - Cache an owned `Uint8List` as a read-only view via `asUnmodifiableView()` in `SecureStorageSeedProvider` so callers cannot mutate cached key material in memory.
  - Validate in `PhiveMetaRegistry.requireSeedSync` that the returned seed length is a valid AES key size (`16`, `24`, or `32` bytes), throwing `StateError` on invalid key material.
- **Strict PKCS7 & block-alignment validation in `AESEncrypted`**:
  - Verify that the IV is exactly 16 bytes, that decoded ciphertext is non-empty and a multiple of the 16-byte AES block size before invoking `CBCBlockCipher.processBlock`, and verify that all trailing PKCS7 padding bytes equal `padLength` (`1..16`), throwing `FormatException` on invalid ciphertext or padding.
- **Deduplicate AES-GCM helpers & eliminate redundant `Uint8List.fromList` copies**:
  - Share AES-GCM nonce generation and cipher initialization between `GCMEncrypted` and `UniversalEncrypted`, reuse `Random.secure()`, and pass the `Uint8List` results of `utf8.encode` and `base64Url.decode` directly without redundant `Uint8List.fromList` copies.

## Capabilities

### New Capabilities

- `aes-cbc-records` specifies CBC record decoding, malformed-input errors and compatibility with valid persisted records.

### Modified Capabilities

- `meta-registry-seeds`: Require synchronous seed retrieval to enforce valid AES key sizes (`16`, `24`, or `32` bytes) and protect cached seed material from in-place mutation.

## Impact

- **`phive_barrel`**:
  - `lib/src/meta.dart`: AES key-length validation (`16`, `24`, `32` bytes) and `Uint8List` normalization in `PhiveMetaRegistry.requireSeedSync`.
  - `lib/templates/encryption/secure_storage_seed_provider.dart`: Cache read-only views of owned key buffers.
  - `lib/templates/encrypted_gcm.dart`, `lib/templates/encryption/encrypted_u.dart`, `lib/templates/encrypted_aes.dart`: Shared GCM helper, zero-copy `utf8.encode` / `base64Url.decode` usage, and strict PKCS7 padding + block-alignment validation in `AESEncrypted`.
  - `test/secure_storage_seed_provider_test.dart`: Add unit tests for immutable cached seeds, invalid key length rejection, and `AESEncrypted` padding/alignment validation.
