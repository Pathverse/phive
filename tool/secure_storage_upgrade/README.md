# Android secure-storage upgrade acceptance

This disposable app checks PHive's default and named seed persistence and
decrypts two retained GCM records across flutter_secure_storage 10.3.4 → 11.2.0.
It uses real Android secure storage. It does not use plugin mocks or real user
data. The fixture includes disposable seed baselines in app-private files so a
missing seed cannot be mistaken for a successful migration.

Prerequisites: Python 3, Flutter 3.47.5 / Dart 3.13.4, Android SDK/build tools,
and an Android device or emulator (API 24+). Put Flutter and adb on PATH. The
generated app uses the Flutter template's compileSdk and debug signing key.
Use the same workspace, application ID and signing key for both upgrade phases.

From the repository root, choose a new directory outside the repository and
the serial of a disposable Android test device:

```sh
proof_workspace=$(mktemp -d)/phive_storage_upgrade
proof_device=emulator-5556
python3 tool/secure_storage_upgrade/prepare.py "$proof_workspace" --version 10.3.4
cd "$proof_workspace"
flutter build apk --debug --target-platform android-arm64 \
  --dart-define=PHIVE_PHASE=write --dart-define=STORAGE_VERSION=10.3.4
adb -s "$proof_device" install build/app/outputs/flutter-apk/app-debug.apk
adb -s "$proof_device" shell am start -W \
  -n dev.phive.acceptance.phive_storage_upgrade/.MainActivity
adb -s "$proof_device" exec-out run-as dev.phive.acceptance.phive_storage_upgrade \
  cat files/phive-upgrade-result.json
```

Wait for the result file, then require `passed: true`, `phase: write`, and
`version: 10.3.4`. Save the result and the APK before the next build. Adjust
`--target-platform` for a non-arm64 device. If the application ID already exists,
use a fresh disposable device/app installation before starting; the writer
deliberately rejects preexisting fixtures and secure-storage entries.

From the repository root, prepare the same workspace with version 11:

```sh
python3 tool/secure_storage_upgrade/prepare.py "$proof_workspace" --version 11.2.0
cd "$proof_workspace"
flutter build apk --debug --target-platform android-arm64 \
  --dart-define=PHIVE_PHASE=verify --dart-define=STORAGE_VERSION=11.2.0
adb -s "$proof_device" shell am force-stop dev.phive.acceptance.phive_storage_upgrade
adb -s "$proof_device" install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s "$proof_device" shell am start -W \
  -n dev.phive.acceptance.phive_storage_upgrade/.MainActivity
adb -s "$proof_device" exec-out run-as dev.phive.acceptance.phive_storage_upgrade \
  cat files/phive-upgrade-result.json
```

Require a **new** result with `passed: true`, `phase: verify`, and `version:
11.2.0`. An old write result is not a passing upgrade. Do not uninstall, clear
app data, delete seeds, or recreate the emulator between these two phases.
The reader checks raw native values before provider initialization, compares
both seed bytes with their original baselines, and decrypts both old records.

After saving the upgrade proof, test a fresh 11 installation separately:

```sh
adb -s "$proof_device" uninstall dev.phive.acceptance.phive_storage_upgrade
flutter build apk --debug --target-platform android-arm64 \
  --dart-define=PHIVE_PHASE=fresh --dart-define=STORAGE_VERSION=11.2.0
adb -s "$proof_device" install build/app/outputs/flutter-apk/app-debug.apk
adb -s "$proof_device" shell am start -W \
  -n dev.phive.acceptance.phive_storage_upgrade/.MainActivity
adb -s "$proof_device" exec-out run-as dev.phive.acceptance.phive_storage_upgrade \
  cat files/phive-upgrade-result.json
```

Require `passed: true` and `phase: fresh`. Save API level, resolved pubspec.lock,
build logs, signing certificate fingerprints, and the three result files with
the verification evidence. Only the disposable acceptance app may be uninstalled.

This checks the default 10.3.4 storage path. It does not establish migration
from pre-10 storage, deprecated cipher options, custom namespaces, biometric
settings, or other operating systems. Follow upstream migration instructions
for those deployments.
