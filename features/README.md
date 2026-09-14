# Acceptance proofs

Run from the repository root after restoring Flutter dependencies in `phive` and
`phive_test` and regenerating integration models in `phive_test` with the local
generator:

```powershell
uv run --with behave python -m behave
uv run --with behave python -m unittest discover -s features/tests -v
```

`features/steps/proof_steps.py` maps each supported proof tag to its owning
package. Router and action-exception proofs run from `phive`; the
`proof_hook_metadata` proof runs from `phive_test`, where generated adapters
restore actual stored bytes. The runner invokes `flutter test --no-pub --tags
<tag>` and includes the package, command, and captured output in failure reports.
Unknown tags fail before execution.

`proof_router_reparenting` covers both router implementations and both ways to
delete a former container after moving a child. `proof_hook_metadata` covers both
explicit and automatic type IDs with both routers, including field overrides,
global defaults, null overrides, and whole-object metadata scope.

`proof_generated_store_names` runs native generated-model persistence checks in
`phive_test`. `proof_release_store_names` runs a dedicated browser proof through
`tool/verify_store_names_web.py`. The latter requires `uv`, Flutter web support,
and Google Chrome. Playwright is resolved as development tooling by `uv`; no
browser tooling is added to runtime packages.

Run the release proof directly from the repository root:

```powershell
uv run --with playwright python tool/verify_store_names_web.py
```

The runner builds two minified JavaScript releases, uses an isolated headless
Chrome context, inspects IndexedDB names, and verifies primary and relationship
reads across builds at one origin without resetting storage. Builds and logs go
under ignored `.dart_tool/store_names/`. Browser/build/assertion failures fail the
scenario. `--skip-build` and `--single-build` are diagnostic options, not substitutes
for the complete acceptance run. To verify failure propagation after building:

```powershell
uv run --with playwright python tool/verify_store_names_web.py --skip-build --single-build --expect-name deliberately_missing_store
```

That command must exit nonzero. This proves generated naming on JavaScript web
and native storage; it does not establish all IndexedDB, native-obfuscation, or
Wasm behavior.
