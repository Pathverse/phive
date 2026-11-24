"""Prove tolerant records across two minified web releases at one origin.

Build A stores TolerantLesson records. Build B, compiled separately and run
against the same browser storage, reads them through evolved models:
- a compatible evolution restores the original values;
- a retyped field reports schema drift by default and becomes a miss under
  the opt-in drift policy, proving the type checks survive release
  optimization;
- a positional record with typed collection fields restores with its
  declared element types.

Run: uv run --with playwright python tool/verify_tolerant_web.py
Uses an isolated headless Chrome context; never opens the user's profile.
"""

import argparse
import hashlib
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import shutil
import subprocess
import threading

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "phive_test"
OUTPUT = ROOT / ".dart_tool" / "tolerant_web"
BACKENDS = ["dynamic", "static"]


def build(variant, skip):
    destination = OUTPUT / f"web-{variant.lower()}"
    command = [
        shutil.which("flutter") or "flutter", "build", "web", "--release",
        "--no-web-resources-cdn", "--no-wasm-dry-run",
        "--target=lib/tolerant_web.dart", f"--dart-define=PROOF_BUILD={variant}",
        f"--output={destination}",
    ]
    if not skip:
        OUTPUT.mkdir(parents=True, exist_ok=True)
        print(f"Building {variant}: {command}", flush=True)
        with (OUTPUT / f"web-{variant.lower()}-build.log").open("w", encoding="utf-8") as log:
            result = subprocess.run(command, cwd=PACKAGE, stdout=log, stderr=subprocess.STDOUT)
        if result.returncode:
            raise RuntimeError(f"Release build {variant} failed: {command}; see {log.name}")
    digest = hashlib.sha256((destination / "main.dart.js").read_bytes()).hexdigest()
    return destination, digest


class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, *_):
        pass


def run_phase(page, port, variant, backend, phase):
    page.goto(f"http://127.0.0.1:{port}/?backend={backend}&phase={phase}")
    page.wait_for_function("window.phiveResult !== undefined", timeout=90000)
    result = page.evaluate("window.phiveResult")
    print(json.dumps(result, sort_keys=True), flush=True)
    assert result["build"] == variant and result["release"], result
    assert result["runtimeType"] != "TolerantCard", "Fixture was not minified"
    assert result["ok"], result
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skip-build", action="store_true", help="Use existing outputs for diagnostics only")
    args = parser.parse_args()
    first, first_digest = build("A", args.skip_build)
    serving = {"path": first}
    server = ThreadingHTTPServer(("127.0.0.1", 0),
        lambda *a, **kw: Handler(*a, directory=str(serving["path"]), **kw))
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    port = server.server_port
    try:
        with sync_playwright() as playwright:
            browser = playwright.chromium.launch(channel="chrome", headless=True)
            try:
                context = browser.new_context(service_workers="block")
                page = context.new_page()
                for backend in BACKENDS:
                    run_phase(page, port, "A", backend, "write")

                page.goto("about:blank")
                serving["path"], second_digest = build("B", args.skip_build)
                assert second_digest != first_digest, "Second build must have distinct compiled output"

                for backend in BACKENDS:
                    evolved = run_phase(page, port, "B", backend, "read-evolved")["evolved"]
                    assert evolved == {
                        "id": "l1", "title": "Intro", "count": 3, "summary": None,
                        "scores": {"x": 1}, "cards": ["c1", "c2"],
                    }, evolved
                    retyped = run_phase(page, port, "B", backend, "read-retyped")
                    assert retyped["driftDetected"] is True, retyped
                    assert retyped["missOnOptIn"] is True, retyped
                    positional = run_phase(page, port, "B", backend, "read-positional")["positional"]
                    assert positional == {
                        "items": ["a", "b"], "scores": {"x": 1}, "tags": ["red"],
                        "grid": [["g1"]], "hooked": ["h"],
                    }, positional
                context.close()
                print("PASS: tolerant records across two minified builds", flush=True)
            finally:
                browser.close()
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


if __name__ == "__main__":
    main()
