# Briefcase Game contributor guide

## What this project is

Briefcase Game is a browser-first Godot 4 stealth game set in an illustrated office. The player guides a camera-facing briefcase through a scrolling maze of cubicles while avoiding patrolling office workers and their visible sight cones.

The goal is to travel from the start of the office to the exit. Being seen normally resets the level. The briefcase can temporarily disguise itself as an ordinary case, causing a worker to carry it somewhere else instead of catching it.

## Current behaviour

- Move with `WASD` or the arrow keys.
- Movement is limited to four screen-aligned cardinal directions; diagonal input resolves to one axis.
- Press `Space` to toggle the temporary disguise.
- Collectibles replenish disguise time.
- Press `P` to pause or resume.
- Workers patrol fixed routes, face their movement direction, react to the player, and collide with office geometry.
- Visible vision cones match the real detection angle and range and are clipped by sight-blocking geometry.
- Office furniture and walls provide movement obstacles, cover, and readable stealth routes.
- Reaching the exit completes and freezes the level.
- There is deliberately no click-to-move or touch-to-move behaviour.

## Camera and isometric presentation

The gameplay view uses an orthographic, pitched top-down camera. It has an isometric-style 2.5D appearance, but it remains aligned with the world axes rather than using a rotated diamond-grid basis.

Movement currently depends on that alignment. `_update_player()` converts screen input directly into the ground plane:

```gdscript
Vector3(input_vector.x, 0.0, input_vector.y)
```

Preserve this relationship unless the camera orientation and controls are deliberately redesigned together. Rotating the camera around the vertical axis would also require coordinated changes to movement, directional animations, patrol readability, level layout, and input testing.

The camera follows the player smoothly and clamps its focus near the office boundaries. Keep the focus at floor level while the briefcase is being carried or animated vertically so the view does not bump. Start and exit framing should remain readable near the edges of the level.

Characters and illustrated props are camera-facing 2D sprites inside a real 3D world used for collision, lighting, and sight checks. Preserve this hybrid approach: artwork should remain clear and grounded at the current camera pitch while shallow geometry supplies physical depth and occlusion.

## Art direction

The established style is a clean, colourful office cartoon with bold outlines, readable silhouettes, warm character accents, and subdued workplace colours. It should feel illustrated and playful while remaining immediately legible at browser-game scale.

- Keep characters expressive and easy to distinguish during movement and stealth reactions.
- Keep directional poses and animation states visually consistent across the cast.
- Use transparent, outlined scenery that reads naturally from the pitched camera angle.
- Keep floor textures restrained so they do not compete with characters, paths, collectibles, or vision cones.
- Maintain coherent scale, lighting, outline weight, and ground contact across new artwork.
- The title presentation may be more energetic and cinematic, but it should still feel like the same office world and character design.
- UI should remain high contrast, friendly, and consistent with the dark office-stealth palette.

Avoid mixing in pixel art, photorealistic characters, or unrelated low-poly styles. Review new artwork beside the existing cast and scenery before adding it to gameplay.

## Sound direction

The sound style is playful, understated office stealth. It combines a light suspenseful music bed with recognisable workplace ambience and soft, distinct action cues.

- Music should create tension without feeling threatening or overpowering gameplay.
- Office ambience should make the setting feel active while leaving important cues audible.
- Sound effects should be short, warm, and easy to distinguish from one another.
- Pause and resume sounds must still work while the game is paused.
- Keep all audio compressed and compatible with browser export.

Avoid harsh arcade sounds or exaggerated cinematic effects unless the overall audio direction is intentionally changed. Preserve source and licence notes for third-party recordings.

## Architecture

The main scene contains a minimal root node, while the primary gameplay script constructs the current prototype in code. It builds the office, player, workers, camera, HUD, and audio systems.

Supporting scripts separate title-screen behaviour, pause handling, shared animation setup, and the standalone asset gallery. Continue splitting out systems when the main gameplay script becomes difficult to navigate, but keep changes small and prototype-friendly.

The asset gallery is the preferred place to compare character animation, scenery, music, ambience, and sound effects without running the full level.

## Input-map warning

Keep the input actions named `move_left`, `move_right`, `move_up`, `move_down`, `toggle_disguise`, and `toggle_pause`.

Godot 4 arrow-key physical keycodes are:

- Left: `4194319`
- Up: `4194320`
- Right: `4194321`
- Down: `4194322`

Do not use `4194311` or `4194313` for horizontal movement; those are Insert and Pause. Letter controls use physical keys so `WASD` remains based on keyboard position.

## Browser requirements

The browser is a primary target, not an optional port:

- Keep the renderer set to `gl_compatibility`.
- Keep the Web export single-threaded unless hosting provides the required cross-origin isolation headers.
- Avoid C# and platform-specific native extensions.
- Keep artwork, audio, scene complexity, and simultaneous effects modest for download size and low-end browser performance.
- Browser builds must be served over HTTP rather than opened directly from disk.

## Running and validation

Use the project launcher for normal browser development:

```sh
./start-game.sh
```

For automated or background checks:

```sh
BRIEFCASE_PORT=8081 BRIEFCASE_OPEN_BROWSER=0 ./start-game.sh
```

Validate gameplay without opening a window:

```sh
godot --headless --path . --quit-after 3 -- --skip-title
```

Review visual and audio work independently with:

```sh
./view-gallery.sh
```

After gameplay, input, camera, rendering, audio, or export changes:

1. Run the headless project and check for runtime errors.
2. Rebuild and serve the Web export.
3. Verify the browser build loads and plays without console or audio errors.
4. Test all four movement directions with both keyboard schemes and confirm paired input suppresses diagonals.
5. Check camera framing, sprite grounding, corridor readability, vision-cone alignment, and cover throughout the level.
6. Listen to affected audio in context with the music and ambience running.

## Asset generation

- Never print, log, paste, or commit locally stored API keys.
- Keep secrets and temporary generation files out of the shipped asset directories.
- Store only final game-ready assets under `assets/`.
- Update the relevant generator whenever a generated asset is intentionally changed.
- Review generated visual and audio work in the asset gallery before wiring it into gameplay.

## Change guidelines

- Keep changes small and prototype-friendly.
- Update the title screen, HUD, README, and this guide when controls or core rules change.
- Do not reintroduce pointer movement unless explicitly requested.
- Keep visible vision cones aligned with real detection and sight blockers.
- Treat start safety, exit reachability, connected routes, cover, patrol timing, collectible accessibility, worker drop points, and camera framing as level-design invariants.
- Preserve the camera/input relationship and illustrated-sprite/3D-collision hybrid unless a coordinated redesign is requested.
- Preserve the understated office-stealth sound direction unless an audio redesign is requested.
