#!/usr/bin/env python3
"""Run a real Godot/OpenGL capture in a private Xvfb display (Linux QA only)."""
from pathlib import Path
import argparse
import os
import socket
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument("--godot", required=True)
parser.add_argument("--xvfb", required=True)
parser.add_argument("--xvfb-library")
parser.add_argument("--script", default="tests/capture_keepsake.gd")
parser.add_argument("--output", required=True)
parser.add_argument("--timeout", type=int, default=180)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
output = Path(args.output).resolve()
output.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
if args.xvfb_library:
    env["LD_LIBRARY_PATH"] = args.xvfb_library
env["IRA_SAVE_PATH"] = "off"
env["IRA_CAPTURE_DIR"] = str(output)
env["DISPLAY"] = "127.0.0.1:196"
with (output / "display.log").open("w") as log:
    display = subprocess.Popen([
        args.xvfb, ":196", "-screen", "0", "1600x1000x24", "-ac",
        "-nolisten", "unix", "-nolisten", "local", "-listen", "tcp",
        "-xkbdir", "/usr/share/X11/xkb",
    ], env=env, stdout=log, stderr=log)
    try:
        for _ in range(40):
            try:
                with socket.create_connection(("127.0.0.1", 6196), timeout=.2):
                    break
            except OSError:
                if display.poll() is not None:
                    raise RuntimeError("Xvfb exited; see display.log")
                time.sleep(.15)
        else:
            raise RuntimeError("The private capture display did not start")
        code = subprocess.run([
            args.godot, "--path", str(root), "--rendering-method", "gl_compatibility",
            "--audio-driver", "Dummy", "--script", args.script,
        ], env=env, cwd=root, timeout=args.timeout).returncode
    finally:
        display.terminate()
        display.wait(timeout=5)
raise SystemExit(code)
