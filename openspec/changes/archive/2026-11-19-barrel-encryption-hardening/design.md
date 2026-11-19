# Design

## Context

See `proposal.md` for motivation and the `meta-registry-seeds` and `aes-cbc-records` deltas for requirements. `phive_barrel` provides the encryption hooks (`GCMEncrypted`, `AESEncrypted`, `UniversalEncrypted`) and seed infrastructure (`PhiveMetaRegistry`, `PhiveSeedProvider`, `SecureStorageSeedProvider`) used across `phive_test` and `example`.

## Goals / Non-Goals

**Goals:**
- Prevent callers from mutating cached key material returned by `SecureStorageSeedProvider.getSeedSync` or `PhiveMetaRegistry.requireSeedSync`.
- Validate AES key byte length (`16`, `24`, or `32` bytes) in `PhiveMetaRegistry.requireSeedSync`.
- Enforce strict block alignment (`ciphertext.isNotEmpty && ciphertext.length % 16 == 0`) and full PKCS7 padding verification in `AESEncrypted`.
- Deduplicate AES-GCM cipher/nonce helpers and remove redundant `Uint8List.fromList` copies in `GCMEncrypted`, `UniversalEncrypted`, and `AESEncrypted`.

**Non-Goals:**
- Changing the metadata keys (`nonce`, `nonce_u`, `iv`) or base64Url ciphertext format of existing encrypted records.

## Decisions

### 1. Immutable Key Views & Key Size Validation in `PhiveMetaRegistry`
- **Choice**:
  - For loaded and newly generated keys, keep an owned `Uint8List` and cache its `asUnmodifiableView()` result. Return the cached read-only view to callers.
  - In `requireSeedSync`, check the provider result has 16, 24 or 32 bytes. For an invalid length, report the length in a `StateError`. For a valid result, return `Uint8List.fromList(seed).asUnmodifiableView()` so a custom provider retaining a writable alias cannot change bytes already handed to a caller. Keep the public `List<int>` return signature.
- **Rationale**: Protects both `SecureStorageSeedProvider` and any custom `PhiveSeedProvider` implementation against accidental in-place key mutation and misconfigured key sizes.

### 2. Strict PKCS7 Unpadding & Ciphertext Alignment in `AESEncrypted`
- **Choice**:
  - In `AESEncrypted.postRead`, after `base64Url.decode`, verify `ciphertext.isNotEmpty && ciphertext.length % _blockSize == 0` and `iv.length == _blockSize`; otherwise throw `FormatException('Invalid AES-CBC ciphertext or IV length.')`.
  - In `_unpadPlaintext(Uint8List paddedPlaintext)`, verify `paddedPlaintext.isNotEmpty && paddedPlaintext.length % _blockSize == 0`, read `final padLength = paddedPlaintext.last`, verify `padLength >= 1 && padLength <= _blockSize`, and check that every byte in `paddedPlaintext.length - padLength ..< paddedPlaintext.length` equals `padLength`. If any check fails, throw `FormatException('Invalid PKCS7 padding in AES-CBC payload.')`.
  - Use `Uint8List.sublistView(paddedPlaintext, 0, paddedPlaintext.length - padLength)` instead of `Uint8List.fromList(paddedPlaintext.sublist(...))` to avoid an extra allocation before `utf8.decode`.

### 3. Shared AES-GCM Utility & Zero-Copy Buffer Handling
- **Choice**:
  - Create a package-internal helper `phive_barrel/lib/src/gcm_helper.dart` holding a shared `Random.secure()` instance, `createGcmNonce()`, and `buildGcmCipher(bool encrypt, List<int> key, Uint8List nonce)`.
  - In `GCMEncrypted`, `UniversalEncrypted`, and `AESEncrypted`, use `utf8.encode(...)` and `base64Url.decode(...)` directly as `Uint8List` without wrapping them in `Uint8List.fromList(...)`.

## Utility Contracts & Verification Plan

- **Reuse Assessment**: Consolidate duplicated GCM cipher/nonce construction inside `phive_barrel/lib/src/` using existing `pointycastle` and `dart:typed_data` primitives.
- **Utility Contracts**:
  - Registry reads require a registered provider and valid AES key length. Each successful read supplies an immutable snapshot.
  - `AESEncrypted`: Throws `FormatException` on non-block-aligned ciphertext, invalid IV length, or corrupted PKCS7 padding bytes.
- **Focused Verification**:
  - Exercise direct provider reads for generated and reloaded keys, registry reads through a mutable custom provider, and invalid key lengths. Decode a fixed CBC record captured with the current writer and verify fresh empty-string and full-block round trips. Assert the specified exception for each malformed IV, ciphertext and padding case.

## Risks / Trade-offs

- Strict padding changes how malformed records surface to callers. A CBC record that passes these structural checks has no authenticity guarantee.
