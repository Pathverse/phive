# PHive Glossary

This glossary defines the core terms used across PHive documentation.

## Generated Adapter

A generated adapter is the `PTypeAdapter<T>` implementation emitted by `phive_generator` for a model annotated with `@PHiveType`.

The generated adapter is responsible for:

- reading and writing model fields
- applying model-level and field-level hook pipelines
- serializing and deserializing PHive metadata
- translating between domain values and Hive binary payloads

In PHive, the generated adapter is the semantic serialization layer.

## Router Boundary

The router boundary is the layer where PHive maps domain types and parent-child relationships onto a concrete storage layout.

This boundary is implemented by `PHiveDynamicRouter` and `PHiveStaticRouter`.

At the router boundary, PHive decides:

- which named store a type belongs to
- how parent-child refs are recorded
- how values are loaded and deleted
- what storage backend shape is used for that router implementation

The router boundary does not replace generated adapters. It uses them.

## Storage Boundary

The storage boundary is the final value shape handed to the underlying Hive storage primitive.

Examples:

- in `PHiveDynamicRouter`, the storage boundary is a normal Hive `Box<T>` or `Box<dynamic>`
- in `PHiveStaticRouter`, the storage boundary is `CollectionBox<String>`

This term is useful because the value shape at the storage boundary may differ from the domain model and may also differ between router implementations.

## PHive Payload

A PHive payload is the string representation produced by `PTypeAdapter.serializePayload()` when a value carries PHive metadata.

Its general shape is:

```text
base64(metadata)%PVR%value
```

If no metadata exists, the payload may be just the value string.

A PHive payload is commonly used when hooks need to persist extra state such as:

- GCM nonces
- TTL metadata
- other hook-specific values

## Hook Metadata

Hook metadata is the extra state a hook records so the value can be interpreted correctly on read.

Examples include:

- a nonce for `GCMEncrypted()`
- expiry metadata for `TTL(...)`

Hook metadata is stored inside the PHive payload envelope, not in a separate application-visible field.

## Primitive Storage Envelope

A primitive storage envelope is a transport-safe representation used when the underlying storage layer needs primitive-compatible values.

In `PHiveStaticRouter`, the primitive storage envelope is a base64 string containing the Hive binary payload.

This allows PHive to preserve generated adapter semantics while using `BoxCollection` as the physical database layout.

## Ref Store

A ref store is the secondary store that maps a parent key to a list of child primary keys.

Ref stores support operations such as:

- `containerOf`
- `getContainer`
- `deleteContainer`
- `deleteWithChildren`

Ref stores are created through `createRef<T, P>()`.

## Primary Store

A primary store is the storage location for instances of one registered type.

Each registered PHive type is associated with one primary store identified by its resolved box name.

## Containership

Containership is the parent-child relationship declared through `createRef<T, P>()`.

In PHive, containership means:

- a child belongs to a parent
- the relationship is represented by a ref store
- container operations can retrieve or delete related children through the router

## Inspection Layers

When inspecting stored data directly, it helps to distinguish between these layers:

1. domain value
2. hook-transformed value
3. PHive payload
4. Hive binary payload
5. router storage envelope
6. final backend storage representation

These layers may all exist for the same logical value.