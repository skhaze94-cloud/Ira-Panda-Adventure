# v0.4 — Little Talks, Big Adventure

Source: v0.3 `deb7f8a`, published separately on
`godot-4-v0.4-quests-and-captions`.

## Presentation

NPC conversations present one speaker and one caption at a time. A cream card,
ink-coloured text, gold edging, a softly dimmed woodland and an animated portrait
replace the generic instruction modal. Portraits reuse the original painted
Ara/Pip/Bramble/Moss rigs and Ira artwork, with shared scale and faithful part
pivots. Gentle breathing, head nods, gestures, happy sparkles and speaker fades
add motion without altering the illustrations.

Captions reveal at 44 characters per second. Space, Enter, E or a caption tap
first reveals the entire current line, then advances on the next press. The
final quest line says “Let's Go”. Back to Woods/Escape can leave early; quests
retain the original immediate-start behaviour rather than requiring acceptance.
Gameplay movement, hazards and quest timers pause while talking. No HUD, generic
modal, floating greetings or world labels compete with the conversation.

Gentler Motion reveals text immediately and suppresses portrait motion and
entrance/speaker fades. Options, pause, credits and replay keep their existing
controls and clear the conversation stage when opened.

## Quest writing

| Chapter | New conversation focus |
|---|---|
| Whispering Woods | Pip calls Ira's disappearance an owl emergency; Bramble's clipboard points to Moss; Moss explains the blue-lantern birch trail and key |
| Glowcap Glade | Purple nests have borrowed three scroll pages as wallpaper; Ara rescues the story and brings it to the lectern |
| Puddlebrook Crossing | Bramble diagnoses a “very wobbly wobble”; Ara gathers three bundles and repairs the bridge |
| Stargazer Hollow | A constellation snores in sparkles; collect crystals, then wake Moon → Star → Heart |
| Pillowmoon Garden | A suspicious giggle leads to the flowers and cottage lullaby |

Each first introduction uses three short beats: friend, Ara, friend. Subsequent
visits use shorter reminders based on collecting, ready-to-finish or completed
progress. The reminder includes the actual number found. All existing quest
items, requirements, locations, bridge gating and rewards remain intact.

Ira and Ara have a four-beat reunion, ending with the big hug and the existing
replay/title controls. This update changes NPC and in-world quest captions;
illustrated interchapter comic panels remain included.

## Discovery captions and HUD

A compact illustrated feedback card replaces bare text toasts. Only one notice
is visible. Long clues are split into ordered captions at sentence boundaries,
with a four-page cap; current authored messages fit that cap. Reading time scales
with caption length. Tapping continues or dismisses, while walking remains active.
A newer event replaces stale feedback, preserving the existing toast behaviour.

Collection and completion lines name the item or achievement and give the next
useful step. The chapter/quest HUD is shorter, and the discovery counter no longer
repeats the entire contextual hint. Overlapping NPC greetings are removed; the
single nearby interaction prompt remains while no feedback card is open.

## Validation

Godot 4.3 Compatibility checks:

- All five chapter quests, actual navigation, bridge gating, discovery/healing
  loops, graphics budgets and v0.3 rig/bloom tests pass.
- `tests/quests_captions.gd` covers all chapters and all three chapter-one friends;
  one speaker/one caption, progress reminders, input reset, paused gameplay,
  reveal-before-advance, Gentler Motion, long clues, reunion, replay and options.
- Real viewport events exercise Space and touch caption dispatch. A matching
  emulated mouse event is suppressed to prevent double advancement. Touch tests
  inject viewport-local coordinates, matching the coordinate space used by the UI.
- Card, caption and continuation button bounds are checked after native layout.
- Native OpenGL screenshots cover guide/response/instruction/reward states for
  all five chapters, plus Ira's reunion and an 854×480 landscape view.
- Fresh PNG project import and explicit-folder ZIP packaging are retained.

Run after importing:

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/quests_captions.gd
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/landscapes_controls.gd
godot --headless --path . --script res://tests/lantern.gd
godot --headless --path . --script res://tests/graphics_v05.gd
godot --headless --path . --script res://tests/masterclass.gd
```

For screenshots, run `tests/capture_quests.gd` with a display and
`IRA_CAPTURE_DIR` set. Local visual checks use Mesa software OpenGL; physical
phone input, safe-area insets and portrait orientation have not been tested.
The project continues to target landscape screens.
