# PHive Example

Simple Flutter app demonstrating PHive storage through both router implementations.

## What it shows

- Save strongly typed models into Hive CE
- Restore login/cache models through `PHiveDynamicRouter`
- Observe field-level hook behavior for TTL and encryption
- Inspect parent-child router relations through `PHiveStaticRouter`, `createRef`, `getContainer`, `deleteContainer`, and `deleteWithChildren`
- Show how static-router values remain hook-aware even though they are stored through `BoxCollection`

## Run the app

```bash
flutter pub get
flutter run -d chrome
```

## Regenerate adapters after model changes

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Quick Flow

1. Use the **Hooked Cache Demo** to save and restore encrypted and TTL-backed values through the dynamic router
2. Wait for TTL expiry and restore again to observe the temporary session fields expire while encrypted fields remain readable
3. Use the **Router Relations Demo** to seed a lesson graph and load its contained cards through the static router
4. Try **Delete Cards Only** and **Cascade Delete Lesson** to see router ref behavior change in place

## Demo behavior

- `Settings.secretKey` uses `GCMEncrypted`
- `Settings.cachedToken` uses `TTL(10)`
- `Settings.config` uses `UniversalEncrypted`
- `UserProfile.encryptedToken` uses `GCMEncrypted`
- `UserProfile.tempSessionId` uses `TTL(10)`
- The login/cache section uses `PHiveDynamicRouter`
- The lesson/card relations section uses `PHiveStaticRouter` with `BoxCollection`
- Static-router values are stored through a primitive string boundary so generated adapters and PHive hooks continue to define the payload semantics
- `DemoLessonCard.lessonId` is routed through a `createRef<DemoLessonCard, DemoLesson>` relationship
- `getContainer` loads all lesson cards for the current lesson handle
- `deleteContainer` clears only the child card box entries and ref store entry
- `deleteWithChildren` removes the lesson and its routed child cards together

## Storage Notes

The example intentionally shows both router boundaries:

- the dynamic router uses normal Hive boxes
- the static router uses one `BoxCollection` with multiple named stores

When inspecting static-router values directly, remember that PHive may store base64-encoded Hive binary payloads at the `CollectionBox<String>` boundary. Read values back through PHive APIs for the decoded domain model.

## Related packages

- `phive` (core runtime)
- `phive_generator` (adapter code generation)
- `phive_barrel` (ready-made hooks)
