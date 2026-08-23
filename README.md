# Briefcase Game

A top-down stealth game built with Godot 4. Guide a briefcase through a scrolling maze of office cubicles to the exit without entering a patrolling worker's visible field of vision. Being seen resets the level.

Move in four cardinal directions with `WASD` or the arrow keys. Paired directional input resolves to a single axis, so there is no diagonal movement.

Office workers also move only in the four cardinal directions while patrolling, approaching, and carrying the briefcase. A worker's vision cone and detection switch off while they put a disguised briefcase away and return to their patrol route.

You begin as an ordinary briefcase. After one second, it automatically comes to life; gameplay controls are ignored until that transformation finishes. Movement is always disabled while disguised. The opening disguise does not consume disguise time; later disguises spend it. Workers carry a disguised briefcase to the nearest cubicle instead of catching it. Disguise time starts at five seconds and only recharges by collecting the scattered potion bottles; each bottle restores one second, up to the five-second maximum. Once spotted in disguise, the timer pauses and movement and transformation controls remain locked until the worker puts the briefcase down. The disguise is free for three seconds after the drop, but `Space` can transform back immediately.

Press `P` to pause or resume the game.

Major actions use the selected soft-office sound-effect set: starting, walking,
transforming, collecting potions, worker alerts, pickup/drop, being caught,
completing the level, and pausing/resuming all have distinct cues.

The game opens on the **Briefcase Escape** title screen. Review the instructions and controls there, then press `Space`, `Enter`, or gamepad Start to begin. After the worker's surprise animation, being caught opens an **Escape Report**; press `Space` to retry. Reaching the exit opens the matching cleared report; press Start to continue to the next floor. There are three distinct floors: a forgiving introduction, a boardroom with six stationary coworkers facing into their conversation, and the full office challenge. Clearing floor three offers a fresh run from floor one.

The title screen and first level share a continuous loop of **Stealth in the
Woods**, layered with busy office chatter, phones, writing, and typing.

## Run locally

1. Install Godot 4.3 or newer and its Web export templates.
2. Open this directory in Godot and press **F6** or **F5**.

Or launch the browser version directly:

```sh
./start-game.sh
```

Press `Ctrl+C` to stop it. To use another port or skip opening the browser:

```sh
BRIEFCASE_PORT=8081 BRIEFCASE_OPEN_BROWSER=0 ./start-game.sh
```

Automated tests and direct Godot runs can bypass the title screen with either
`--skip-title` (passed as a Godot user argument) or `BRIEFCASE_SKIP_TITLE=1`:

```sh
godot --headless --path . --quit-after 3 -- --skip-title
BRIEFCASE_SKIP_TITLE=1 godot --headless --path . --quit-after 3
```

The launcher keeps the server running and automatically re-exports when Godot source files or assets change. Refresh the browser after the terminal prints `Build updated`. Disable watching when needed with:

```sh
BRIEFCASE_WATCH=0 ./start-game.sh
```

## View the asset gallery

Open the standalone Godot asset gallery without starting the game:

```sh
./view-gallery.sh
```

The **People** tab displays every worker simultaneously, with menus for changing
animation and direction plus a pause button. The **Briefcase** tab previews its
directional idle/walk artwork alongside the ordinary disguise. Keyboard shortcuts
remain available: use `W`/`S` for worker animation, `A`/`D` for direction, and
`Space` to pause. The **Scenery** tab displays
the workstation, divider, filing cabinet, plant, start marker, exit sign, and
exit marker. The **Audio** tab contains a **Music** section comparing four CC0
tension/stealth candidates and a **Sound FX** section with three original options
for each of 12 major game actions. Music can be auditioned alone or with the
busier real-office ambience layer, and the ambience can also be played by itself.
The sound-effect rows are grouped by action so their soft-office, retro-arcade,
and cinematic/cartoon directions can be compared directly. Option 1, the
soft-office set, is marked as selected and is wired into gameplay. Click
**Reload assets** after changing or generating artwork; the
gallery restarts, imports changed files, and returns to the selected tab. In the
Godot editor you can also open `asset_gallery.tscn` and press **F6**. Godot's
SpriteFrames editor previews one sprite animation; this gallery is provided to
compare the complete cast.

The **Level Map** tab contains separate **Level 1**, **Level 2**, and **Level 3**
tabs showing each live layout, its patrol overlays, and its stationary-worker
count.

Run `./capture-level-map.sh` to regenerate whole-floor snapshots for all three
levels. Floor one keeps the legacy `level-layout-snapshot.png` filename; floors
two and three use numbered snapshot filenames.

## Export for the browser

The Web export preset is already configured for the Compatibility renderer and a single-threaded browser build:

```sh
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server --directory build/web 8080
```

Open `http://localhost:8080`. Web exports must be served over HTTP; opening `index.html` directly from disk is not supported.

## Deploy with GitHub Pages

The `Deploy game to GitHub Pages` workflow exports and deploys the Web build
whenever `main` is updated. It can also be run manually from the repository's
**Actions** tab.

Before the first deployment, open **Settings → Pages** in GitHub and select
**GitHub Actions** as the publishing source. After the first successful run, add
the site's domain under **Settings → Pages → Custom domain**, configure the
matching DNS records with the domain provider, and enable **Enforce HTTPS** once
GitHub has issued the certificate.

## Project layout

- `scripts/main.gd` builds the top-down world, player, people, camera, and UI.
- `scripts/title_screen.gd` builds the title, static chase banner, objective, and controls screen.
- `assets/title_banner.png` is the generated all-in-one title and office-chase artwork.
- `assets/fonts/` contains the OFL-licensed Oswald and IBM Plex Mono title-screen fonts.
- `assets/briefcase_walk.svg` is the four-direction idle/walk atlas used by the player.
- `assets/briefcase_hidden.svg` is the matching ordinary-case disguise artwork.
- `assets/briefcase.svg` remains as the original static player-art fallback.
- `assets/scenery/generated/` contains the illustrated workstation, divider,
  cabinet, plant, printer, vending machine, bathroom fixtures, boardroom table,
  exit-sign, and disguise-potion sprites used by the level and gallery.
- `assets/audio/` contains the CC0 music candidates, busy office ambience, 36 original sound-effect candidates, and source/license notes.
- `tools/generate_briefcase_walk_atlas.py` regenerates both matching briefcase vector assets.
- `tools/generate_office_worker_variants.py` defines modular worker appearances.
- `tools/generate_office_worker_animations.py` regenerates worker animation atlases.
- `tools/office_prop_prompts.jsonl` records the OpenAI Image API prompt set for
  generated office scenery, including the boardroom table.
- `tools/office_prop_rotation_manifest.json` defines the reference-image prompts,
  filenames, and S/E/N/W ordering for directional static-prop views.
- `tools/generate_sound_effects.py` regenerates the original procedural sound-effect candidates.
- `asset_gallery.tscn` provides a standalone home for animated and static asset previews.
- `export_presets.cfg` contains the browser export settings.
