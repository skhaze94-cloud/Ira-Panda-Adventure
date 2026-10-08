# Ira the Panda 2.3 — Quest to Find Ira

A kid-friendly painted moonlit adventure starring Ara the Panda and her pillowcase sister Ira.

[Play the game](https://ara-quest-to-find-ira.sjk100.chatgpt.site)

## Comprehensive 2.0 update

- Five distinct painted terrain sets, with alternating isometric checkerboard tiles.
- Fifteen woodland, mushroom, riverbank, celestial and flowering tree sprites.
- Ten ornate tall and short lantern posts with warm pools of light and cool moonbeams.
- Each chapter's playable route is approximately twice the previous length.
- Lantern use lifts and sways the lantern, sends curling light wisps outward, and releases shimmering world-space particles.
- Cooldown reduced from 2.6 seconds to 1.15 seconds.
- Extra funny captions along the trails; all five chapters still lead to Ira's reunion.
- Distinct tree arrangements: dense groves, glade clearings, river reeds, celestial openings and spaced garden rows.

## Chapters

1. The Whispering Woods
2. Glowcap Glade
3. Puddlebrook Crossing
4. Stargazer Hollow
5. Pillowmoon Garden

## Play locally

Open index.html with assets, game.js and style.css alongside it. WASD or arrow keys move, Space activates the lantern, E talks to neighbours or opens the door, Esc pauses. Touch controls and tap-to-walk are included. Options control sound and gentler motion.

## Validation

All five routes, objectives, locked gates, chapter transitions, final reunion, movement and pause passed the gameplay harness. Checks also cover doubled playable spans, cooldown behavior, particle expiry/budget and reduced motion. Each chapter and the lantern burst were rendered with the actual Canvas renderer for visual inspection, including a mobile playfield.

Artwork generated with the built-in image tool. Full prompts: assets/asset-prompts-v2.json.

## Music

Menu and opening comic: **Curious Monsters (Remastered)**. Gameplay: **Nimble Motif (Remastered)**. Both supplied MP3s loop. Persistent audio players keep gameplay music continuous through chapters and chapter story panels without reloading or seeking. Music starts with the first user interaction and has a separate Music option. Hidden tabs pause music and resume at the same position when visible.

## Quest 1 — The Lost Woodland Key (2.1)

Level 1 is twice its 2.0 length. Three painted NPCs appear only in Whispering Woods: Pip the owl teaches movement and lantern use; Bramble the hedgehog explains the locked door; Moss the fox gives the key quest and a hint about three pale birches, blue mushrooms and a blue lantern branch. Explore the woodland branch, use the lantern to reveal the brass key, approach it to collect it, then press E or tap Open door at the wooden door. The first door stays locked until you have the key. Only Quest 1 is added; later chapters retain their existing objectives. Collected keys survive bat resets; a fresh adventure resets the quest.

Quest checks verify all NPC dialogues, the reachable woodland branch, lantern reveal and pickup, locked-door guards, door interaction, first-level length, quest reset and no NPCs/quests in chapters 2–5. Music continuity checks also pass for the standalone HTML.

## Character animation update (2.2)

New painted transparent rig atlases preserve the original character designs. Ara's paw, ring handle and lantern form one connected painted part, with a lantern lift on Glow, independent footsteps driven by actual travel, breathing and head turns. Pip has separate wing/lantern gestures and head turns; Bramble moves his held clipboard and pencil; Moss points and swishes his separate tail. NPC conversations show the same animated rigs in live portraits. Ira has neutral, blinking and delighted expressions, with a softer fabric sway and a happy reaction as Ara approaches. Bats have continuously articulated violet wings and faster frightened flaps. The title screen and final reunion use the articulated sisters.

Cast movement freezes on pause. Gentler motion removes oscillation while preserving readable poses and glow actions. Quest 1, all five chapters, and music continuity are retained. Gameplay and standalone checks cover all chapters, quest/door behavior, movement-driven gait, dialogue animation, pause, gentler motion, sprite crops and looping music. Source sprites and full built-in image-generation prompts are in assets/*-rig-22.webp and assets/cast-22-prompts.json; source crop definitions are in assets/cast-22-crops.json.

## Lively character follow-up (2.2)

Pip, Bramble and Moss now move around their home spots rather than remaining in fixed positions. Each has an individual pace and walking bounce. They notice Ara, approach slightly, hop in greeting, settle for easy conversations, and react happily to nearby lantern glow. Moss wags his tail more quickly near Ara. Patrols stay within 1.7 map units of home, avoid tree collisions, and freeze on pause or in gentler motion. Ira shuffles and hops more excitedly as Ara reaches the cottage. Only the original three NPCs and Quest 1 are present.

Checks cover all three NPCs changing world position, clear routes and home boundaries, approach reactions, easy talking, lantern reactions, pause and gentler motion; all chapters and continuous music pass for the standalone HTML.

## Five-quest update (2.3)

Chapters 2–5 have doubled playable spans of 68, 72, 76 and 80 map units, following chapter 1's existing 60-unit route. Quest 1 remains the woodland key adventure. Each later chapter has a lively returning guide, readable objective/inventory progress and new painted quest objects:

- Quest 2, The Torn Moon Scroll: Pip asks Ara to reveal three scroll pages in glowcap nests, collect them and rebuild the scroll at the moon lectern.
- Quest 3, The Wobbly Brook Bridge: Bramble needs three driftwood bundles. The broken crossing physically blocks onward travel until Ara repairs it with E or the touch action.
- Quest 4, The Sleepy Constellation: Moss asks for three star crystals, then a lantern puzzle at Moon, Star, Heart stones in that order. Incorrect order resets only the stones, preserving crystals.
- Quest 5, Ira's Moonflower Lullaby: wake three moonflowers with Glow and play the cottage music box with their petals. Ira appears when the lullaby opens the cottage.

Completed collections survive bat resets; restarting an adventure resets progress. Later exits and direct completion calls are guarded until the chapter quest is done. Persistent music and articulated/lively character behavior remain in place.

Gameplay checks pass for every quest, reachable items/guides, doubled route spans, no duplicate collection, mandatory lantern actions, broken/repaired bridge, puzzle retry, chapter transitions and final reunion. Music and all quest checks also pass for the self-contained HTML. Quest item/station/completed states were inspected with the actual Canvas renderer. New atlas: assets/quests-23.webp; exact built-in generation prompt: assets/quests-23-prompts.json; source rectangles: assets/quests-23-crops.json.
