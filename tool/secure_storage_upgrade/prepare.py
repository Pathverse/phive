#!/usr/bin/env python3
"""Prepare a disposable Android app; never changes an existing consumer app."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('workspace', type=Path)
parser.add_argument('--version', choices=['10.3.4', '11.2.0'], required=True)
args = parser.parse_args()
workspace = args.workspace.resolve()
repo = Path(__file__).resolve().parents[2]
if not workspace.exists():
    subprocess.run([
        'flutter', 'create', '--empty', '--platforms=android',
        '--project-name', 'phive_storage_upgrade', '--org',
        'dev.phive.acceptance', '--no-pub', str(workspace),
    ], check=True)
if 'name: phive_storage_upgrade' not in (workspace / 'pubspec.yaml').read_text():
    raise SystemExit('Refusing to modify a workspace with a different project name')
(workspace / 'pubspec.yaml').write_text(f'''name: phive_storage_upgrade
publish_to: none
version: 1.0.0+1
environment:
  sdk: ^3.11.0
dependencies:
  flutter:
    sdk: flutter
  flutter_secure_storage: {args.version}
  path_provider: ^2.1.5
  phive: ^0.8.0
  phive_barrel:
    path: {json.dumps(str(repo / 'phive_barrel'))}
dependency_overrides:
  phive:
    path: {json.dumps(str(repo / 'phive'))}
''')
shutil.copyfile(Path(__file__).with_name('main.dart'), workspace / 'lib/main.dart')
subprocess.run(['flutter', 'pub', 'get'], cwd=workspace, check=True)
