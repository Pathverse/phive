# Product Context

## Why this exists
Standard Hive CE provides great storage speed but lacks built-in primitives for field-level/model-level interception (hooks like encryption, LRU, validation, TTL). A previous iteration used a wrapper-class approach (`PHiveVar<T>`) but failed at separating domain concerns from persistence code. 

## The Shift
By shifting entirely to a generator-centric design:
- Domain models remain completely decoupled ("Plain Old Dart Objects" or Freezed models).
- The behavior is defined via static annotations array `hooks: [GCMEncrypted.instance]`.
- The generator creates a subclass of `PTypeAdapter` acting identically to a generic Hive TypeAdapter but seamlessly interleaves context propagation and hook execution internally.

## Target Experience
Users define normal class properties:
```dart
@freezed
@PHiveType(typeId: 1)
abstract class Note with _$Note {
  const factory Note({
    @PHiveField(0) required String id,
    @PHiveField(1, hooks: [GCMEncrypted.instance]) required String blob,
  }) = _Note;
}
```
All metadata creation, storage formatting, and field transformation is handled inside the auto-generated `PTypeAdapter` behind the scenes.
