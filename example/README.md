# Try PHive in a Flutter app

Use this demo to save a cached value, watch TTL expiry, and move or delete related lesson cards.

## Run the demo

From the repository root, use Flutter 3.44 or newer with Dart 3.11 or newer and resolve dependencies for that SDK.

```sh
cd example
flutter pub get
flutter run -d chrome
```

Google Chrome and Flutter web support are needed for this command. You can choose another configured Flutter device instead.

## Try these flows

1. Open **Hooked Cache Demo**. Save a value and restore it to see the stored data.
2. Wait more than ten seconds and restore again to see TTL-backed values expire.
3. Open **Router Relations Demo**. Seed the lesson graph, then load a lesson's cards.
4. Try **Delete Cards Only**, then seed again and try **Cascade Delete Lesson** to compare the two actions.

## Change a model

Edit a model under `lib`, then regenerate its adapters before running the app again.

```sh
dart run build_runner build
```

The demo uses local copies of all three PHive packages. Its Freezed models and the integration package can resolve different compatible generator toolchains, so run `flutter pub get` inside the package you are using.

## Where to go next

- [Use PHive in your app](../phive/README.md).
- [Generate your own adapters](../phive_generator/README.md).
- [Configure expiry and encryption](../phive_barrel/README.md).
- [Run the cross-package tests](../phive_test/README.md).
