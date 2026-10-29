# Reliability validation · v0.11.1

All 14 automated checks pass with zero reported engine errors or leaked instances in their final logs. These cover all five chapters, movement, quests, lanterns, controls, graphics contracts, character behaviour, hidden discoveries, object interactions, storybook UI and persisted saves.

## Fixes

- Explicitly stop and detach music streams as the scene closes; allow the automated audio test 200 ms for the mixer to release pending playback before terminating the engine.
- Preserve the Larger Text preference through viewport changes and dialogue layout.
- Restore normal story-card margins when returning from a short viewport, and avoid replacing an unchanged style on every layout call.
- Clamp restored audio volume preferences to supported slider bounds.

## Save and recovery evidence

On every chapter, a disk round-trip preserves chapter, position, hearts, quest count, discoveries, audio volume and larger-text preferences. Corrupt-primary recovery restores the last-good backup. Starting over preserves preferences. An unwritable save path is reported as a failure. Tests use an isolated save filename and remove their files afterward.

## Performance measurements

Godot 4.5.1, 1280×720, GL Compatibility, Mesa llvmpipe software rasterization. Thirty frames were sampled after eight warm-up frames in each chapter at Balanced and Rich quality. No capture or other test process ran concurrently with this profiling pass.

| Chapter | Quality | First frame (ms) | Median frame (ms) | p95 frame (ms) | p95 script drawing (ms) |
| --- | --- | ---: | ---: | ---: | ---: |
| 1 | Balanced | 692.9 | 113.2 | 158.9 | 4.5 |
| 1 | Rich | 692.9 | 154.5 | 185.1 | 2.9 |
| 2 | Balanced | 757.7 | 110.3 | 173.2 | 2.6 |
| 2 | Rich | 757.7 | 148.5 | 169.9 | 5.8 |
| 3 | Balanced | 554.3 | 102.8 | 263.0 | 7.4 |
| 3 | Rich | 554.3 | 194.5 | 246.6 | 4.9 |
| 4 | Balanced | 503.0 | 128.6 | 191.5 | 5.4 |
| 4 | Rich | 503.0 | 175.9 | 241.4 | 2.7 |
| 5 | Balanced | 611.3 | 96.5 | 279.9 | 6.0 |
| 5 | Rich | 611.3 | 102.5 | 202.8 | 1.6 |

These software-rendered full-frame times are slow and do not establish acceptable gameplay frame rates on a target device. The comparatively small script-drawing times suggest software rasterization is a major cost; that interpretation is an inference, not a GPU diagnosis. A representative target GPU/phone benchmark remains required before claiming a frame-rate target.

The navigation-request check passes its existing 30 ms budget in all chapters. Original art, sound files, shaders and effect quality are preserved. This validation profiles one starting viewpoint per chapter, not every possible gameplay state.

## Reproduce

Import project.godot with the Godot editor first. Run headless scripts under tests/ for functional checks with IRA_SAVE_PATH=off; reliability_v011.gd temporarily uses and cleans its own isolated disk save. Run tests/profile_reliability.gd with a real renderer and IRA_CAPTURE_DIR set to a writable output folder to reproduce rendering measurements. tests/benchmarks/storybook-validation.json contains all results and exact timings.
