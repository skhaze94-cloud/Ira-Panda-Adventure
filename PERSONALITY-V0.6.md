# v0.6 — Little Paws, Big Personality

Based on v0.5 commit `dae5880`, on `godot-4-v0.6-little-paws-big-personality`.

## Character and sound

Ara's shared body frame keeps the arms and lantern attached during every pose.
Wood crossings add balancing arms and a gentle lean; stepping stones add small
hops and slower, deliberate steps. Pickups crouch, bridge building hammers,
discoveries celebrate, and bat contact briefly startles. Gentler Motion keeps
all actions functional while suppressing decorative pose motion.

Twenty original synthesized mono WAV clips add grass/wood/stone footsteps,
a proximity-faded looping stream, glow and discovery chimes, bridge building,
web sparkles, character voice motifs, three rune notes and a music-box lullaby.
Effects use a bounded eight-voice pool. Music and woodland sounds have separate
persistent switches; voice motifs are nonverbal, not spoken dialogue.

## Clearer woods and integrated crossings

Foliage fades around nearby quest items, characters, the station, the spider
and secret spots as well as Ara. Focus positions are collected once per draw.
Bridges have grain, moss and shadows; stepping stones have irregular textured
surfaces, lifted edges and moss. Logs have bark scoring and growth rings.
The art and navigation still share the same crossing geometry. Stone gaps are
visual: the crossing is forgiving and never unexpectedly drops Ara into water.

## Ten optional discoveries

Two short woodland loops in every chapter branch off and rejoin the trail.
Wooden arrow signs and the ground shader mark these routes. Each themed spot
adds a caption, celebration and one missing heart on its first visit.

| Chapter | Optional discoveries | Chapter moment |
|---|---|---|
| Whispering Woods | Acorn Picnic; Ribbon Chimes | Gold motes swirl around the birch key reveal |
| Glowcap Glade | Moth Tea Party; Spore Wishes | Caps respond to glow; the smiling spider remains after its web dissolves |
| Puddlebrook Crossing | Pebble Ducks; Willow Chimes | Bridge planks appear during Ara's building pose |
| Stargazer Hollow | Pocket Observatory; Fallen-Star Bench | Rune notes and luminous constellation links follow Moon → Star → Heart |
| Pillowmoon Garden | Biscuit Nook; Sister's Ribbons | The lullaby grows near the cottage; the sisters move together behind a small end card |

These loops never gate a quest. Entrances and exits are protected from logs and
boulders. Stream crossings sit clear of the optional loops.

## Controls and continuity

A compact translucent HUD and illustrated glow, interact and pause buttons
leave more room for the woods. The paw stick owns one touch pointer, ignores
extra fingers, and releases outside its bounds. Keyboard and tap-to-walk remain
available. Menu and options were inspected at 1280 × 720 and 854 × 480.

A versioned local JSON checkpoint saves on quest progress, discoveries, chapter
transitions, pause, returning to the title, and every twelve seconds in play.
Continue restores location, hearts, quest objects, NPC meetings, rune order,
lantern discoveries, cleared web and optional discoveries. Invalid blocked
locations fall back to the chapter start. Preferences persist independently;
starting again requires an explicit choice and keeps those preferences.

Writes use a temporary file and rotate a last-good backup. Loading skips
malformed or oversized files and tries the backup. The save is
`user://ira-adventure-v06.json`; it is local to this installation, not cloud sync.
A completed adventure can be continued near the cottage and replay its reunion.

## Performance and verification

Navigation prepares quarter-tile clearance cells over frame slices with a
2 ms target, including optional routes. Tap requests can wait for preparation;
keyboard input remains available and cancels a pending destination. The same
nine-point clearance checks prevent corner clipping. This reduces a long cold
navigation stall by spreading work; it does not eliminate the total work.

Godot 4.3 was tested with Compatibility rendering. Eight suites passed:
smoke, actual five-chapter navigation/controls, pathways, lantern discoveries,
character/graphics, quests/captions, v0.5 graphics, and new personality/save/touch
checks. New checks walk every optional loop and rejoin, verify one-time rewards,
repair progression, quiet poses, outside touch release, backup recovery,
persisted preferences and chapter-transition checkpoints. Native visual capture
also exercised actual audio frames, mute and the voice pool.

The native captures and benchmark used Mesa llvmpipe software rendering at
1280 × 720. Recorded balanced frame medians were about 42–59 ms, with scene
draw CPU snapshots about 1.3–3.1 ms. Navigation request measurements were about
2.5–9.2 ms; maximum observed slices were about 2.2–8.5 ms under concurrent host
work. The v0.5 synchronous builds took about 456–612 ms on this host.
Scheduling can exceed the slice target. Raw reports live in
`tests/benchmarks/personality-balanced.json`, `personality-navigation.json`
and `v05-navigation-baseline.json`. These are development-host measurements,
not phone FPS guarantees. Physical mobile hardware testing remains outstanding.

The release ZIP excludes imported caches and includes explicit directory
entries for Godot Project Manager import. A fresh extraction must finish its
asset import before running. Source assets remain PNG and WAV, retaining the
previous image-import fixes.
