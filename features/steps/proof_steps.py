import subprocess
from pathlib import Path
from behave import given, when, then

# phive/ package root — two directories up from features/steps/
PHIVE_PKG = Path(__file__).resolve().parents[2] / "phive"


def _proof_tag(context):
    tags = [t for t in context.scenario.tags if t.startswith("proof_")]
    assert len(tags) == 1, (
        f"expected exactly one @proof_<id> tag on the scenario, found {tags or 'none'}"
    )
    return tags[0]


@given("a bound integration proof exists for this scenario")
def step_bound(context):
    context.proof_tag = _proof_tag(context)


@when("the bound integration proof is executed")
def step_execute(context):
    context.result = subprocess.run(
        ["flutter", "test", "--tags", context.proof_tag],
        cwd=str(PHIVE_PKG),
        capture_output=True,
        text=True,
    )


@then("it passes")
def step_passes(context):
    r = context.result
    assert r.returncode == 0, (
        f"bound proof '{context.proof_tag}' failed (exit {r.returncode})\n"
        f"stdout:\n{r.stdout}\n"
        f"stderr:\n{r.stderr}"
    )
