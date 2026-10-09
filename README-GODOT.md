# Ira the Panda Adventure — Godot 4 port (v0.1)

Isolated branch **godot-4-port-v0.1**, based on the latest 2.4 Storybook. The HTML game is preserved on main.

## Open
In Godot 4.3+, import project.godot and run the project. It uses the WebP images, MP3 music and story-24.json already in this repository.

## Controls
- WASD or arrow keys: Move
- Space: Lantern glow
- E: Interact and talk
- Escape: Pause
- On-screen directional pad, GLOW / INTERACT, or tap-to-walk

## Scope
Five storybook chapters, woodland key, scroll, bridge, stars, moonflower quests, 2.4 comic transitions, Godot native rendering/UI and character animation.

## Source structure
- `scripts/core.gd` — GDScript quest logic, gameplay, map generation and controls
- `scripts/render.gd` — isometric textured renderer and character animations
- `scripts/main.gd` — menu, storybook, HUD and touch UI
- `scenes/main.tscn` — Godot entry scene
- `assets/` and `story-24.json` — original 2.4 Storybook media and script data

**Status:** First native port candidate. Godot editor/runtime and mobile export testing have not yet been completed. The `main` branch has been left unchanged.

This is a first port and needs Godot editor/runtime testing. Do not merge to main until tested.
