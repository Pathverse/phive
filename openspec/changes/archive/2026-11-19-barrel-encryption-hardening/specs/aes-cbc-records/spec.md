# Spec Delta

## Purpose

Defines how the AES-CBC string hook reads existing encrypted PHive records and reports malformed record data.

## ADDED Requirements

### Requirement: Valid CBC records retain their plaintext

With the original seed, the AES-CBC hook SHALL decode valid records written by the previous writer using the existing base64Url ciphertext, `iv` metadata and PKCS7 padding.

#### Scenario: Read an existing encrypted record

- **WHEN** the hook reads a fixed ciphertext and IV captured from the pre-change writer using its original seed
- **THEN** it restores the exact original string.

#### Scenario: Round-trip empty and block-aligned plaintext

- **WHEN** the hook writes and then reads an empty string or a string whose UTF-8 length is exactly 16 bytes
- **THEN** it restores the original string in both cases, including removal of a complete padding block.

### Requirement: Reject malformed CBC records

For a string payload with IV metadata and a valid seed, the hook SHALL throw `FormatException` for an invalid IV length, empty or non-block-aligned ciphertext, or invalid PKCS7 padding.

#### Scenario: Invalid IV length

- **WHEN** the decoded IV is shorter or longer than 16 bytes
- **THEN** the hook throws `FormatException`.

#### Scenario: Invalid ciphertext length

- **WHEN** the decoded ciphertext is empty or its byte length is not a multiple of 16
- **THEN** the hook throws `FormatException`.

#### Scenario: Invalid padding length

- **WHEN** the final decrypted byte declares zero or more than 16 padding bytes
- **THEN** the hook throws `FormatException`.

#### Scenario: Inconsistent trailing padding

- **WHEN** the final byte declares a valid padding length but another byte in the declared padding differs
- **THEN** the hook throws `FormatException`.
