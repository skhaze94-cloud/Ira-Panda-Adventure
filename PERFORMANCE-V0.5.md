# v0.5 graphics and performance verification

Local comparison on Windows, Godot 4.7.2 Compatibility/OpenGL, Intel Arc 140V,
1280×720. Each run used the same chapter viewpoints, music disabled and bats
removed to avoid combat changing the sample. Eight rendered warm-up frames,
then 24 rendered frames per chapter, VSync and frame cap disabled. The baseline
was the unmodified v0.4 ZIP with the same benchmark script added. v0.5 adds
scenic clearings and animations; geometry is therefore not identical.

These are short, fixed-view frame intervals measured through Godot's rendered
frame callback, not isolated GPU timings or a guarantee for every machine.
CPU scheduling, power state and shader warm-up affect repeated runs. Light and
Rich can overlap in short measurements; their budgets differ regardless.

| Chapter | v0.4 median ms | v0.5 Balanced median ms | Balanced p95 ms | Rich median ms | Light median ms | Draw calls v0.4 → Balanced |
|---|---:|---:|---:|---:|---:|---:|
| Whispering Woods | 72.31 | 3.79 | 4.46 | 3.64 | 3.71 | 2279 → 295 |
| Glowcap Glade | 83.56 | 3.58 | 4.25 | 4.66 | 4.23 | 2622 → 365 |
| Puddlebrook Crossing | 65.37 | 3.45 | 4.67 | 4.22 | 3.50 | 2041 → 258 |
| Stargazer Hollow | 67.25 | 3.17 | 4.72 | 3.36 | 3.36 | 1921 → 187 |
| Pillowmoon Garden | 56.98 | 2.94 | 3.83 | 3.11 | 3.53 | 1917 → 132 |

The five local views showed roughly 95% lower median frame intervals in
Balanced. This compares complete release rendering, including new clearings,
with the previous renderer. It does not isolate an individual optimization.
Godot's reported texture memory at chapter five changed from approximately
106.94 MiB to 99.93 MiB in Balanced (103.93 MiB in Rich). This is the texture
monitor, not total application memory.

## Changes responsible

- Full-screen ground shader replaces per-tile geometry and repeated light passes.
- Shared antialiased disc texture batches petals, shadows, glows and motes.
- Spatial tree chunks select visible sprites; the visibility cache tolerates small
  camera movement with a conservative margin.
- Native lights have limits of 2/3/5, with shadows and painted surface relief
  reserved for Rich. Motes use 12/24/40 and nearby creatures use limits of 8/16/24.
- Sparkles have a hard limit of 96. Scene ambience has 36 fixed world anchors.
- Unused legacy chapter backgrounds and whole NPC portraits are retained as
  assets but no longer loaded by the gameplay scene.

## Functional and visual verification

All five chapters passed original quest smoke tests, actual click walking to
required items/stations/exits, movement consistency at 30/60/120 simulation fps,
lantern discovery and healing checks, shadow clue alignment, and pause/reset
checks. v0.5 checks also passed forest culling coverage, graphics budgets,
unchanged quest state across quality changes, NPC facing/greetings, lantern
reactions, paused animation timers, gentler motion and graphics selector access.

OpenGL screenshots of five scenic stops, all three NPC rigs facing in both
screen directions across captures, the options screen and chapter completion
states were reviewed. The ZIP was imported and checked after fresh extraction.
Mobile hardware, physical touchscreen input, platform exports, listening tests
and Godot 4.3 were not tested in this release.

## Reproduce

Import the project first. Run `tests/benchmark.gd` in a rendered Godot session,
using `--disable-vsync --max-fps 0`. Set `IRA_BENCH_QUALITY` to `0`, `1` or `2`,
and `IRA_BENCH_OUTPUT` to an absolute JSON output path. Run each preset separately.
Raw measurements from this comparison are in `tests/benchmarks/`.
