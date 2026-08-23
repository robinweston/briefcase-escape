# Briefcase Game

A small Godot 4 isometric 3D prototype. Move the briefcase around a fixed scene of people using WASD or the arrow keys.

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

## Export for the browser

The Web export preset is already configured for the Compatibility renderer and a single-threaded browser build:

```sh
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server --directory build/web 8080
```

Open `http://localhost:8080`. Web exports must be served over HTTP; opening `index.html` directly from disk is not supported.

## Project layout

- `scripts/main.gd` builds the isometric world, player, people, camera, and UI.
- `assets/briefcase.svg` is the static player image.
- `export_presets.cfg` contains the browser export settings.
