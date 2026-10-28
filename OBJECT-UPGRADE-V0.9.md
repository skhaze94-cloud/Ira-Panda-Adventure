# v0.9 — Object Upgrade Pack: Woodland Whimsy

Twenty new PNG illustrations bring a different bridge, pumpkin, sign and playful
display to each of the five chapters. Nine encounter positions per chapter
follow the three treasure loops, giving forty-five encounters in the game.

| Chapter | Bridge | Pumpkin | Trail display |
|---|---|---|---|
| Whispering Woods | Honey-oak acorn boards | One-toothed leaf-hat grin | Biscuit Boo in a hollow log |
| Glowcap Glade | Violet mushroom timber | Ticklish mushroom hat | Postmaster Mushroom and snail |
| Puddlebrook Crossing | Fish-carved driftwood | Spectacles and a hello | Captain Quack's walnut boat |
| Stargazer Hollow | Constellation boards | Star-speckled wizard | Professor Flap's telescope |
| Pillowmoon Garden | Rose and heart boards | Blushing pink bonnet | Teapot Tilly's ghost cottage |

## Little encounters

Approach an object and press E or its contextual LOOK / SAY BOO button. A single
Ara caption describes its joke, while the object bounces, glimmers and settles.
The lantern also wakes nearby objects; pumpkins contribute warm ground light.
Gentler Motion keeps the captions and light response without decorative bobbing.
Pausing freezes response timers.

Continue saves the nine discovery flags for the current chapter. Earlier saves
without those flags load normally. These encounters add personality without
changing the 400-point crown, required chest items, quest order or exit rules.
Chests retain interaction priority when several objects are nearby.

## Bridges

All eleven crossings now use chapter artwork mapped onto the existing safe
world-space lanes. Textured rails, posts, bells and a visible deck edge provide
depth; the front rail participates in the actor depth sort. Bank stones and
ferns soften the joins. Puddlebrook's quest bridge shows two broken ends until
repaired, then reveals its boards during the repair animation.

## Artwork and memory

The twenty original RGBA PNGs live in `assets/objects`. They use transparent
backgrounds and region metadata, with no WebP source dependency. The renderer
loads four object textures for the active chapter and releases the previous
chapter's object references. Existing bounded lighting and creature pools remain
in use.

## Verification

The release checks use Godot 4.3 stable with Compatibility. The machine-readable
results are in `tests/benchmarks/object-upgrade-validation.json`. Coverage includes
the original five quests, click-route walking, all secret loops and collectibles,
lantern rules, captions, save/resume, motion options and all forty-five new
encounters. `tests/object_upgrade.gd` checks interaction, reachability, legacy
saves, current-chapter texture loading and the repair gate.

`tests/capture_v09.gd` renders every chapter's bridge and three object types, the
repair sequence and a compact caption view. Set `IRA_CAPTURE_DIR` to choose its
output directory. The ZIP is extracted into a clean folder and imported before
delivery. Mobile hardware, physical touch and platform exports remain separate
device checks.
