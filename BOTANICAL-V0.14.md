# v0.14.0 — A Little Room to Bloom

Five new botanical textures for each of the five chapters: 25 individually generated transparent sprites, integrated into the live world. The two new tree silhouettes per chapter join the two existing silhouettes; the three smaller plants/props appear along alternating banks.

## Assessment and visual direction

The previous renderer used two tree silhouettes per setting, dense cell-based placement, and lamps/decorations at three-unit intervals. Several decorative systems accumulated near the same route. The refresh keeps the established painted artwork and chapter palettes while adding open branches, contrasting leaf shapes, smaller seasonal plants, and occasional botanical objects. Trees frame the route; plants sit in separated groups rather than forming a continuous hedge.

| Chapter | New textures |
| --- | --- |
| The Whispering Woods | rowan, hazel, fern, wild strawberry, mossy birch branch |
| Glowcap Glade | lilac alder, mushroom tree, bell mushrooms, silver fern, hollow log planter |
| Puddlebrook Crossing | young willow, river birch, cattails, water mint, driftwood lily |
| Stargazer Hollow | silver starblossom tree, blue juniper, moon ferns, starflowers, lichen stone |
| Pillowmoon Garden | blush crabapple, cream magnolia, peonies, moonflower vine, sweet-pea watering can |

## Integration

- Tree anchors are at least 2.3 ground units apart. Repeated lamps and standard decorations use six-unit intervals instead of three, alternating sides.
- New small props have at least 3.5 units between their anchors, 2.8 units from protected objectives/characters, and 1.8 units from nearby tree/decor anchors. Placement is deterministic and bounded to 12 small props per chapter.
- Tree and plant anchors stay outside stream channels, with a little extra bank clearance.
- New props respect depth sorting and gentle-motion settings. Trees retain the existing fade near characters and important targets. Decorative plants introduce no new collision.
- All five new textures per chapter are used in world rendering. Only the active chapter's botanical textures remain loaded.
- Generated alpha is preserved. Transparent margins are cropped and sprites resized for runtime use; original character, quest-item, scenery and audio artwork is retained unchanged.
- Artwork: built-in image_gen, separate prompts for each sprite. Subjects, palettes, source hashes and runtime hashes are in `assets/botanical/manifest.json`; full prompt scaffold is in `assets/botanical/prompts.json`.

## Validation

See `tests/benchmarks/botanical-validation.json` for final automated results and layout counts. Native desktop and compact OpenGL captures are reviewed separately. Software rendering is used in this environment; physical-device GPU performance and feel are not measured.
