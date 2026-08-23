# Audio sources and licenses

These are unmodified third-party recordings downloaded for soundtrack review.
All five files are available under Creative Commons Zero (CC0), so they may be
used, modified, and distributed in commercial projects without attribution.
Source links are retained here for provenance.

## Music candidates

- `stealth_in_the_woods.mp3` — **Stealth Music** by Lisboa.
  Source: <https://opengameart.org/content/stealth-music>
- `suspense.ogg` — **Suspense** by wipics.
  Source: <https://opengameart.org/content/suspense-0>
- `time_constraints.mp3` — **Time Constraints** by tapatilorenzo.
  Source: <https://opengameart.org/content/midi-2-tension-songs>
- `tension.mp3` — **Tension** by tapatilorenzo.
  Source: <https://opengameart.org/content/midi-2-tension-songs>

The OpenGameArt source pages mark each work as CC0.

## Office ambience

- `busy_office_ambience.mp3` — **Office Ambience** by DiArchangeli. A real
  busy-office soundscape with conversation, telephone, writing, and typing.
  Original CC0 source: <https://freesound.org/people/DiArchangeli/sounds/108695/>
  Download mirror: <https://pixabay.com/sound-effects/city-office-ambience-6322/>

The original Freesound page marks the recording as CC0. The Pixabay mirror also
permits free use and modification under the Pixabay Content License.

## Original sound-effect candidates

The `sfx/` directory contains three original procedural candidates for each of
11 major game actions: game start, disguise on/off, potion pickup,
worker alert, briefcase pickup/drop, caught/reset, level complete, pause, and
resume. Option 1 uses a softer office-friendly palette, option 2 is deliberately
retro/arcade-like, and option 3 is more cinematic or cartoon-like.

These sounds were synthesized specifically for this project and contain no
third-party recordings. Regenerate them with:

```sh
python3 tools/generate_sound_effects.py
```

Files use the naming pattern `<action>_<option>.wav`. They are mono 44.1 kHz
16-bit PCM WAV files for straightforward Godot and Web-export compatibility.
Option 1, the soft-office direction, is currently selected for every gameplay
action; Options 2 and 3 remain in the gallery for comparison.
