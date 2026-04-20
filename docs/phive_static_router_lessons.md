# PHive Payload Encoding And Dissection Guide

This guide explains how PHive values are encoded, what layers may appear in a stored payload, and how to dissect a raw value when inspecting storage directly.

## Overview

PHive values may pass through multiple encoding layers before they reach the underlying storage backend.

Depending on the router and the hooks in use, a stored value may include:

1. the domain value
2. a hook-transformed value
3. a PHive payload string
4. Hive binary framing
5. a router-level primitive storage envelope

This layering is expected. The goal of this document is to make that representation understandable.

## 1. PHive Payloads

PHive uses `PTypeAdapter.serializePayload()` to combine a value with optional hook metadata.

The general shape is:

```text
base64(metadata)%PVR%value
```

If no metadata exists, the payload may be just the value string.

### 1.1 Delimiter

PHive uses the literal delimiter:

```text
%PVR%
```

This separates base64-encoded metadata from the serialized value.

### 1.2 Metadata Section

The metadata section is a base64-encoded JSON object.

Example:

```text
eyJub25jZSI6InNXdDV0cjhPQlB1NnlGSFoifQ==
```

decodes to:

```json
{"nonce":"sWt5tr8OBPu6yFHZ"}
```

### 1.3 Value Section

The value section is the string representation of the transformed field value.

For encrypted fields, this is often base64 ciphertext. For unhooked string fields, it may remain readable text.

## 2. Hook Effects On Payloads

Hooks can transform both the field value and the PHive metadata.

### 2.1 `GCMEncrypted()`

`GCMEncrypted()` typically does two things during write:

1. encrypts the field value
2. records the nonce in PHive metadata

That is why an encrypted field may look like this before decode:

```text
eyJub25jZSI6InNXdDV0cjhPQlB1NnlGSFoifQ==%PVR%9XMMpwyuXdRDhkjnPq8Y55b1cwtEU8fBcQruMjQ=
```

In that payload:

- the left side carries metadata such as the nonce
- the right side carries the encrypted field value

### 2.2 Other Hooks

Other hooks may also attach metadata or alter the stored value representation.

Common cases include:

- TTL metadata for expiry-aware hooks
- encrypted payloads for other cipher-based hooks
- format-specific metadata needed for restoration on read

## 3. Hive Binary Layer

Generated PHive adapters still write values through Hive binary serialization.

That means a stored model is not just a concatenation of readable field values. Hive adds its own binary structure around the adapter output.

For string fields, Hive binary framing typically includes:

- a value type marker
- a length field
- the UTF-8 bytes for the string

This is why raw binary dumps may show a mix of readable text and unreadable control characters.

## 4. Visible Raw Characters

When Hive binary is rendered as text, some bytes may appear as:

- control characters
- replacement glyphs
- stray ASCII symbols such as `$`

These usually reflect binary framing rather than data corruption.

Examples include:

- custom type identifiers
- string type markers
- length bytes rendered as text

For string-heavy models, readable field values may still appear inline because the string bytes remain valid UTF-8 inside the binary frame.

## 5. Static Router Storage Envelope

`PHiveStaticRouter` adds one more layer when storing values through `BoxCollection`.

The static-router write path is:

1. generated adapter writes the Hive payload
2. PHive hooks transform fields and attach metadata
3. Hive binary serialization produces the binary payload
4. the router base64-encodes that binary payload
5. `CollectionBox<String>` stores the primitive string

This means that a static-router stored value may contain:

- a base64 wrapper at the router boundary
- which decodes into Hive binary
- which may contain PHive payload strings
- which may themselves contain metadata and ciphertext

## 6. Example Dissection

Consider a raw encrypted field payload:

```text
eyJub25jZSI6InNXdDV0cjhPQlB1NnlGSFoifQ==%PVR%9XMMpwyuXdRDhkjnPq8Y55b1cwtEU8fBcQruMjQ=
```

It can be dissected like this:

1. `eyJub25jZSI6InNXdDV0cjhPQlB1NnlGSFoifQ==`
	- base64 metadata
2. `%PVR%`
	- PHive delimiter
3. `9XMMpwyuXdRDhkjnPq8Y55b1cwtEU8fBcQruMjQ=`
	- transformed field value, here ciphertext

If this payload appears inside a full model dump, the surrounding bytes may still include Hive binary framing and router-level wrapping.

## 7. Dissection Workflow

When inspecting a stored value directly, peel it back in this order:

1. determine whether you are looking at a router-level primitive wrapper
2. determine whether the value is Hive binary
3. identify any PHive payload string inside it
4. split on `%PVR%` if metadata is present
5. decode metadata JSON
6. identify whether the value section is plaintext, ciphertext, or another transformed representation

This approach helps distinguish valid layered encoding from actual storage bugs.

## 8. Recommended Mental Model

Use this model when reading PHive storage:

- generated adapters define value semantics
- hooks transform values and attach metadata
- Hive adds binary framing
- routers define the storage layout and may add a transport-safe outer envelope

The stored representation is therefore often a composed format, not a single plain-text value.

## Summary

- PHive payloads use `base64(metadata)%PVR%value` when metadata is present.
- Hook metadata and transformed values may both appear inside the same string payload.
- Hive adds binary framing around generated adapter output.
- `PHiveStaticRouter` adds a primitive base64 envelope at the `CollectionBox<String>` boundary.
- Raw stored values should be dissected layer by layer rather than interpreted as plain text.