# Ara the Panda: Quest to Find Ira — Godot v0.5

**Living Woodlands** updates the five-chapter 2D Godot adventure with animated
woodland neighbours, new scenic stops and a rebuilt renderer. The Godot edition
is on `godot-4-v0.2-moonlight-depth`; the historical branch name is retained.

- Pip waves and swings his lantern; Bramble scribbles and greets Ara; Moss swishes
  his tail and gestures. All three turn toward Ara and react to her light.
- Explore ribbon clearings, glowcap clusters, lily ponds, orbiting star sculptures
  and flower arches, with fireflies, butterflies, frogs, ripples and shooting stars.
- Softer effect edges, blended trail borders, warm pools of lantern light,
  walking dust and celebratory sparkles make the woods feel alive.
- Choose Light, Balanced (default) or Rich graphics in Options. Rich adds painted
  surface relief and lantern shadows. Gentler Motion remains available.
- The renderer batches effects, draws the ground in one pass, culls forest chunks,
  and keeps lights, creatures and particles within fixed budgets.

All v0.4 lantern discoveries, five quests, story panels, navigation and music
are included. In local 1280×720 test views, Balanced reduced median frame times
substantially versus v0.4; see [PERFORMANCE-V0.5.md](PERFORMANCE-V0.5.md) for the
measurements and their limits.

Import `project.godot` with Godot 4.3 or newer, Compatibility renderer, wait for
asset import and press F5. Move with WASD/arrows or click the ground, Space to
glow, E to interact, and Escape to pause.

[README-GODOT.md](README-GODOT.md) has full controls and validation details.
Local verification used Godot 4.7.2. Unity 3D conversion remains on hold; the
browser edition is maintained on `main`.
