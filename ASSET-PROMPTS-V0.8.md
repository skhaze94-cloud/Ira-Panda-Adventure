# Original asset prompts — v0.8 Hidden Wonders

Mode: built-in ImageGen, five brand-new transparent PNG atlas generations.
The five source sheets are saved unchanged at `assets/beauty/woods.png`,
`glade.png`, `brook.png`, `hollow.png`, and `garden.png`. Each contains four
individual illustrated assets. `regions.json` records alpha-bounded rectangles;
Godot samples regions directly rather than modifying the bitmap files.

Shared prompt direction: a polished painterly storybook sprite sheet for an
isometric Godot woodland adventure for a young child, warm magical detail,
textured bark, moss, delicate blossoms, soft moonlit rim light, richly illustrated
material surfaces and gentle fairytale charm. Exactly four isolated cutouts in
a spacious two-by-two arrangement, full silhouettes and roots, transparent
background, no text, labels, grids or frame. Upper-left airy tree; upper-right
plant patch; lower-left closed themed treasure chest; lower-right landmark.
Match the established woodland's detailed illustrated, softly shaded style.

| Atlas | Airy tree | Plant patch | Treasure chest | Landmark |
|---|---|---|---|---|
| woods.png | Silver birch with light canopy | Ferns, ivory daisies and moss | Carved wood and copper clasp | Acorn and crescent stump |
| glade.png | Curving violet mushroom tree | Blue and mauve glowcaps | Lilac velvet, brass crescent | Ivory moth-flower bush |
| brook.png | Jade willow with hanging leaves | Reeds and pink water lilies | Driftwood and brass | Rounded mossy river boulder |
| hollow.png | Silver rowan with blue foliage | Silver starflowers | Midnight blue, gold stars and moonstone | Crystal arch and crescent |
| garden.png | Blush cherry blossom tree | Pink and ivory moonflowers | Ivory quilt lid, rose heart clasp | Biscuit-carved sage bench and cushion |

Integration: new trees alternate with established chapter tree variants. All
three treasure alcoves include plant patches and landmarks, with smaller trees
framing the chests. Every prop participates in the world's depth order. The
native renderer animates upper chest regions around a hinge, adds glimmer and
star sparkles, and respects Gentler Motion. The illustrated sprites augment
Godot's existing lighting, atmospheric shaders, water and foliage fading.
