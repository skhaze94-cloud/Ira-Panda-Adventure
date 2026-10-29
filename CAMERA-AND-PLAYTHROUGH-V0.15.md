# v0.15.0 — A Gentle Journey

The camera now follows Ara with a damped spring, a short directional lead, and bounded attention toward nearby characters, interactable objectives and close destinations. A central corridor keeps Ara away from the outer touch controls; a visible discovery caption raises the framing. Resizing, Continue and respawn reframe immediately instead of sweeping across the map. Pause and dialogue freeze the world camera.

Crossings and side clearings receive a short, gentle reveal on approach. The last chapter also frames the cottage approach. Reveals last 2.8 seconds, have an eight-second separation, and occur once per location during a chapter visit. They never lock controls, change zoom or trigger screen shake. Gentler Motion removes the directional lead and scenic motion. Nearby reveals are suppressed after Continue, respawn or resize so returning players do not get a surprise pan.

## Smaller fixes

- Play Again clears the opening tutorial flags while preserving best scores and the chapter album.
- Touch players receive a GLOW touch hint; chest dialogue uses Interact rather than a hard-coded keyboard key.
- World prompts use shared bounds: they avoid other prompts, visible HUD controls, viewport edges and Ara's body. Labels render above particles and butterflies, which previously could obscure letters. NPC prompts sit above the character's head; constellation names use the same placement rules.
- Discovery cards reset their desired width/height as wrapped text settles, preventing a first-use card from staying excessively tall. The finale frames both sisters above the result card; compact results use tighter spacing and text.
- The final music box sits beside the garden path instead of crowding Ara during the reunion. Its rendering, interaction position and quest destination share the same updated location.
- A long native review can now supply a longer capture timeout. This only affects the QA helper.

## Complete journey review

`tests/full_journey_v015.gd` drives the actual opening pages, walking, conversations, chest interactions, lantern use, quest stations, chapter interludes, Continue, reunion and replay in order. It does not inject quest-completion flags or jump between chapters. It visits one side clearing and opens the optional first chest as well as the required quest chest in every chapter. The separate Hidden Wonders suite covers all 90 stars and all 15 chests.

The route uses known objective locations and presses Glow defensively near bats. This is a scripted engine playthrough, not an unassisted human playtest. Its simulated time is not a promise about how long a new player will take. Native OpenGL screenshots cover the journey; separate framing captures cover desktop and compact viewports, captions, scenic transitions and Gentler Motion.

Final results, chapter observations and method are recorded in `tests/benchmarks/gentle-journey-validation.json`. The source ZIP contains the game and this review; it is not an exported Windows or Android installer.

## Major outstanding work

| Priority | Aspect | Evidence and next step |
| --- | --- | --- |
| High | Target-device performance and first-route latency | Navigation still prepares its grid incrementally. A first distant tap can wait; previous software benchmarks also contained long work slices. Profile on the intended phone and desktop GPU, then address path preparation and rendering using those measurements. No target-device frame rate is verified. |
| High | Exported builds and hands-on touch/accessibility QA | The source runs in the tested Linux Godot runtime. Windows/Android export, installation, device safe areas, sustained touch input, sound balance and large-text comfort still need physical-device testing. Compact screenshots do not establish those results. |
| Medium | NPC approach and body tapping | Ara can occupy an NPC's ground position; character sprites can overlap when the player walks directly onto a friend. Add safe stand-off arrival points and explicit character-body hit regions in a focused interaction update. Camera translation alone cannot separate overlapping world positions. |
| Medium | Guidance and difficulty with a fresh player | The complete scripted route knows where the hidden chest and stations are. Observe a first-time player finding them without help, distinguishing decorative flowers from quest flowers, handling bats, and learning Moon → Star → Heart. Tune hints and optional wayfinding from that evidence. |
| Medium | More chapter-specific play | Most later chapters share a three-item collection followed by a station or sequence. The visual identities are stronger than the mechanical differences. Design one distinct small activity per chapter before adding more content or levels. |

No quest blocker was found in the final automated journey. The remaining items above are substantial follow-up work or validation gaps, rather than claims that those areas have been completed.
