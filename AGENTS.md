# Briefcase Game contributor guide

## What this project is

Briefcase Game is a browser-first Godot 4 stealth game set in an illustrated office. The player guides a camera-facing briefcase through a scrolling maze of cubicles while avoiding patrolling office workers and their visible sight cones.

The goal is to travel from the start of the office to the exit. Being seen plays the worker's surprise reaction, then opens an Escape Report and waits for Space before retrying. The briefcase can temporarily disguise itself as an ordinary case, causing a worker to carry it somewhere else instead of catching it.

## Current behaviour

- Move with `WASD` or the arrow keys.
- Movement is limited to four screen-aligned cardinal directions; diagonal input resolves to one axis.
- Press `Space` to toggle the temporary disguise.
- The level starts in a free disguise, ignores controls for one second, then automatically animates the briefcase to life; later disguises consume disguise time.
- Once spotted in disguise, disguise time pauses and movement and disguise toggling stay locked until the worker puts the briefcase down.
- A dropped briefcase receives three seconds of free disguise time and may leave disguise immediately.
- Collectibles replenish disguise time.
- Press `P` to pause or resume.
- Workers patrol fixed routes, face their movement direction, react to the player, and collide with office geometry.
- A worker's vision cone and detection are disabled while putting the briefcase away and returning to their patrol route.
- Visible vision cones match the real detection angle and range and are clipped by sight-blocking geometry.
- Office furniture and walls provide movement obstacles, cover, and readable stealth routes.
- Reaching the exit opens a cleared Escape Report and waits for Space before continuing.
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

## Static asset viewpoints

Directional static props use four cardinal views that must agree with the axis-aligned office layout. Treat the un-suffixed source image as the canonical south/front view, then produce the other views according to this contract:

- **South:** the functional front faces the bottom edge of the image and remains the canonical source view.
- **North:** rotate the prop 180 degrees around its vertical axis so the functional front faces the top edge and the back is the primary visible face.
- **East:** show a strict orthographic right-facing side elevation. The functional front points exactly toward the right edge; its front and back faces are edge-on. Do not use a diagonal, three-quarter, isometric, or perspective view.
- **West:** horizontally mirror the approved east image pixel-for-pixel. Never generate west independently. East and west must be the identical side profile in reverse, including dimensions, silhouette, grounding, lighting, and transparent padding.

Generate or edit the east view from the canonical prop, normalize it, and derive west only after east passes review. Preserve the same object design, proportions, declared tile footprint, camera pitch, outline weight, and contact point across all views. A directional image is invalid if it exposes both the front and a side face, changes the prop's apparent footprint, or uses canvas padding to shift its placement.

Before adding directional props to gameplay, compare all four views together in the asset gallery, verify east and west with an exact horizontal-mirror pixel comparison, and run `./capture-level-map.sh` to confirm that placed props face their walls and routes cleanly. Keep `tools/office_prop_rotation_manifest.json` and the relevant generator in sync with this contract.

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

## Static layout grid

Static scenery and dividers use a 0.5-world-unit tile. Depth-bearing props declare an integer `Vector3i(width, height, depth)` tile size; their collision footprint and on-screen billboard dimensions are derived from that single declaration. Billboard height must use the gameplay camera pitch so illustrated depth stays proportional across every asset.

Tile placement, adjacency, and row spacing are determined only by a prop's base contact footprint (`width` by `depth`), never by its illustrated height or full transparent-image bounds. Place ordinary adjacent props so their base footprints meet on the grid. Repeated depth-stacked banks, such as filing cabinets, may use a smaller explicit base-contact stride so foreground sprites occlude the bodies behind them; assign deterministic back-to-front render priorities and preserve only the rear props' readable top edges. Keep sprites grounded at their footprint centres and never add layout gaps merely to prevent tall artwork from overlapping.

Dividers declare an integer `Vector2i(width, depth)` tile footprint and integer tile height. Their visible and collision wall may remain a thin inset within the occupied tile row, but their span must be a whole number of tiles. Place new static assets on the same half-unit grid and do not add independent hand-tuned sprite sizes or collision dimensions.

## Level design review

Review every new or changed level as a complete stealth route, not only as a collection of correctly placed assets. Start with its whole-level snapshot and then play it in the browser with sound muted. A level is not ready merely because it loads without errors.

### Layout and access

- Confirm there is a connected, player-width route from the start to the exit and that all intended rooms, cubicles, bathroom stalls, collectibles, cover positions, and worker drop points are reachable. Check actual collision clearance, not just visible gaps in the snapshot.
- Inspect every doorway and cubicle opening. Entrances must face an accessible aisle rather than an outer wall, divider, desk, or another prop. Walk into each enclosed space from gameplay.
- Preserve more than one useful stealth choice where the design allows it. Avoid a single unavoidable choke point covered continuously by overlapping sight cones.
- Keep the start safe and readable. Early patrols should give the player time to understand the room and should move away from the spawn rather than trapping it in a short loop. Keep the exit visible, reachable, and free from accidental geometry or permanent cone coverage.
- Keep corridors wide enough for the briefcase, turning workers, carried movement, and camera readability. Validate worker pickup, drop-off, and return routes against walls and furniture as well as ordinary patrol routes.
- Place collectibles on traversable ground within pickup range. They must remain fully visible, must not overlap props or walls, and should reward a deliberate route rather than require collision exploits.
- In every whole-level snapshot, inspect the complete potion sprite and pickup clearance, not only its centre point. Keep both outside partition footprints and projected partition artwork so the collectible never appears embedded in a wall.

### Static scenery and room composition

- Put wall furniture flush against the wall when it is already intended to be wall-adjacent. Printers, vending machines, sinks, filing cabinets, and similar functional fronts must face into the room or aisle. Do not leave small unexplained gaps or place their usable face against a wall.
- Use each prop's declared base footprint for placement and clearance. Check that its sprite, footprint, and collision agree, that tall artwork does not overlap walls unnaturally, and that transparent padding has not shifted its apparent position.
- Group repeated furniture intentionally. Filing-cabinet banks should share a wall and use the approved depth stride and render order so foreground bodies overlap the cabinets behind and only their top edges remain readable. Do not fix sprite overlap by adding layout gaps.
- Make each room's purpose legible while preserving paths and cover. Distribute clutter rather than concentrating it in one room, and inspect foreground props for hidden routes, workers, collectibles, or vision cones.
- Keep boundary areas readable through the gameplay camera. Near the north edge in particular, leave enough projected space for tall scenery and the HUD so the player, walls, exits, and threats are not obscured.
- Floor-material transitions must meet cleanly on one plane. Do not expose narrow strips of the base floor or add raised trim to separate floor textures; if rooms need a physical boundary, use an actual collision wall with intentional, player-width doorways.
- Decide separately whether each prop blocks movement and sight. Low furniture such as a boardroom table may block movement while allowing eye-level detection and the rendered vision cone to pass over it; test both behaviours from every relevant worker position.

### Workers, patrols, and difficulty

- Plot every complete patrol in the whole-level snapshot, including the closing segment from the last waypoint to the first. Routes must avoid static collision, give workers enough room to turn, and keep their visible facing and sight cone aligned with their real movement and detection.
- Check each complete patrol leg as a swept worker-width path, not a zero-width line between waypoints. No leg, endpoint, or closing segment may touch or cross a wall, partition, furniture collision footprint, or doorway jamb; confirm the route by observing a full loop in gameplay.
- Space patrols across rooms and time so workers do not form an accidental cluster or repeatedly cover the same corridor in sync. Overlap should create an intentional timing puzzle, not an unavoidable wall of vision.
- Avoid tiny back-and-forth routes and repeated immediate 180-degree turns. Prefer longer loops, multi-room routes, and paths with varied shapes. Where a U-turn is intentional, give the worker a readable pause before turning.
- Use a range of worker roles across a level: long cross-room patrols, local loops or circling workers, and occasional stationary workers facing a deliberate direction. Stationary groups, such as people talking around a boardroom table, should create clear safe lanes behind their backs rather than omnidirectional coverage.
- Vary route length, direction, phase, worker appearance, and area of responsibility. Do not add difficulty only by adding more workers; combine patrol patterns, cover, route choice, and recovery opportunities.
- Check difficulty from the player's route rather than by worker count alone. Each level should introduce or combine ideas deliberately, later levels should increase complexity, and recovery resources should be spaced in proportion to risk.

### Review procedure

1. Regenerate the whole-level snapshot after any layout, patrol, start, exit, collectible, or drop-point change with `./capture-level-map.sh`. When multiple levels exist, inspect a snapshot for every level rather than assuming one representative floor is sufficient.
2. In the snapshot, trace start-to-exit connectivity, room and cubicle entrances, floor seams, prop-wall alignment, collectible sprite and pickup clearance, complete worker-width patrol loops, route overlap, cover, and camera-edge clearance.
3. Run each level headlessly with audio disabled and check for runtime errors and collision-route validation failures.
4. Play each level in the served Web build. Walk every room and both keyboard schemes; test ordinary movement, disguise routes, being caught and carried, every drop point, collectibles, the exit, and retry or progression flow.
5. Inspect the browser console and visually check sprite grounding, directional assets, sight-cone clipping, worker turns, foreground occlusion, HUD clearance, and start and exit framing before accepting the level.

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

When running the game to test or inspect it, disable or mute its sound. Only enable sound when the task specifically requires audio validation.

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

The committed [whole-level snapshot](level-layout-snapshot.png) shows the current office layout and colour-coded worker patrol routes without launching the game. Regenerate it after level-layout or patrol-route changes with:

```sh
./capture-level-map.sh
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
- OpenAI image generation uses `OPENAI_API_KEY`, which is stored locally in the repository's `.env` file. The file is gitignored and must remain uncommitted.
- Before running an OpenAI image-generation script, load the key into the current shell with `set -a; source .env; set +a`, then run the generator from that same shell. Check that it is available with `test -n "${OPENAI_API_KEY:-}"` rather than printing its value.
- Pass the key to OpenAI through the `OPENAI_API_KEY` environment variable. Never place it in prompts, command-line arguments, source files, generated metadata, or logs.
- Keep secrets and temporary generation files out of the shipped asset directories.
- Store only final game-ready assets under `assets/`.
- Run depth-bearing scenery through `tools/normalize_prop_assets.py` so transparent canvas padding does not change its declared tile dimensions.
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
