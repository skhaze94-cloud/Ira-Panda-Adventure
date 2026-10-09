# v0.2 — Moonlight & Woodland Depth

All five chapters were reviewed against the supplied v0.1 project. The story,
quests and original artwork are preserved; the visual rendering and rig have
been upgraded in native Godot.

| Chapter | Finding | v0.2 improvement |
|---|---|---|
| 1 — Whispering Woods | Lamp halos did not illuminate the ground or cast shadows; the hidden-key area needed a cooler accent. | Warm native lantern lights, blue birch-trail light, tree-trunk shadow occluders, leaf accents and cool moonlit mist. |
| 2 — Glowcap Glade | Strong violet artwork needed warm contrast and more environmental life. | Violet atmospheric grading, warm light on the path, small glowcaps, luminous quest-object lights and floating motes. |
| 3 — Puddlebrook Crossing | The bridge quest had no clearly rendered brook; a finished bridge was visible before repair. | A rendered animated brook, a driftwood repair marker before completion, and a bridge drawn over the crossing after repair. Cooler light and denser mist distinguish this chapter. |
| 4 — Stargazer Hollow | Rune activation had limited lighting feedback. | Star-flecked ground, lavender air and blue rune lights that turn warm when activated. The Moon–Star–Heart order remains intact. |
| 5 — Pillowmoon Garden | The map's diamond edge exposed the background near the finale; the garden needed warmth. | Continuous decorative ground beyond the playable boundary, warmer ambient light, small petal clusters, moonflower lights and a softly illuminated cottage exit. |

## Character and depth work

- Ara is the panda; Ira is her pillowcase sister. The repaired rig is Ara's.
- Mirroring now transforms the entire rig's attachment positions and rotations
  together. Previously, each crop flipped while shoulders stayed on fixed sides.
- The ordinary and lantern arms attach inside the body silhouette, with adjusted
  shoulder pivots and restrained swings. The native lantern light follows the
  articulated arm tip, including its walking and glow animation.
- NPCs gently wander near their home positions, bob and lean more when Ara is
  nearby. Tree canopies sway around their grounded trunks.
- Softer layered contact shadows, trunk occluders, textured relief shading,
  foreground tree transparency and a gently easing camera improve the 2D depth.
- Reduced Motion suppresses new idle motion, fireflies, fog animation, light
  flicker and camera easing. Gameplay glow feedback remains available.

## Native rendering implementation

`PointLight2D` lights and `CanvasModulate` provide actual scene illumination.
The player's lantern casts filtered shadows from a bounded pool of nearby
trunk occluders. Up to 12 lights and 36 occluders are reused rather than making
thousands of nodes across the generated maps. Quest and nearby lamp sources
are selected by distance.

`stitched_surface.gdshader` reconstructs subtle normals from the existing
textures for relief under the lights. This is a stylized texture-derived normal,
not a hand-authored normal map or a conversion to 3D meshes.
`moonlit_air.gdshader` adds drifting layered mist, soft moonbeams and a vignette.
Native GPU particles provide gently fading motes. HUD and dialogs use a separate
canvas so they remain bright and readable.

HTML/WebGL can also support sophisticated effects. This update uses Godot's
native lighting, shadow, shader and particle pipeline instead of the previous
flat drawn halos; the effects are not inherently impossible in a browser.

## Validation

- Godot 4.3 editor import and GDScript parsing passed.
- Five-chapter automated smoke test passed with zero failures: clear spawns,
  sampled main-path collision checks, collectible positions, key reveal and
  collection, all three collectibles per later chapter, bridge/scroll/lullaby
  station completion, ordered runes and chapter transitions.
- OpenGL Compatibility rendering ran successfully under Mesa software
  rendering, with no shader compilation or gameplay-script errors.
- Screenshots of all five chapters, with Ara facing right and left, were visually
  inspected. Further captures checked the garden boundary and brook correction.
- v0.1's untyped array-derived variables and missing base story callback were
  fixed because they produced Godot 4.3 parse errors.

These checks are not a complete human playthrough. Audio was disabled during
render checks, and physical touchscreen use, mobile performance, Android/iOS
exports and device-specific drivers still require testing.

## Remaining opportunities

The art remains 2D and the terrain still uses repeated atlas tiles. A later
update can add hand-painted terrain transitions, bespoke foliage normal maps,
NPC articulated rigs and larger authored landmarks. Browser save migration is
still absent. This version does not claim release certification or native 3D
models.
