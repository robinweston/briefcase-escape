#!/usr/bin/env python3
"""Generate four-direction animated atlases for every modular office worker.

Atlas rows: south/front, east/profile, north/back, west/mirrored profile.
Atlas columns: idle, four walk, four surprised, four cross/carry frames.
Each cell is 128x160 pixels.
"""

from pathlib import Path

import generate_office_worker_variants as workers


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "office_workers" / "animated"
CELL_W = 128
CELL_H = 160
DIRECTIONS = ("s", "e", "n", "w")
WALK_PHASES = (-1.0, 0.0, 1.0, 0.0)
REACTION_PHASES = (0.2, 0.72, 1.0, 0.88)


def _front_limbs(v: workers.WorkerVariant, state: str, phase: float) -> str:
    if state == "surprised":
        lift = phase
        hand_y = 238 - 145 * lift
        hand_x = 24 + 15 * lift
        other_x = 232 - 15 * lift
        arms = f'''<path class="ink" d="M63 195Q43 {180 - 55 * lift:.1f} {hand_x:.1f} {hand_y:.1f}M193 195Q213 {180 - 55 * lift:.1f} {other_x:.1f} {hand_y:.1f}" fill="none"/>
          <circle class="fine" cx="{hand_x:.1f}" cy="{hand_y:.1f}" r="10" fill="{v.skin}"/><circle class="fine" cx="{other_x:.1f}" cy="{hand_y:.1f}" r="10" fill="{v.skin}"/>'''
    elif state == "carry_cross":
        arms = f'''<path class="ink" d="M63 195Q83 218 112 224M193 195Q173 218 144 224" fill="none"/>
          <circle class="fine" cx="112" cy="224" r="10" fill="{v.skin}"/><circle class="fine" cx="144" cy="224" r="10" fill="{v.skin}"/>'''
    else:
        swing = phase * 17.0
        arms = f'''<path class="ink" d="M63 195Q38 216 24 {238 + swing:.1f}M193 195Q218 216 232 {238 - swing:.1f}" fill="none"/>
          <circle class="fine" cx="24" cy="{238 + swing:.1f}" r="10" fill="{v.skin}"/><circle class="fine" cx="232" cy="{238 - swing:.1f}" r="10" fill="{v.skin}"/>'''
    stride = phase * 12.0 if state in ("walk", "carry_cross") else 0.0
    legs = f'''<path class="ink" d="M86 268Q{84 - stride * .25:.1f} 286 {73 - stride:.1f} 297M170 268Q{172 + stride * .25:.1f} 286 {183 + stride:.1f} 297" fill="none"/>
      <path class="ink" d="M{74 - stride:.1f} 297q-16 12-30 0 5-18 28-15M{182 + stride:.1f} 297q16 12 30 0-5-18-28-15" fill="{v.accent_color}"/>'''
    return legs + arms


def _side_limbs(v: workers.WorkerVariant, state: str, phase: float) -> str:
    if state == "surprised":
        lift = phase
        front_y = 232 - 140 * lift
        back_y = 237 - 125 * lift
        arms = f'''<path class="ink" d="M74 194Q57 {170 - 50 * lift:.1f} 45 {back_y:.1f}M183 195Q205 {169 - 55 * lift:.1f} 219 {front_y:.1f}" fill="none"/>
          <circle class="fine" cx="45" cy="{back_y:.1f}" r="10" fill="{v.skin}"/><circle class="fine" cx="219" cy="{front_y:.1f}" r="10" fill="{v.skin}"/>'''
    elif state == "carry_cross":
        arms = f'''<path class="ink" d="M74 194Q113 214 168 221M183 195Q190 211 172 222" fill="none"/>
          <circle class="fine" cx="168" cy="221" r="10" fill="{v.skin}"/><circle class="fine" cx="172" cy="222" r="10" fill="{v.skin}"/>'''
    else:
        swing = phase * 17.0
        arms = f'''<path class="ink" d="M74 194Q51 216 40 {237 + swing:.1f}M183 195Q207 215 219 {232 - swing:.1f}" fill="none"/>
          <circle class="fine" cx="40" cy="{237 + swing:.1f}" r="10" fill="{v.skin}"/><circle class="fine" cx="219" cy="{232 - swing:.1f}" r="10" fill="{v.skin}"/>'''
    stride = phase * 12.0 if state in ("walk", "carry_cross") else 0.0
    legs = f'''<path class="ink" d="M96 268Q{92 - stride * .25:.1f} 288 {84 - stride:.1f} 297M164 268Q{169 + stride * .25:.1f} 288 {177 + stride:.1f} 297" fill="none"/>
      <path class="ink" d="M{85 - stride:.1f} 297q-16 12-30 0 5-18 28-15M{177 + stride:.1f} 297q16 12 30 0-5-18-28-15" fill="{v.accent_color}"/>'''
    return legs + arms


def _expression(state: str, front: bool = True) -> str:
    if state == "surprised":
        if front:
            return f'<path class="fine" d="M118 148Q128 132 138 148Q128 164 118 148Z" fill="{workers.INK}"/><path class="fine" d="M62 56Q90 43 116 55M140 55Q167 43 195 56" fill="none"/>'
        return f'<ellipse class="fine" cx="212" cy="150" rx="8" ry="11" fill="{workers.INK}"/><path class="fine" d="M144 55Q172 42 198 54" fill="none"/>'
    if state == "carry_cross":
        if front:
            return '<path class="fine" d="M99 158Q128 137 158 158M61 67L115 78M141 78L195 67" fill="none"/>'
        return '<path class="fine" d="M194 158Q208 144 220 158M143 72L198 82" fill="none"/>'
    return '<path class="fine" d="M96 147Q128 172 161 147" fill="none"/>' if front else '<path class="fine" d="M193 151Q210 161 219 147" fill="none"/>'


def front_pose(v: workers.WorkerVariant, state: str, phase: float) -> str:
    bob = -4.0 if state in ("walk", "carry_cross") and abs(phase) < 0.1 else 0.0
    return f'''<g transform="translate(0 {bob})">
      <ellipse cx="128" cy="302" rx="80" ry="13" fill="{workers.INK}" opacity=".12"/>
      {workers._front_hair_back(v)}{_front_limbs(v, state, phase)}{workers._front_outfit(v)}
      <path class="ink" d="M39 77Q49 20 128 14Q207 20 217 77L205 169Q128 203 51 169Z" fill="{v.skin}"/>
      {workers._front_hair(v)}{workers._front_eyes(v)}{workers._front_accessories(v)}{_expression(state)}
    </g>'''


def side_pose(v: workers.WorkerVariant, state: str, phase: float) -> str:
    bob = -4.0 if state in ("walk", "carry_cross") and abs(phase) < 0.1 else 0.0
    accessories = ""
    if v.accessory == "glasses":
        accessories = '<circle class="ink" cx="174" cy="101" r="39" fill="none"/><path class="ink" d="M211 101H228M136 101H126" fill="none"/>'
    elif v.accessory == "lashes":
        accessories = '<path class="fine" d="M196 76l9-10M190 71l5-13" fill="none"/>'
    return f'''<g transform="translate(0 {bob})">
      <ellipse cx="128" cy="302" rx="80" ry="13" fill="{workers.INK}" opacity=".12"/>
      {workers._side_hair_back(v)}{_side_limbs(v, state, phase)}
      <path class="ink" d="M70 182Q128 165 187 184L181 273Q128 289 77 273Z" fill="{v.outfit_color}"/>
      <path class="fine" d="M126 178L151 210 174 180M151 210V278" fill="{v.accent_color}"/>
      <path class="ink" d="M39 78Q51 21 126 14Q190 21 202 78L206 92 225 107 206 122 198 169Q128 202 51 169Z" fill="{v.skin}"/>
      {workers._side_hair(v)}{workers._side_eye(v)}{accessories}{_expression(state, False)}
    </g>'''


def back_pose(v: workers.WorkerVariant, state: str, phase: float) -> str:
    bob = -4.0 if state in ("walk", "carry_cross") and abs(phase) < 0.1 else 0.0
    return f'''<g transform="translate(0 {bob})">
      <ellipse cx="128" cy="302" rx="80" ry="13" fill="{workers.INK}" opacity=".12"/>
      {workers._front_hair_back(v)}{_front_limbs(v, state, phase)}{workers._front_outfit(v)}
      <path class="ink" d="M39 77Q49 20 128 14Q207 20 217 77L205 169Q128 203 51 169Z" fill="{v.skin}"/>
      <path class="ink" d="M40 82Q48 17 128 12Q208 17 216 82L204 151Q166 177 128 176Q90 177 52 151Z" fill="{v.hair_color}"/>
      <path class="fine" d="M88 162Q128 177 168 162" fill="none" opacity=".35"/>
    </g>'''


def directed_pose(v: workers.WorkerVariant, direction: str, state: str, phase: float) -> str:
    if direction == "s":
        return front_pose(v, state, phase)
    if direction == "n":
        return back_pose(v, state, phase)
    pose = side_pose(v, state, phase)
    if direction == "w":
        return f'<g transform="translate(256 0) scale(-1 1)">{pose}</g>'
    return pose


def atlas(v: workers.WorkerVariant) -> str:
    cells = []
    for row, direction in enumerate(DIRECTIONS):
        frames = [("idle", 0.0)]
        frames.extend(("walk", phase) for phase in WALK_PHASES)
        frames.extend(("surprised", phase) for phase in REACTION_PHASES)
        frames.extend(("carry_cross", phase) for phase in WALK_PHASES)
        for column, (state, phase) in enumerate(frames):
            cells.append(f'<g transform="translate({column * CELL_W} {row * CELL_H}) scale(.5)">{directed_pose(v, direction, state, phase)}</g>')
    width = CELL_W * 13
    height = CELL_H * 4
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">
      <title>{v.name} directional animation atlas</title>{workers._style()}{''.join(cells)}
    </svg>\n'''


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for variant in workers.VARIANTS:
        path = OUT_DIR / f"{variant.id}-atlas.svg"
        path.write_text(atlas(variant), encoding="utf-8")
        print(path)


if __name__ == "__main__":
    main()
