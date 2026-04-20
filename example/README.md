# PHive Example

Simple Flutter app demonstrating PHive storage through both router implementations.

## What it Shows

- save strongly typed models into Hive CE
- restore login/cache models through `PHiveDynamicRouter`
- observe field-level hook behavior for TTL and encryption
- inspect parent-child router relations through `PHiveStaticRouter`, `createRef`, `getContainer`, `deleteContainer`, and `deleteWithChildren`
- show how static-router values remain hook-aware even though they are stored through `BoxCollection`
- show generated router descriptors installing registration and ref wiring declaratively

## Run the App

```bash
flutter pub get
flutter run -d chrome
```

## Regenerate Adapters After Model Changes

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Quick Flow

1. Use the **Hooked Cache Demo** to save and restore encrypted and TTL-backed values through the dynamic router.
2. Wait for TTL expiry and restore again to observe the temporary session fields expire and disappear.
3. Use the **Router Relations Demo** to seed a lesson graph and load its contained cards through the static router.
4. Try **Delete Cards Only** and **Cascade Delete Lesson** to see router ref behavior change in place.

## Demo Behavior

- `Settings.secretKey` uses `GCMEncrypted`
- `Settings.cachedToken` uses `TTL(10)`
- `Settings.config` uses `UniversalEncrypted`
- `UserProfile.encryptedToken` uses `GCMEncrypted`
- `UserProfile.tempSessionId` uses `TTL(10)`
- expired TTL values trigger behavior-driven cleanup that deletes the stored entry and returns `null`
- the login/cache section uses `PHiveDynamicRouter`
- the lesson/card relations section uses `PHiveStaticRouter` with `BoxCollection`
- static-router values are stored through a primitive string boundary so generated adapters and PHive hooks continue to define the payload semantics
- `DemoLessonCard.lessonId` is routed through a generated `createRef<DemoLessonCard, DemoLesson>` relationship
- `getContainer` loads all lesson cards for the current lesson handle
- `deleteContainer` clears only the child card box entries and ref store entry
- `deleteWithChildren` removes the lesson and its routed child cards together

## Storage Notes

The example intentionally shows both router boundaries:

- the dynamic router uses `LazyBox<T>` for primary values so keyed reads can apply hook-driven behaviors
- the static router uses one `BoxCollection` with multiple named stores

When inspecting static-router values directly, remember that PHive may store base64-encoded Hive binary payloads at the `CollectionBox<String>` boundary. Read values back through PHive APIs for the decoded domain model.

## Related Packages

- `phive` (core runtime)
- `phive_generator` (adapter and descriptor generation)
- `phive_barrel` (ready-made hooks)
