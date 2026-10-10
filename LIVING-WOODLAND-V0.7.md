# v0.7 — The Living Woodland

Built on v0.6 commit `d116803`, on `godot-4-v0.7-living-woodland`.

## Neighbours with routines

Pip flutters and greets, Bramble walks a small safe circuit while checking his
clipboard, and Moss tends a mushroom with a little watering can. Each stops
working and turns toward Ara when she approaches. Greetings have a cooldown;
returning after finishing a quest or finding the key brings a celebratory pose
and a small completion tick. Existing quest dialogue remains intact, with an
extra chapter-specific line when Ara has found a clue left by Ira.

NPC movement stays within one world unit of its original home, checks terrain,
and freezes during dialogue. Gentler Motion keeps neighbours at home and
suppresses routine motion while retaining facing, dialogue and quest reactions.

## Woodland play

One group of five fireflies in each chapter invites Ara from the first optional
trail entrance. It moves along that loop, waits when she falls behind, and
settles in the clearing. It never gates progress. Six leaf piles in each chapter
scatter gently on approach or movement, with a cooldown that prevents continuous
rustling while standing still. One rabbit, moth or frog near the second clearing
notices Ara and leans or moves a small safe distance toward her.

Stargazer Hollow has three musical pebbles along an optional trail. Stepping
near one plays its note and lights it; lantern glow can sound a small chord.
These toys do not affect the Moon → Star → Heart quest sequence. Quiet motion
uses static feedback instead of flying leaves, moving creatures or rising notes.

## Ira's trail

Three nonblocking clues in every chapter suggest that Ira has passed through.
Ribbons, little pillow-shaped prints and biscuit crumbs become warmer and more
hopeful toward Pillowmoon Garden. Approach discovers each once, plays a chime,
and presents one short Ara caption. The compact HUD counts the three clues.
They do not replace quest items or add requirements to the woodland door.

Continue persists discovered clues and completed guides. The existing version-1
checkpoint format and `user://ira-adventure-v06.json` path remain in use, so
v0.6 saves load with fresh flags for the new optional encounters. Leaf rustles,
NPC routine positions and visitor attention are transient and reset on load.

## Atmosphere and resource budgets

Lighting, mist and rays interpolate gradually near clearings, streams and the
cottage. Ground tint follows the same woodland state; the cottage adds a gentle
warmth. A new original five-second WAV bed layers quiet leaf air and distant
bird phrases beneath the music, fades near water and home, and respects the
Woodland Sounds switch. The existing stream bed and eight-voice effects pool
remain bounded. No new light nodes are allocated: fireflies use an existing
light slot within each quality tier's budget.

Each chapter has fixed pools of three clues, six leaf piles, one guide and one
visitor, plus three musical pebbles only in chapter four. Art is native Godot
CanvasItem drawing using the existing woodland palette and atlas. Foreground
foliage fades more broadly to keep Ara and nearby encounters readable.

## Verification

Nine suites cover all five chapters: smoke, real chapter navigation and controls,
pathway crossings, lantern discoveries, character/graphics, quests/captions,
v0.5 graphics, v0.6 personality/save/touch, and the new living woodland suite.
The new suite walks to all fifteen clues, checks guide waiting and arrival,
one-time discoveries, leaf cooldown and standing behavior, safe NPC routines,
quiet motion, visitor reactions, gradual atmosphere, pause freezing, new-save
restoration and v0.6 checkpoint compatibility. The inherited suites also verify
all required quests and exits remain reachable.

Native visual capture checks the title, NPC routines and greetings, all chapters'
clues, guides and visitors, musical pebbles, leaves, cottage warmth and compact
854 × 480 controls. Actual audio frames verify the eight-voice pool, 21 loaded
clips, ambient playback and immediate mute. Logs are checked for script errors,
resource leaks and import failures as well as assertion results.

Balanced benchmarks use Godot 4.3, Compatibility rendering, 1280 × 720 and Mesa
llvmpipe software rendering. The recorded sample has frame medians around
40–56 ms and draw CPU snapshots around 1.3–3.4 ms. These are comparable to the
included v0.6 host samples, with no texture-memory increase in those views;
variation between runs is expected. Reports are in `tests/benchmarks/living-balanced.json`
and `living-navigation.json`. This is development-host profiling, not a phone
FPS claim; physical mobile performance testing still requires a device.

The Godot-ready ZIP contains source PNG/WAV assets and explicit folders, excludes
import caches, and is checked by fresh extraction, import and runtime smoke.
