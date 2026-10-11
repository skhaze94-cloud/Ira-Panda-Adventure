# Hidden Wonders — Godot v0.8

A beauty and exploration refresh across all five chapters, built on v0.7.

## Room for curious paws

The deterministic forest generator removes 42% of eligible tree placements
before carving the new alcoves. Three four-point loops per chapter add fifteen
secret routes, with generous clear floors and entrances marked by tiny stars.
New foliage mixes with the original trees. Nearby trees fade around Ara and
important objects; the birches at the key now fade as she approaches too.

Paths use the textured ground shader, with a narrower, gently warm edge for
side trails. Native depth sorting keeps new plants, trees, chests, landmarks,
Ara and neighbours in the right order. Existing light pools, rippling streams,
relief shading, mist and living woodland routines remain active.

| Chapter | New tree | New plants | New chest | New landmark |
|---|---|---|---|---|
| Whispering Woods | Silver birch | Ferns and daisies | Wood and copper | Acorn stump |
| Glowcap Glade | Violet mushroom tree | Blue glowcaps | Lilac velvet and brass | Moth-flower bush |
| Puddlebrook Crossing | Jade willow | Reeds and water lilies | Driftwood | Mossy river boulder |
| Stargazer Hollow | Silver rowan | Silver starflowers | Moonstone and gold | Crystal crescent arch |
| Pillowmoon Garden | Blush cherry | Moonflowers | Ivory quilt and heart | Biscuit bench |

These twenty illustrated assets are five original transparent PNG sheets.
Godot draws alpha-bounded regions directly from unchanged source images.
Prompts and saved asset paths are in [ASSET-PROMPTS-V0.8.md](ASSET-PROMPTS-V0.8.md).

## A gentle treasure hunt

Every chapter has eighteen stars and three themed chests. One chest holds the
brass key, scroll page, driftwood bundle, star crystal or moonflower required
for that chapter. Stars lead off the main road. Nearby chests sparkle; lantern
glow makes their clasps glimmer more clearly. E / OPEN CHEST opens them with
a hinge animation and a little celebration. Then approach the quest item,
or shine to wake the moonflower. Neighbours explain this in one short caption.

Stars give 10 points each, chests give 40, and the required chapter quest gives
100: **400 points earns a woodland crown**. There are no speed or heart bonuses,
and no penalty for trying again. Optional treasure never blocks story progress.

CHAPTERS on the title screen opens a scrolling album with best scores and
crowns. Previously visited chapters can be replayed; choosing one warns that
it replaces the current checkpoint. Cancel preserves progress. Best scores
and unlocked chapters survive replay and New Adventure.

Continue restores stars, chests, lid states and crown announcements. Completed
quest items in v0.6/v0.7 checkpoints automatically retain an opened chest, so
old progress remains playable. Gentler Motion opens lids immediately, stops
star bobbing and keeps all routes and collectibles usable. Pause freezes them.

## Validation

Godot 4.3 Compatibility import and ten runtime suites cover required quests,
actual walking routes, bridge approaches, optional discoveries, caption input,
quality settings, save recovery, touch controls and the new treasure hunt.
The new suite walks all fifteen loops, opens all fifteen chests and collects
all ninety stars. It checks closed-chest quest gating, 400-point crowns,
repeat-pickup protection, Continue, legacy saves, chapter replay, cancel,
unvisited chapter locks, Gentler Motion and pause.

Native rendered captures cover every chapter's closed/open chest and star
trail, plus the chapter album, title and pause at a compact 854×480 viewport.
All new source assets are PNG; the distributable excludes engine import
caches and includes explicit directory records for Project Manager ZIP import.
Desktop software-rendered QA is not a phone performance certification.
