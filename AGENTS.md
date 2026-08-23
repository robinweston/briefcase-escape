# Briefcase Game contributor guide

## What this project is

Briefcase Game is a small Godot 4 isometric 3D browser prototype. The player controls a camera-facing briefcase sprite and moves it around five stationary, low-poly people on a flat grid.

There is currently no score, dialogue, win condition, or interaction system. Treat the project as a movement and presentation prototype unless the user asks to expand the game design.

## Current behaviour

- Move with `WASD` or the four arrow keys.
- Movement is relative to the isometric screen, not raw world axes.
- The briefcase collides with the static people.
- World boundaries clamp the briefcase to `-7.5...7.5` on the X and Z axes.
- The camera is fixed, orthographic, and does not follow the player.
- There is deliberately no click-to-move or touch-to-move behaviour.

The screen-relative movement conversion is in `_physics_process()`:

```gdscript
Vector3(input_vector.x + input_vector.y, 0.0, -input_vector.x + input_vector.y)
```

Preserve this relationship unless changing the camera orientation and controls together.

## Architecture

`main.tscn` contains only the root `Node3D`. `scripts/main.gd` constructs the complete runtime scene in code:

1. `_build_world()` creates lighting, the ground, grid, and people.
2. `_build_player()` creates the `CharacterBody3D`, collision capsule, and briefcase `Sprite3D`.
3. `_build_camera()` creates the fixed isometric camera.
4. `_build_hud()` creates the instruction panel.

The briefcase visual is `assets/briefcase.svg`. It is shown as a billboarded `Sprite3D`, so it remains a static 2D image while moving through a true 3D scene.

People are `StaticBody3D` nodes made from primitive meshes and capsule collision shapes. Their positions and colours are defined by the `PEOPLE` constant near the top of `scripts/main.gd`.

## Important files

- `project.godot`: project settings, input actions, viewport, and Compatibility renderer.
- `main.tscn`: main scene and script attachment.
- `scripts/main.gd`: all gameplay, world construction, camera, and HUD code.
- `assets/briefcase.svg`: static player artwork.
- `export_presets.cfg`: single-threaded Web export preset.
- `start-game.sh`: exports, serves, and opens the browser build.
- `build/web/`: generated browser output; ignored by Git and safe to regenerate.

## Input-map warning

Keep input actions in `project.godot` named `move_left`, `move_right`, `move_up`, and `move_down`.

Godot 4 arrow-key physical keycodes are:

- Left: `4194319`
- Up: `4194320`
- Right: `4194321`
- Down: `4194322`

Do not use `4194311` or `4194313` for horizontal movement; those represent Insert and Pause, respectively. Letter controls use physical keys so `WASD` remains based on keyboard position.

## Browser requirements

The browser is a primary target, not an optional port:

- Keep the renderer set to `gl_compatibility`; Forward+ and Mobile cannot export to Godot 4 Web.
- Keep the Web export single-threaded unless hosting is explicitly changed to provide the required cross-origin isolation headers.
- Avoid C# and platform-specific native extensions.
- Keep assets and scene complexity modest for download size and low-end browser performance.
- Browser builds must be served over HTTP; opening `index.html` directly is insufficient.

## Running and validation

The expected local launcher is:

```sh
./start-game.sh
```

It exports to `build/web`, serves on port `8080`, and opens the browser. Stop it with `Ctrl+C`.

For automated or background checks:

```sh
BRIEFCASE_PORT=8081 BRIEFCASE_OPEN_BROWSER=0 ./start-game.sh
```

Validate gameplay code without opening a window:

```sh
godot --headless --path . --quit-after 3
```

Rebuild only the Web export:

```sh
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
```

After gameplay, input, rendering, or export changes:

1. Run the headless project and check for GDScript/runtime errors.
2. Rebuild the Web export.
3. Serve the build and verify it loads without browser-console errors.
4. Exercise all eight keyboard directions with both `WASD` and arrow keys when input code changes.

## Change guidelines

- Keep changes small and prototype-friendly.
- Update the HUD and `README.md` whenever controls change.
- Do not reintroduce pointer movement unless the user explicitly requests it.
- Add gameplay systems as separate scripts/scenes once `main.gd` becomes difficult to navigate; the current single-script structure is intentional only while the prototype is small.
- Preserve the SVG as a fallback if introducing generated or raster briefcase artwork.

