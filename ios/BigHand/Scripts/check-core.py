#!/usr/bin/env python3
"""Check pure game logic on the host. This does not build or verify the iOS app."""
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
sources = sorted((root / 'Models').glob('*.swift'))
sources += [root / 'Game' / (name + '.swift') for name in ['CollisionSystem', 'DifficultySystem', 'GateSystem', 'Economy', 'SpawnSystem']]
sources += [root / 'Services/SaveService.swift', root / 'Tests/CoreChecks.swift']
runner = '\n'.join(path.read_text() for path in sources)
runner += '''
let checks: [(String, () throws -> Void)] = [
    ("crush eligibility and swept contact", CoreChecks.crushEligibility),
    ("growth and visual cap", CoreChecks.growth),
    ("gate modifiers", CoreChecks.gates),
    ("upgrade effects and purchase rules", CoreChecks.upgrades),
    ("coin rounding and reward ledger", CoreChecks.coins),
    ("difficulty thresholds and speed", CoreChecks.difficulty),
    ("save model and UserDefaults", CoreChecks.persistence),
    ("4,800 connected spawn rows", CoreChecks.spawning)
]
for (name, check) in checks {
    do { try check(); print("PASS: " + name) }
    catch { fatalError("FAIL: " + name + ": " + String(describing: error)) }
}
print("Core logic checks passed. iOS build, XCTest, and simulator launch remain separate checks.")
'''
swift = shutil.which('swift')
if not swift:
    raise SystemExit('Swift is required for core checks.')
with tempfile.TemporaryDirectory(prefix='bighand-core-') as directory:
    scratch = Path(directory)
    script = scratch / 'main.swift'
    script.write_text(runner)
    subprocess.run([swift, '-swift-version', '6', '-module-cache-path', str(scratch / 'cache'), str(script)], check=True)
