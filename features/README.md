# Run PHive acceptance checks

These checks exercise complete storage journeys, including reads after a second browser build. Run them when changing behavior that spans the runtime and generated adapters.

## Prepare the checkout

Install Flutter, Python, and uv. The browser checks also need Google Chrome and Flutter web support. From the repository root, prepare the two test packages.

```sh
cd phive
flutter pub get
cd ../phive_test
flutter pub get
dart run build_runner build
cd ..
```

## Run every journey

```sh
uv run --with behave python -m behave
uv run --with behave python -m unittest discover -s features/tests -v
```

Expect a Behave summary with zero failed scenarios, followed by `OK` from the binding tests.

## Run a browser check directly

For storage names and parent-child relationships across two minified builds, run this from the repository root.

```sh
uv run --with playwright python tool/verify_store_names_web.py
```

The successful run prints `PASS: minified storage naming across two builds`.

For tolerant fields, enum cases, and positional collections across two builds, run the second probe.

```sh
uv run --with playwright python tool/verify_tolerant_web.py
```

The successful run prints `PASS: tolerant records across two minified builds`. Both probes use an isolated headless browser context and keep storage between their writer and reader builds. Their build logs are under `.dart_tool/store_names/` and `.dart_tool/tolerant_web/`.

## Find a failure

Read the failed scenario's output for the owning package and Flutter command. Run that command inside the package to reproduce it. For example, run `flutter test --no-pub --tags proof_enum_adapters` inside `phive_test`.

`features/steps/proof_steps.py` maps tags to packages. Add a mapping there when introducing a new proof. The binding tests check that unsupported tags fail before a command is launched.

After building the naming probe, this diagnostic command deliberately asks for a missing store and should exit with an error.

```sh
uv run --with playwright python tool/verify_store_names_web.py --skip-build --single-build --expect-name deliberately_missing_store
```

Use the complete two-build commands above for acceptance evidence.
