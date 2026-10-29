# Little Paws · v0.13.0

## Walking

Keyboard directions have a normalized ground speed; the joystick now preserves input strength for careful movement. Acceleration, braking and the existing body-lean animation give starts, stops and turns softer transitions. Bounded collision substeps remain in place. Blocked movement slides along the dominant requested axis without adding unsolicited sideways movement, and blocked velocity components are removed.

## Tap-to-walk

Tap routes accelerate instead of snapping to full speed. Speed carries through route corners while direction stays on the collision-checked segment, avoiding momentum cutting across scenery. Pending and active routes cancel immediately when manual input begins; releasing manual input cannot resurrect them. Gold markers distinguish an accepted route, arrival uses a tick, and a rejected or obstructed destination uses a rose cross. Gentler Motion keeps markers steady.

Long direct-line probes are deferred to the incrementally built navigation grid. Nearest-cell selection checks the central cell first and avoids visibility checks for cells that cannot improve the result. Path shortening uses bounded lookahead instead of repeatedly testing progressively longer rays.

## Interactions

A single nearest-target selection drives the action button, target ring, tooltip and action. Nearby chests, characters, objects, doors and quest stations compete by distance rather than category. The interaction radius is 2.7 ground units; visibility sampling prevents interaction through intervening solid scenery. Tapping precisely on the selected target activates it; requests to walk to ground positions remain movement commands.

## Validation

See tests/benchmarks/movement-validation.json. New tests cover acceleration and stopping, diagonal speed, joystick strength, manual takeover, arrival and rejection feedback, clustered targets, touch interaction, comfortable range and occlusion. Existing five-chapter navigation, hidden discoveries, object interactions, saves, touch controls, opening and storybook checks are rerun. Native desktop and compact captures check the target highlight and route marker. Physical-device feel and GPU frame rates remain unverified. Existing character art, camera behaviour and quest structure are retained.

Long discovery notices are also anchored using their final panel height, preventing compact-screen clipping when text wraps.

The measured cold route requests queue in 0.008–0.027 ms on this host. This is queueing latency: navigation construction still takes approximately 1.1–1.5 seconds of work spread over updates, followed by route planning. These numbers do not establish a target-device frame rate.
