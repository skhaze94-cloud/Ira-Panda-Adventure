# Ara the Panda: Quest to Find Ira — Godot v0.2.2

**Moonlight & Woodland Depth** upgrades all five chapters from the supplied
Godot v0.1 project, with native lights and shadows, textured relief shading,
moonlit mist, motes, livelier characters and a corrected panda arm rig.

## Import fix in v0.2.2

This archive has `project.godot` directly at its root, rather than inside an
extra wrapper folder. Explicit directory records are written before their files, so Godot can create
`assets/`, `scenes/`, `scripts/`, `shaders/`, `tests/` and `tools/` during ZIP import.
The previous ZIP lacked those directory records: normal archive extraction
created the folders automatically, but Godot's package importer did not. All 33 WebP textures are now lossless RGBA PNGs,
with the same dimensions, colors and alpha channels. Runtime asset paths were
updated. No Godot cache or stale import sidecars are included.

**Recommended on Windows:** right-click the ZIP → **Extract All**, choose a
new writable folder such as `Documents/Ira-Panda-v0.2.2`, then open Godot
Project Manager → **Import** → select that folder's **project.godot**.
If importing the ZIP directly, choose a new empty writable destination folder.
Avoid the partially extracted folder from the failed import.

## Open and play

1. Use Godot **4.3 or newer**, with the **Compatibility** renderer.
2. Extract this ZIP. Import `project.godot` in Godot Project Manager.
3. Allow the image/audio imports to finish, then press **F5**.

| Action | Keyboard | Touch / mouse |
|---|---|---|
| Move | WASD / arrows | Direction buttons or tap the path |
| Lantern | Space | GLOW |
| Talk / interact | E | INTERACT / TALK near a guide or quest station |
| Pause | Escape | Pause button |
| Story | Enter / Space | Next Page / Skip |

Options include music and Reduced Motion. All five quests and the original
storybook panels remain included. Ara is the panda; Ira is her pillowcase sister.

## What's new

- Native player and woodland lantern lighting, including filtered trunk shadows.
- Gentle texture relief, soft contact shadows, drifting mist and moonbeams.
- Chapter-specific ground details, atmosphere and quest-object lights.
- Visible brook, repair materials before bridge completion and repaired crossing.
- Whole-rig mirroring and better shoulder attachment; the light follows the arm.
- NPC wandering/leaning, canopy sway, floating motes and smooth camera following.
- Continuous decorative ground at map edges and fixes for Godot 4.3 load errors.

See `REVIEW-V0.2.md` for the chapter-by-chapter review and validation limits.
This is a native **2D** Godot project with stylized depth, not a 3D mesh conversion.
Original bitmap artwork is retained; shaders enhance its lighting and texture.

## Developer checks

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/smoke.gd
```

`tests/capture.gd` needs a real rendering display and writes chapter images to
`user://v02-captures` inside Godot's application data folder. Run it with:

```sh
godot --path . --script res://tests/capture.gd
```

The tests passed on Godot 4.3. Mobile exports, physical touch controls, audio
playback and target-device performance still need a device playtest.

This PNG compatibility fix is included on the `godot-4-v0.2-moonlight-depth` branch. The browser game remains on `main`.

The v0.2.2 archive was extracted using Godot ZIPReader with the Project Manager
folder-creation behavior: 58 files, zero extraction failures. Editor import
and all five quest smoke checks passed on that fresh extraction.
