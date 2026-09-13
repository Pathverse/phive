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

The bound tests use native temporary storage. They do not establish browser
IndexedDB behavior; dedicated web serialization coverage remains outstanding.
