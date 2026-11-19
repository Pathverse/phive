# Tasks

## 1. Checkpoint 1: Immutable Seed Views & AES Key Size Validation

- [x] 1.1 Cache read-only views of owned bytes in `SecureStorageSeedProvider`. Validate key length in `PhiveMetaRegistry.requireSeedSync` and return a read-only snapshot of the provider bytes. Cover generated and reloaded keys, accepted AES lengths, rejection of an invalid length, caller mutation and later mutation of the custom provider’s source buffer. Observe RED then GREEN with `flutter test test/secure_storage_seed_provider_test.dart` in `phive_barrel`.
- [x] 1.2 Create an incremental checkpoint commit for immutable seed caching and AES key-length validation after `pspec check commit` and `zmem-author-commits` validation pass, keeping active OpenSpec change artifacts local and unstaged (completion evidence: passing `pspec check commit` and verified Git commit for Checkpoint 1).

## 2. Checkpoint 2: Shared AES-GCM Utility, Zero-Copy Buffers & Strict AES-CBC PKCS7 Validation

- [x] 2.1 Extract shared AES-GCM nonce/cipher helpers into `phive_barrel/lib/src/gcm_helper.dart`, remove redundant `Uint8List.fromList` copies in `GCMEncrypted` (`phive_barrel/lib/templates/encrypted_gcm.dart`), `UniversalEncrypted` (`phive_barrel/lib/templates/encryption/encrypted_u.dart`), and `AESEncrypted` (`phive_barrel/lib/templates/encrypted_aes.dart`), and validate the IV, ciphertext length and every PKCS7 padding byte in `AESEncrypted`. Exercise every malformed-input scenario from the CBC delta, a fixed record from the pre-change writer, and fresh round trips for empty and block-aligned plaintext, with tests in `phive_barrel/test/secure_storage_seed_provider_test.dart` and `phive_test` (completion evidence: RED then GREEN `flutter test` in `phive_barrel` and `phive_test`, plus `dart analyze` clean).
- [x] 2.2 Create an incremental checkpoint commit for the shared GCM helper, zero-copy buffer handling, and strict `AESEncrypted` PKCS7 validation after `pspec check commit` and `zmem-author-commits` validation pass, keeping active OpenSpec change artifacts local and unstaged (completion evidence: passing `pspec check commit` and verified Git commit for Checkpoint 2).
