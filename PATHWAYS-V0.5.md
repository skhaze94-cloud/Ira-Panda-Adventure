# v0.5 — The Wandering Woodlands

The pathways update builds on v0.4 Little Talks, Big Adventure (`2ca7e8d`), on
`godot-4-v0.5-pathways`. The browser version and previous release branches are
preserved.

## Five redesigned journeys

| Chapter | Travel additions |
|---|---|
| Whispering Woods | Sweeping woodland turns, mossy fallen logs, a plank footbridge and stepping stones; the blue side trail still leads to the birch key. |
| Glowcap Glade | Deeper violet woodland bends, boulders, stepping stones, a fallen-log crossing and a friendly silvery spiderweb clearing. |
| Puddlebrook Crossing | Willowbank turns, two scenic crossings, logs to weave around and a separate broken bridge repaired with the three original driftwood bundles. |
| Stargazer Hollow | S-shaped woodland approaches, boulders, a stone crossing and a rope-railed bridge before the open constellation hollow. |
| Pillowmoon Garden | Winding blossom woods, mossy logs, a footbridge and a fallen-log crossing before the moonflowers and cottage reunion. |

The authored centerlines are about 14–28% longer than the direct start-to-exit
line. Local obstacles and bridge lanes add small detours. Lanterns, NPCs, quest
items, landmark scenery and hidden discovery trails follow the new route.

## Travel and presentation

- Eleven animated stream crossings in total, including the repaired quest bridge.
  Water is blocked away from the crossing lane. Ara never needs to swim or jump.
- Plank decks with rope rails, rounded stone treads, and bark-striped log decks
  drawn with Godot CanvasItem geometry over the native water shader.
- Three physical logs/boulders per chapter, positioned away from quest objects,
  guides and river approaches. Ara can walk around either end.
- The spiderweb slows nearby travel gently. Space/GLOW clears it without damage,
  with a short dissolve and sparkle burst. It never hard-locks a quest.
- Small discovery captions celebrate the first visit to each crossing. Repeated
  crossings do not repeat them; restart resets discoveries.
- Gentler Motion freezes water/ambient motion and completes the web dissolve
  immediately. Conversations still pause travel and its animations.

Pathways owns route offsets, obstacle positions and crossing lanes. The shader
receives those offsets and stream dimensions from the same data. Collision,
keyboard movement and click/tap navigation use the authored geometry. Navigation
uses a quarter-tile grid with extra corner clearance, tests only the playable
corridor, and rebuilds after repairing the final brook bridge. Click-following
lands precisely at bends instead of carrying momentum into the river bank.

All five original quests, NPC conversations, comics, music, lantern discoveries,
Ara's shared body rig and the v0.3 graphical effects remain included. Existing
PNG assets are reused; there are no additional WebP imports or downloads.

## Validation

Godot 4.3 stable, Compatibility renderer:

- `smoke.gd`: all assets, spawns, quest items, stations and chapter completion.
- `landscapes_controls.gd`: actual walking to every required quest object and
  exit, key/scroll/driftwood/crystal/flower collection, rune order, repaired
  bridge gate, keyboard direction, frame-rate independence and pause reset.
- `pathways.gd`: actual travel across each scenic crossing in both directions,
  blocked water, colliding obstacles, protected objectives, winding distance,
  web slowdown/clearing/dissolve/Gentler Motion and restart resets.
- `lantern.gd`, `masterclass.gd`, `graphics_v05.gd`, `quests_captions.gd`:
  inherited discovery, graphics, rig, animation and conversation behavior.
- `capture_pathways.gd`: 20 native OpenGL screenshots covering all chapters,
  both scenic crossings, obstacles, spiderweb and repaired brook bridge.
- ZIP is extracted into a clean folder and freshly imported before delivery.

Native graphics reviewed with Mesa llvmpipe software OpenGL. This checks
rendering, not phone performance. Physical mobile devices and portrait layouts
have not been tested; this is a landscape Godot project.

## Import

Extract the ZIP, import `project.godot` in Godot 4.3 or newer with Compatibility,
wait for asset import, then press F5. Explicit ZIP folder entries are included
for Godot Project Manager. Runtime import caches are excluded.
