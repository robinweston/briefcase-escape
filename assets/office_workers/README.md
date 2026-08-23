# Modular office workers

`tools/generate_office_worker_variants.py` builds every worker from the same
head/body rig and independent modules for:

- skin tone
- hair style and colour
- eye style
- outfit style, primary colour, and accent colour
- accessories
- presentation metadata

Add or duplicate a `WorkerVariant` entry in `VARIANTS`, then regenerate:

```sh
python3 tools/generate_office_worker_variants.py
```

Generated front and side SVGs are written to `assets/office_workers/generated/`.
The manifest records the selected modules for every asset. Preview sheets are
written to `output/office-worker-modular-front.svg` and
`output/office-worker-modular-side.svg`.

Regenerate the four-direction idle, walk, surprised, and cross/carry atlases:

```sh
python3 tools/generate_office_worker_animations.py
```

Animation atlases are written to `assets/office_workers/animated/`. They use
128×160 cells with four direction rows. Shared atlas slicing lives in
`scripts/worker_sprite_frames.gd` so the game and gallery cannot drift apart.

Gender presentation is metadata and a styling choice, not a separate body rig.
All hair, eye, outfit, colour, and accessory modules can be combined freely.
The current cast contains eight distinct workers so each of the six rooms can
remain staffed while the two busier rooms retain their overlapping patrols.
