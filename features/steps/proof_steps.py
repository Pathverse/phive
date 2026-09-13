import shutil
import subprocess
from pathlib import Path
from behave import given, when, then

PROJECT_ROOT = Path(__file__).resolve().parents[2]
PROOF_PACKAGES = {
    "proof_router_crud": "phive",
    "proof_router_container": "phive",
    "proof_router_reset": "phive",
    "proof_router_static_layout": "phive",
    "proof_router_reparenting": "phive",
    "proof_hook_action_exception": "phive",
    "proof_hook_metadata": "phive_test",
}


def _proof_tag(context):
    tags = [t for t in context.scenario.tags if t.startswith("proof_")]
    assert len(tags) == 1, (
        f"expected exactly one @proof_<id> tag on the scenario, found {tags or 'none'}"
    )
    return tags[0]


@given("a bound integration proof exists for this scenario")
def step_bound(context):
    context.proof_tag = _proof_tag(context)
    assert context.proof_tag in PROOF_PACKAGES, f"Unknown proof: {context.proof_tag}"
    context.proof_package = PROJECT_ROOT / PROOF_PACKAGES[context.proof_tag]


@when("the bound integration proof is executed")
def step_execute(context):
    flutter = shutil.which("flutter")
    assert flutter, "Flutter executable not found on PATH"
    context.proof_command = [flutter, "test", "--no-pub", "--tags", context.proof_tag]
    context.result = subprocess.run(
        context.proof_command,
        cwd=str(context.proof_package),
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )


@then("it passes")
def step_passes(context):
    r = context.result
    assert r.returncode == 0, (
        f"bound proof '{context.proof_tag}' failed (exit {r.returncode})\n"
        f"package: {context.proof_package}\ncommand: {context.proof_command}\n"
        f"stdout:\n{r.stdout}\n"
        f"stderr:\n{r.stderr}"
    )
