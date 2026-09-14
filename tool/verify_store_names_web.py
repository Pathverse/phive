"""Build and exercise PHive naming in two minified releases at one origin.

Run: uv run --with playwright python tool/verify_store_names_web.py
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
OUTPUT = ROOT / ".dart_tool" / "store_names"
EXPECTED = {
    "namingparent", "namingcard", "autonamingcard", "cards_v1", "auto_cards_v1",
    "__ref_NamingParent_NamingCard", "__ref_NamingParent_AutoNamingCard",
    "cards_by_parent_v1", "auto_cards_by_parent_v1",
}


def build(variant, skip):
    destination = OUTPUT / f"web-{variant.lower()}"
    command = [
        shutil.which("flutter") or "flutter", "build", "web", "--release",
        "--no-web-resources-cdn", "--no-wasm-dry-run",
        "--target=lib/store_names_web.dart", f"--dart-define=PROOF_BUILD={variant}",
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


def inspect_storage(page):
    return page.evaluate("""async () => {
      const result = {};
      for (const info of await indexedDB.databases()) {
        result[info.name] = await new Promise((resolve, reject) => {
          const request = indexedDB.open(info.name);
          request.onerror = () => reject(request.error);
          request.onsuccess = () => {
            const db = request.result;
            const stores = Array.from(db.objectStoreNames);
            db.close();
            resolve(stores);
          };
        });
      }
      return result;
    }""")


def verify_names(storage, backend, extra_name):
    expected = EXPECTED | ({extra_name} if extra_name else set())
    if backend == "dynamic":
        for name in expected:
            assert storage.get(name.lower()) == ["box"], (
                f"Missing expected dynamic store {name.lower()}; actual: {storage}"
            )
    else:
        assert set(storage.get("naming_static", [])) == expected, (
            f"Static store names differ: expected {sorted(expected)}, actual: {storage}"
        )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--single-build", action="store_true", help="Focused RED/diagnostic run")
    parser.add_argument("--skip-build", action="store_true", help="Use existing outputs for diagnostics only")
    parser.add_argument("--expect-name", help="Add a deliberately missing name for a failure control")
    args = parser.parse_args()
    first, first_digest = build("A", args.skip_build)
    serving = {"path": first}
    server = ThreadingHTTPServer(("127.0.0.1", 0),
        lambda *a, **kw: Handler(*a, directory=str(serving["path"]), **kw))
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        with sync_playwright() as playwright:
            browser = playwright.chromium.launch(channel="chrome", headless=True)
            try:
                context = browser.new_context(service_workers="block")
                page = context.new_page()
                for variant in (["A"] if args.single_build else ["A", "B"]):
                    if variant == "B":
                        page.goto("about:blank")
                        serving["path"], second_digest = build("B", args.skip_build)
                        assert second_digest != first_digest, "Second build must have distinct compiled output"
                    for backend in ["dynamic", "static"]:
                        phase = "write" if variant == "A" else "read"
                        page.goto(f"http://127.0.0.1:{server.server_port}/?backend={backend}&phase={phase}")
                        page.wait_for_function("window.phiveResult !== undefined", timeout=90000)
                        result = page.evaluate("window.phiveResult")
                        storage = inspect_storage(page)
                        print(json.dumps({"report": result, "storage": storage}, sort_keys=True), flush=True)
                        assert result["build"] == variant and result["release"], result
                        assert result["runtimeType"] != "NamingCard", "Fixture was not minified"
                        assert result["ok"], result
                        verify_names(storage, backend, args.expect_name)
                context.close()
                print("PASS: minified storage naming" + (" (single build)" if args.single_build else " across two builds"), flush=True)
            finally:
                browser.close()
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


if __name__ == "__main__":
    main()
