#!/usr/bin/env python3
"""Run the game's integration suites and retain a concise, reproducible report."""
from pathlib import Path
import argparse
import datetime
import json
import os
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument("--godot", required=True)
parser.add_argument("--report", default="tests/benchmarks/keepsake-validation.json")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
env = os.environ.copy()
env["IRA_SAVE_PATH"] = "off"
suites = [
    "smoke", "landscapes_controls", "lantern", "quests_captions", "masterclass",
    "pathways", "graphics_v05", "personality_v06", "living_woodland",
    "hidden_wonders", "object_upgrade", "keepsake",
]
results = []
for suite in suites:
    begin = time.monotonic()
    run = subprocess.run([
        args.godot, "--headless", "--path", str(root), "--script", f"tests/{suite}.gd",
    ], cwd=root, env=env, capture_output=True, text=True, timeout=180)
    output = run.stdout + run.stderr
    errors = [line for line in output.splitlines() if "ERROR:" in line]
    result = {
        "suite": suite, "exit_code": run.returncode,
        "seconds": round(time.monotonic() - begin, 2),
        "passed": run.returncode == 0 and not errors,
        "evidence": [line for line in output.splitlines() if
                     "FAILURES:" in line or "CHECKED CHAPTER" in line or
                     "KEEPSAKE LAYOUT" in line or "UPGRADE CHAPTER" in line],
        "errors": errors,
    }
    results.append(result)
    print(f"{'PASS' if result['passed'] else 'FAIL'} {suite}: {result['seconds']}s", flush=True)
    if not result["passed"]:
        print(output, flush=True)
report = {
    "version": "0.10.0", "engine": "Godot 4.3.stable.official.77dcf97d8",
    "checked_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "passed": all(r["passed"] for r in results), "suites": results,
    "scope": "Native headless integration; OpenGL visual capture is checked separately.",
}
destination = (root / args.report).resolve()
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_text(json.dumps(report, indent=2) + "\n")
print(f"{sum(r['passed'] for r in results)}/{len(results)} suites passed", flush=True)
raise SystemExit(0 if report["passed"] else 1)
