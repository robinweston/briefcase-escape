#!/usr/bin/env python3
"""Generate modular office-worker SVG assets and preview sheets.

Each worker uses the same head/body rig. Hair, eyes, outfit, palette, accessory,
and presentation metadata are selected independently in VARIANTS below.
"""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "office_workers" / "generated"
OUTPUT_DIR = ROOT / "output"
INK = "#2b2528"
CREAM = "#fff8e9"


@dataclass(frozen=True)
class WorkerVariant:
    id: str
    name: str
    presentation: str
    skin: str
    hair: str
    hair_color: str
    eyes: str
    outfit: str
    outfit_color: str
    accent_color: str
    accessory: str = "none"


# Add variants here. Every property is a swappable module.
VARIANTS = (
    WorkerVariant("a-intern", "Eager Intern", "man", "#d89a71", "side_part", "#c58b3c", "classic", "shirt", "#e5a93e", "#9e722b"),
    WorkerVariant("b-anime", "Anime Ace", "man", "#f0b58c", "full_fringe", "#252638", "anime", "jacket", "#62749a", CREAM),
    WorkerVariant("c-manager", "Tired Manager", "man", "#b97958", "neat", "#8a817d", "tired", "jacket", "#4e5962", "#d4a34c"),
    WorkerVariant("d-analyst", "Precise Analyst", "woman", "#8f6045", "bun", "#3d241f", "dot", "jacket", "#769179", CREAM, "glasses"),
    WorkerVariant("e-supervisor", "Sharp Supervisor", "man", "#e0a06d", "crop", "#b75a32", "angular", "jacket", "#a94e48", CREAM),
    WorkerVariant("f-creative", "Cheerful Creative", "woman", "#7b4d38", "wavy_bob", "#5a314f", "round", "blouse", "#d07878", "#ffe8cf", "lashes"),
)


def _style() -> str:
    return f"""
    <style>
      .ink{{stroke:{INK};stroke-width:6;stroke-linecap:round;stroke-linejoin:round}}
      .fine{{stroke:{INK};stroke-width:4;stroke-linecap:round;stroke-linejoin:round}}
    </style>"""


def _front_hair_back(v: WorkerVariant) -> str:
    if v.hair == "bun":
        return f'<circle class="ink" cx="75" cy="61" r="31" fill="{v.hair_color}"/>'
    if v.hair == "wavy_bob":
        return f'<path class="ink" d="M39 75Q48 15 128 12Q210 18 218 76L207 183Q188 203 169 177Q151 205 130 179Q107 205 88 178Q65 201 48 180Z" fill="{v.hair_color}"/>'
    return ""


def _front_hair(v: WorkerVariant) -> str:
    paths = {
        "side_part": "M42 76Q60 17 130 13Q191 18 214 78Q161 56 123 70Q78 88 42 76Z",
        "full_fringe": "M41 78Q52 15 128 11Q207 16 215 78L190 54 173 84 151 49 128 83 104 47 82 82 61 52Z",
        "neat": "M41 77Q62 17 139 13Q193 20 215 72Q170 58 135 68Q78 84 41 77Z",
        "bun": "M42 79Q62 17 136 13Q199 18 214 73Q168 56 130 68Q77 84 42 79Z",
        "crop": "M41 77Q54 22 107 13L125 43 144 12Q198 22 215 78Q169 59 128 69Q79 84 41 77Z",
        "wavy_bob": "M40 79Q44 16 108 11Q133 10 145 27Q170 7 194 32Q216 52 215 85L194 60 174 86 151 53 128 84 103 52 80 86 61 58Z",
    }
    return f'<path class="ink" d="{paths[v.hair]}" fill="{v.hair_color}"/>'


def _front_eyes(v: WorkerVariant) -> str:
    if v.eyes == "tired":
        return f'<path class="fine" d="M62 100Q91 83 117 101Q91 124 65 104ZM139 101Q166 83 195 100L192 104Q165 124 139 101Z" fill="{CREAM}"/><circle cx="93" cy="104" r="5" fill="{INK}"/><circle cx="166" cy="104" r="5" fill="{INK}"/><path class="fine" d="M61 89Q89 73 118 89M139 89Q168 73 197 89" fill="none"/>'
    if v.eyes == "angular":
        return f'<path class="fine" d="M61 96L117 86Q111 121 70 119ZM139 86L195 96 186 119Q145 121 139 86Z" fill="{CREAM}"/><ellipse cx="94" cy="105" rx="7" ry="14" fill="{INK}"/><ellipse cx="162" cy="105" rx="7" ry="14" fill="{INK}"/><path class="ink" d="M61 75L116 65M140 65L195 75" fill="none"/>'
    outer = '<ellipse class="fine" cx="91" cy="99" rx="28" ry="36" fill="%s"/><ellipse class="fine" cx="165" cy="99" rx="28" ry="36" fill="%s"/>' % (CREAM, CREAM)
    if v.eyes == "dot":
        return outer + f'<circle cx="93" cy="103" r="6" fill="{INK}"/><circle cx="167" cy="103" r="6" fill="{INK}"/>'
    if v.eyes == "anime":
        return outer + f'<ellipse cx="91" cy="102" rx="15" ry="23" fill="#735b9f"/><ellipse cx="165" cy="102" rx="15" ry="23" fill="#735b9f"/><ellipse cx="91" cy="106" rx="8" ry="14" fill="{INK}"/><ellipse cx="165" cy="106" rx="8" ry="14" fill="{INK}"/><path d="M84 91l3 6 6 3-6 3-3 6-3-6-6-3 6-3ZM158 91l3 6 6 3-6 3-3 6-3-6-6-3 6-3Z" fill="white"/>'
    if v.eyes == "round":
        return outer + f'<circle cx="93" cy="103" r="14" fill="{INK}"/><circle cx="167" cy="103" r="14" fill="{INK}"/><circle cx="98" cy="96" r="4" fill="white"/><circle cx="172" cy="96" r="4" fill="white"/>'
    return outer + f'<ellipse cx="96" cy="105" rx="10" ry="20" fill="{INK}"/><ellipse cx="170" cy="105" rx="10" ry="20" fill="{INK}"/><circle cx="99" cy="97" r="3.5" fill="white"/><circle cx="173" cy="97" r="3.5" fill="white"/>'


def _front_outfit(v: WorkerVariant) -> str:
    base = f'<path class="ink" d="M59 183Q128 161 197 183L188 273Q128 291 68 273Z" fill="{v.outfit_color}"/>'
    if v.outfit == "shirt":
        detail = f'<path class="fine" d="M93 179L128 216 163 179M128 216V278" fill="none" stroke="{v.accent_color}"/>'
    elif v.outfit == "blouse":
        detail = f'<path class="fine" d="M96 179L128 211 160 179M128 211V278" fill="{v.accent_color}"/>'
    else:
        detail = f'<path class="fine" d="M91 179L128 220 165 179M128 220V278" fill="{v.accent_color}"/>'
    return base + detail


def _front_accessories(v: WorkerVariant) -> str:
    parts = []
    if v.accessory == "glasses":
        parts.append(f'<circle class="ink" cx="91" cy="99" r="38" fill="none"/><circle class="ink" cx="165" cy="99" r="38" fill="none"/><path class="ink" d="M129 99H127M53 99H40M203 99H216" fill="none"/>')
    if v.accessory == "lashes":
        parts.append('<path class="fine" d="M65 72l-10-9M72 66l-5-13M191 72l10-9M184 66l5-13" fill="none"/>')
    return "".join(parts)


def front_character(v: WorkerVariant) -> str:
    return f"""
    <g>
      <ellipse cx="128" cy="302" rx="80" ry="13" fill="{INK}" opacity=".12"/>
      {_front_hair_back(v)}
      <path class="ink" d="M86 268Q80 292 73 297M170 268Q176 292 183 297" fill="none"/>
      <path class="ink" d="M74 297q-16 12-30 0 5-18 28-15M182 297q16 12 30 0-5-18-28-15" fill="{v.accent_color}"/>
      <path class="ink" d="M63 195Q35 218 24 238M193 195Q221 218 232 238" fill="none"/>
      <circle class="fine" cx="24" cy="238" r="10" fill="{v.skin}"/><circle class="fine" cx="232" cy="238" r="10" fill="{v.skin}"/>
      {_front_outfit(v)}
      <path class="ink" d="M39 77Q49 20 128 14Q207 20 217 77L205 169Q128 203 51 169Z" fill="{v.skin}"/>
      {_front_hair(v)}
      {_front_eyes(v)}
      {_front_accessories(v)}
      <path class="fine" d="M96 147Q128 172 161 147" fill="none"/>
    </g>"""


def _side_hair_back(v: WorkerVariant) -> str:
    if v.hair == "bun":
        return f'<circle class="ink" cx="62" cy="62" r="31" fill="{v.hair_color}"/>'
    if v.hair == "wavy_bob":
        return f'<path class="ink" d="M39 77Q51 17 132 14Q198 24 205 85L191 185Q173 203 157 178Q137 201 120 177Q96 200 75 175Q55 193 44 171Z" fill="{v.hair_color}"/>'
    return ""


def _side_hair(v: WorkerVariant) -> str:
    paths = {
        "side_part": "M39 80Q59 18 135 15Q188 23 201 79Q148 60 104 73Q68 85 39 80Z",
        "full_fringe": "M39 80Q52 17 128 14Q189 19 202 78L181 59 163 88 143 55 123 87 102 53 81 85 60 57Z",
        "neat": "M39 80Q62 19 141 16Q191 24 202 78Q153 62 110 73Q68 85 39 80Z",
        "bun": "M39 80Q61 18 139 15Q191 22 202 78Q153 61 109 73Q68 85 39 80Z",
        "crop": "M39 80Q54 24 110 14L128 45 146 13Q193 25 202 79Q153 62 110 73Q68 85 39 80Z",
        "wavy_bob": "M39 80Q45 17 111 13Q139 12 151 30Q175 10 197 37Q207 53 203 85L185 62 167 88 147 57 128 86 107 55 86 88 63 60Z",
    }
    return f'<path class="ink" d="{paths[v.hair]}" fill="{v.hair_color}"/>'


def _side_eye(v: WorkerVariant) -> str:
    if v.eyes == "tired":
        return f'<path class="fine" d="M142 102Q170 86 195 102Q170 124 145 107Z" fill="{CREAM}"/><circle cx="174" cy="106" r="5" fill="{INK}"/><path class="fine" d="M142 91Q170 76 197 91" fill="none"/>'
    if v.eyes == "angular":
        return f'<path class="fine" d="M140 96L197 86 188 120Q149 121 140 96Z" fill="{CREAM}"/><ellipse cx="174" cy="107" rx="7" ry="14" fill="{INK}"/><path class="ink" d="M140 74L198 64" fill="none"/>'
    outer = f'<ellipse class="fine" cx="174" cy="101" rx="28" ry="36" fill="{CREAM}"/>'
    if v.eyes == "anime":
        return outer + f'<ellipse cx="176" cy="104" rx="15" ry="23" fill="#735b9f"/><ellipse cx="179" cy="108" rx="8" ry="14" fill="{INK}"/><path d="M169 93l3 6 6 3-6 3-3 6-3-6-6-3 6-3Z" fill="white"/>'
    if v.eyes == "dot":
        return outer + f'<circle cx="181" cy="105" r="6" fill="{INK}"/>'
    if v.eyes == "round":
        return outer + f'<circle cx="181" cy="105" r="14" fill="{INK}"/><circle cx="186" cy="98" r="4" fill="white"/>'
    return outer + f'<ellipse cx="182" cy="107" rx="10" ry="20" fill="{INK}"/><circle cx="185" cy="99" r="3.5" fill="white"/>'


def side_character(v: WorkerVariant) -> str:
    accessories = ""
    if v.accessory == "glasses":
        accessories = f'<circle class="ink" cx="174" cy="101" r="39" fill="none"/><path class="ink" d="M211 101H228M136 101H126" fill="none"/>'
    if v.accessory == "lashes":
        accessories = '<path class="fine" d="M196 76l9-10M190 71l5-13" fill="none"/>'
    return f"""
    <g>
      <ellipse cx="128" cy="302" rx="80" ry="13" fill="{INK}" opacity=".12"/>
      {_side_hair_back(v)}
      <path class="ink" d="M96 268Q91 291 84 297M164 268Q170 291 177 297" fill="none"/>
      <path class="ink" d="M85 297q-16 12-30 0 5-18 28-15M177 297q16 12 30 0-5-18-28-15" fill="{v.accent_color}"/>
      <path class="ink" d="M74 194Q51 216 40 237M183 195Q207 215 219 232" fill="none"/>
      <circle class="fine" cx="40" cy="237" r="10" fill="{v.skin}"/><circle class="fine" cx="219" cy="232" r="10" fill="{v.skin}"/>
      <path class="ink" d="M70 182Q128 165 187 184L181 273Q128 289 77 273Z" fill="{v.outfit_color}"/>
      <path class="fine" d="M126 178L151 210 174 180M151 210V278" fill="{v.accent_color}"/>
      <path class="ink" d="M39 78Q51 21 126 14Q190 21 202 78L206 92 225 107 206 122 198 169Q128 202 51 169Z" fill="{v.skin}"/>
      {_side_hair(v)}
      {_side_eye(v)}
      {accessories}
      <path class="fine" d="M193 151Q210 161 219 147" fill="none"/>
    </g>"""


def svg_document(content: str) -> str:
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="320" viewBox="0 0 256 320"><title>Modular office worker</title>{_style()}{content}</svg>\n'


def preview_sheet(view: str) -> str:
    render = front_character if view == "front" else side_character
    groups = []
    for index, variant in enumerate(VARIANTS):
        column = index % 2
        row = index // 2
        x = 48 + column * 492
        y = 132 + row * 432
        groups.append(f'''<g transform="translate({x} {y})">
          <rect width="456" height="400" rx="28" fill="#fffaf0" stroke="#eadfce" stroke-width="3"/>
          <text x="26" y="45" font-family="system-ui,sans-serif" font-size="28" font-weight="700" fill="#322a2b">{variant.name}</text>
          <text x="26" y="75" font-family="system-ui,sans-serif" font-size="17" fill="#756568">{variant.presentation} · {variant.hair} · {variant.outfit}</text>
          <g transform="translate(100 72)">{render(variant)}</g>
        </g>''')
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1428" viewBox="0 0 1024 1428">
      <title>Modular office worker {view} variants</title>{_style()}
      <rect width="1024" height="1428" fill="#f3eadc"/>
      <text x="48" y="65" font-family="system-ui,sans-serif" font-size="34" font-weight="800" fill="#2b2528">MODULAR OFFICE WORKERS — {view.upper()}</text>
      <text x="48" y="100" font-family="system-ui,sans-serif" font-size="20" fill="#756568">Shared rig · swappable hair · eyes · outfits · colours · accessories</text>
      {''.join(groups)}
    </svg>\n'''


def main() -> None:
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    manifest = []
    for variant in VARIANTS:
        front_name = f"{variant.id}-front.svg"
        side_name = f"{variant.id}-side.svg"
        (ASSET_DIR / front_name).write_text(svg_document(front_character(variant)), encoding="utf-8")
        (ASSET_DIR / side_name).write_text(svg_document(side_character(variant)), encoding="utf-8")
        manifest.append({**asdict(variant), "front": front_name, "side": side_name})
    (ASSET_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    (OUTPUT_DIR / "office-worker-modular-front.svg").write_text(preview_sheet("front"), encoding="utf-8")
    (OUTPUT_DIR / "office-worker-modular-side.svg").write_text(preview_sheet("side"), encoding="utf-8")
    print(f"Generated {len(VARIANTS)} worker variants in {ASSET_DIR}")


if __name__ == "__main__":
    main()
