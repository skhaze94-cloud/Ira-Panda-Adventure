# v0.3 Graphical Masterclass

Branch: `godot-4-v0.3-graphical-masterclass`.
Base: `dd7d48d8de27a9466139b6add3e351792aa7b2b3` (Living Woodlands).

The source branch had already advanced to v0.5. This separately named v0.3
edition preserves that newer gameplay and rendering foundation while applying
the requested graphical update. The original Godot branch and browser `main`
remain intact.

## Chapter review and changes

| Chapter | Visual work | Gameplay check |
|---|---|---|
| Whispering Woods | Shaded, swaying ferns; smoother canopy occlusion; irregular moss/trail borders; soft canopy shafts and an unfolding teaching bloom | Walk to the hidden birch key, reveal it and reach the exit |
| Glowcap Glade | Bell-shaped mushroom caps with shaded tops, luminous rims, stems and spots; textured butterfly wings | Navigate to and collect all three scroll pages, complete the station |
| Puddlebrook Crossing | Shader water at the crossing and all four pebble pools, animated wave glints, shoreline accents; lily props and reeds preserved | Collect driftwood, keep the unrepaired crossing blocked, then repair and cross |
| Stargazer Hollow | Continuous observatory rings with slowly orbiting lights; cooler mist and restrained highlight glow | Collect crystals and activate Moon → Star → Heart in order |
| Pillowmoon Garden | Shaded, veined flowers throughout beds and arches; butterfly wings; Ira's breathing animation at the reunion | Wake quest moonflowers, complete the music box and reach Ira |

All five chapters also receive continuous world-space terrain variation and
fine textile grain in Balanced/Rich. Terrain remains a single full-screen draw.
Existing painted PNG assets are retained; tiny foliage textures are built once
inside Godot and reused. No external asset generator or new image decoder is
required.

## Character and animation work

Ara's shoulders, torso and head now share one pose frame around the torso pivot.
Arm articulation remains local to that frame. Facing mirrors both the attachment
points and the artwork, and the native PointLight2D uses the same lantern-tip
transform. Walking bounce, breathing and lantern raising therefore stay aligned.
Ira has a subtle reunion breathing pose anchored at the feet.

Lantern blooms unfold over 0.8 seconds after their first awakening. Discovery,
healing and hint logic still happen immediately. Dialogue pauses the opening;
Gentler Motion displays the fully open bloom and freezes water, canopy shafts,
foliage sway and orbiting stars. Smooth spatial tree fading avoids abrupt opacity
changes when a canopy crosses the player.

## Native Godot rendering and quality

PointLight2D, LightOccluder2D, CanvasModulate and GPUParticles2D remain native
Godot effects. The existing Rich-mode surface normal reconstruction and lantern
shadows are preserved. GPU motes now use a soft radial texture.

A separate screen-reading CanvasLayer renders after the world and before the
HUD. Balanced has subtle colour grading and edge shading. Rich additionally
samples four neighbouring pixels to add restrained glow to bright highlights.
Light bypasses this screen pass and fine terrain grain. Existing budgets remain:
2/3/5 active lights, 12/24/40 GPU motes and 8/16/24 nearby creatures.

Water uses world-space procedural colour, moving waves and moonlight-like glints;
it does not reflect scene objects. Canopy shafts are an artistic canvas shader,
not a 3D volumetric simulation. This release remains a 2D painted adventure.

## Validation

Verified with Godot **4.3 stable**, the minimum advertised engine version:

- Fresh PNG import and startup; all source PNG signatures and decoding verified.
- Clean packaged ZIP extracted and imported with explicit directory entries.
- `tests/smoke.gd`: all five quests and chapter completions, zero failures.
- `tests/landscapes_controls.gd`: actual navigation to quest objects, bridge
  gating, movement frame rates, touch release, pause and input buffering pass.
- `tests/lantern.gd`: all five discovery/healing/clue loops pass.
- `tests/graphics_v05.gd`: quality budgets, forest culling, NPC reactions and
  paused animation behaviour pass.
- `tests/masterclass.gd`: mirrored lantern attachment, rigid shoulder frame,
  bloom timing/pause, water alignment, finish quality and Gentler Motion pass.
- Native OpenGL captures: five chapters × three qualities × two character poses,
  plus initial left/right and completed bridge/garden checks. No shader compile
  or rendering errors were reported. The software display only reports that
  changing V-Sync mode is unsupported.

Reproduce logic checks after importing:

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/landscapes_controls.gd
godot --headless --path . --script res://tests/lantern.gd
godot --headless --path . --script res://tests/graphics_v05.gd
godot --headless --path . --script res://tests/masterclass.gd
```

For visual checks, run `tests/capture_masterclass.gd` with a real display and
`IRA_CAPTURE_DIR` set to an output directory. It captures all three quality
settings, both facing/lantern poses, and the five authored scenic views.

## Performance and limits

Foliage initially used per-petal polygons. Profiling found 1,272 draw calls in
the garden test view. Reusable shaded petal and flower textures replace those
polygons and repeated flower-centre draws, reducing that view to **155 draw calls**.
The inherited base view uses 132. They are cached by the small authored
colour palette, with no new per-frame node creation.

[Masterclass report](tests/benchmarks/masterclass-balanced.json) and
[base report](tests/benchmarks/masterclass-base-balanced.json) use Godot 4.3, Compatibility, 1280×720 and Mesa
llvmpipe software rendering. They measure 24 frames after eight warmup frames.
They are diagnostic measurements on a CPU renderer, not hardware FPS targets.
The base run had cold driver-cache timing spikes; draw-call counts are the useful
comparison here. These runs do not establish a frame-time improvement.
Phone/tablet performance and Vulkan renderers have not been measured. Choose
Light on slower devices; hardware profiling is still needed before making an
FPS promise. Historical v0.5 benchmark numbers used another engine/environment
and should not be compared to these reports.
