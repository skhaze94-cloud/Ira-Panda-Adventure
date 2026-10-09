# Ara the Panda: Quest to Find Ira — Godot v0.4 — Lantern Trails

This release makes the lantern a tool for discovery throughout the existing
**2D Godot adventure**. It retains v0.3 landscapes and controls, the v0.2.2 PNG /
ZIP import fix, all five quests, story panels, artwork and music. The Unity 3D
conversion remains on hold.

## Open and play

1. Extract the ZIP into a new folder, or use Godot Project Manager's ZIP import.
2. Import `project.godot` with Godot 4.3 or newer, Compatibility renderer.
3. Wait for asset import, then press F5.

| Action | Controls |
|---|---|
| Move | WASD / arrows, or direction buttons |
| Walk to a destination | Click / tap the woodland floor |
| Lantern glow | Space / GLOW |
| Talk / quest station / door | E / INTERACT |
| Pause | Escape / pause button |
| Story | Enter / Space / Next Page / Skip |

Music and Gentler Motion are available under Options. Losing application focus
pauses play. UI buttons do not capture movement or lantern keys after a click.

## Lantern discovery loop

Explore, glow, follow a clue, and shine again as the trail unfolds. Press
**Space / GLOW** near a blue bud, hidden trail or marked shadow stone.

- **Hidden footprints:** nearby silver tracks appear for 18 seconds. They lead
  along the first teaching trail and toward chapter quest locations. Glowing
  again refreshes nearby tracks. A discovered trail counts once for that chapter.
- **Lantern blooms:** three blue buds per chapter wake within 3.2 world units of
  a glow. Each becomes a lasting green light, shares a chapter hint and restores
  one missing heart on its first awakening. Repeat glows cannot farm hearts.
  Blooms also reveal nearby footprints. These are separate from the three
  quest moonflowers in Pillowmoon Garden.
- **Shadow stones:** stand on the visible brass crescent and glow. When light
  comes from the correct side, the ordinary shadow becomes a golden arrow and
  exposes a clue for 18 seconds. Other angles give an alignment hint. Stargazer
  Hollow also contains a shadow inscription showing **Moon > Star > Heart**.
- **Discovery counter:** the HUD counts blooms, trails and shadow clues found
  in the current chapter, with a contextual lantern hint. Repeat discoveries
  do not add to the counter. Restarting a chapter clears its discoveries.

The glow search radius is 4.8 world units; the expanding ground ripple shows
its reach. Original key/page reveals, bat repelling and quest-flower awakening
retain their existing ranges and rules. There is no fuel cost or added quest
gate. The lantern's original short recharge remains. Clue timers pause during
dialogue and pause screens; Gentler Motion keeps all clues usable without an
expanding ripple or decorative plant bobbing.

## Distinct landscapes

- **Whispering Woods:** taller woodland trees, gentle bends, a pale-blue side
  trail to the original key grove, and named navigation landmarks.
- **Glowcap Glade:** broader mushroom clearings, violet cap rings and a silver
  spore circle along a new rolling route.
- **Puddlebrook Crossing:** broad brookside bends, pebble pools, reeds and visible
  planks spanning the brook after the bridge quest is completed.
- **Stargazer Hollow:** an open clearing with concentric star rings, named rune
  stones and a constellation connection that brightens after completion.
- **Pillowmoon Garden:** an open cottage approach with flowerbeds, painted
  moonflowers and garden landmarks.

## Smoother controls

Movement now accelerates and brakes over a short interval, with small collision
steps, screen-aligned diagonal input, speed-driven foot animation and subtle
body lean. The camera follows with gentle directional anticipation; Gentler
Motion removes that anticipation and decorative character movement.

Click / tap walking routes around trees. Blocked destinations snap to nearby
walkable ground when reachable. A closed bridge remains closed until repaired.
Keyboard or direction-pad movement cancels a click route immediately. Pausing,
changing chapter and losing focus clear held movement and routes.

Interaction reach and collection reach are more forgiving. Nearby guides and
stations show a contextual prompt. A lantern press just before recharge ends
is buffered for up to 0.2 seconds. Direction-button release is idempotent, so
repeated release events cannot leave a phantom direction held.

## Validation

Validated locally with Godot **4.7.2**:

- All five original quest smoke checks passed.
- Lantern checks passed in every chapter: hidden initial state, reveal range,
  routes to all blooms and source markers, correct and wrong shadow angles,
  one-time healing and discovery rewards, clue expiry/refresh, pause behavior,
  chapter reset, Gentler Motion and original bat repelling.
- Actual click-route walking to every quest item, required rune, station and
  exit passed, including both bridge states.
- Screen-direction mapping, 30/60/120 fps movement consistency, braking,
  duplicate direction releases, pause cancellation, Gentler Motion movement
  and lantern buffering checks passed.
- OpenGL rendered before/after lantern captures of all five chapters, an
  awakened bloom and the rune-order clue were reviewed. Earlier v0.3 checks
  covered facing directions and bridge/garden completion states.
- ZIP packaging retains explicit folder records and PNG assets.

Run developer checks:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/landscapes_controls.gd
godot --headless --path . --script res://tests/lantern.gd
godot --path . --script res://tests/capture_lantern.gd --max-fps 60
```

Lantern captures default to `user://v04-captures`. Set `IRA_CAPTURE_DIR` to save them
elsewhere. `tools/package_project.py` makes a ZIP with explicit directory
records and excludes generated import caches.

This release has not been device-tested on mobile, tested with physical touch,
or exported to a platform build. Godot 4.3 compatibility has not been re-tested;
the local engine used was 4.7.2. Audio playback still needs a listening check.
`REVIEW-V0.2.md` is retained as the historical review of the earlier release.
The Godot edition is maintained on GitHub branch
`godot-4-v0.2-moonlight-depth`; the browser edition remains on `main`.
