#!/usr/bin/env python3
"""Generate the animated and ordinary briefcase vector artwork."""

from pathlib import Path


CELL_SIZE = 256
COLUMNS = 5  # idle, then four walk frames
DIRECTIONS = ("s", "e", "n", "w")

OUTLINE = "#2b180d"
LEATHER = "#a96536"
LEATHER_LIGHT = "#bd7b45"
LEATHER_DARK = "#74401f"
TRIM = "#4a2815"
CREAM = "#fff4df"
BRASS = "#d89a36"


def _hand(x: float, y: float) -> str:
    return f"""
      <circle cx="{x}" cy="{y}" r="7" fill="{LEATHER}" stroke="{OUTLINE}" stroke-width="3"/>
      <circle cx="{x - 5}" cy="{y - 5}" r="3.5" fill="{LEATHER}"/>
      <circle cx="{x + 1}" cy="{y - 7}" r="3.5" fill="{LEATHER}"/>
      <circle cx="{x + 6}" cy="{y - 3}" r="3.5" fill="{LEATHER}"/>
    """


def _arm(start_x: float, start_y: float, end_x: float, end_y: float) -> str:
    return f"""
      <path d="M {start_x} {start_y} Q {(start_x + end_x) / 2:.1f} {end_y - 2:.1f} {end_x} {end_y}"
            fill="none" stroke="{OUTLINE}" stroke-width="10" stroke-linecap="round"/>
      <path d="M {start_x} {start_y} Q {(start_x + end_x) / 2:.1f} {end_y - 2:.1f} {end_x} {end_y}"
            fill="none" stroke="{LEATHER}" stroke-width="6" stroke-linecap="round"/>
      {_hand(end_x, end_y)}
    """


def _leg(start_x: float, start_y: float, offset_x: float, foot_y: float) -> str:
    end_x = start_x + offset_x
    return f"""
      <path d="M {start_x} {start_y} Q {start_x + offset_x * 0.35:.1f} {foot_y - 20:.1f} {end_x} {foot_y - 7}"
            fill="none" stroke="{OUTLINE}" stroke-width="13" stroke-linecap="round"/>
      <path d="M {start_x} {start_y} Q {start_x + offset_x * 0.35:.1f} {foot_y - 20:.1f} {end_x} {foot_y - 7}"
            fill="none" stroke="{LEATHER_DARK}" stroke-width="8" stroke-linecap="round"/>
      <ellipse cx="{end_x + 3}" cy="{foot_y}" rx="14" ry="7" fill="{LEATHER}" stroke="{OUTLINE}" stroke-width="3"/>
    """


def _handle(view: str, bob: float) -> str:
    if view == "e":
        return f"""
          <path d="M 105 {92 + bob} V {66 + bob} Q 105 {50 + bob} 121 {50 + bob} H 139 Q 151 {50 + bob} 151 {64 + bob} V {91 + bob}"
                fill="none" stroke="{OUTLINE}" stroke-width="15" stroke-linejoin="round"/>
          <path d="M 105 {92 + bob} V {66 + bob} Q 105 {50 + bob} 121 {50 + bob} H 139 Q 151 {50 + bob} 151 {64 + bob} V {91 + bob}"
                fill="none" stroke="{LEATHER_DARK}" stroke-width="9" stroke-linejoin="round"/>
        """
    return f"""
      <path d="M 88 {91 + bob} V {63 + bob} Q 88 {45 + bob} 106 {45 + bob} H 150 Q 168 {45 + bob} 168 {63 + bob} V {91 + bob}"
            fill="none" stroke="{OUTLINE}" stroke-width="17" stroke-linejoin="round"/>
      <path d="M 88 {91 + bob} V {63 + bob} Q 88 {45 + bob} 106 {45 + bob} H 150 Q 168 {45 + bob} 168 {63 + bob} V {91 + bob}"
            fill="none" stroke="{LEATHER_DARK}" stroke-width="10" stroke-linejoin="round"/>
    """


def _eyes(view: str, bob: float) -> str:
    if view == "n":
        return ""
    if view == "e":
        return f"""
          <ellipse cx="156" cy="{96 + bob}" rx="15" ry="31" fill="{CREAM}" stroke="{OUTLINE}" stroke-width="4"/>
          <ellipse cx="163" cy="{99 + bob}" rx="8" ry="18" fill="#191512"/>
          <circle cx="166" cy="{92 + bob}" r="3" fill="white"/>
        """
    eye_positions = ((105, 25), (151, 25))
    parts = []
    for cx, rx in eye_positions:
        parts.append(
            f"""<ellipse cx="{cx}" cy="{96 + bob}" rx="{rx}" ry="34" fill="{CREAM}" stroke="{OUTLINE}" stroke-width="4"/>
            <ellipse cx="{cx + 4}" cy="{101 + bob}" rx="10" ry="20" fill="#191512"/>
            <circle cx="{cx + 7}" cy="{93 + bob}" r="3.5" fill="white"/>"""
        )
    return "\n".join(parts)


def _body(view: str, bob: float) -> str:
    if view == "e":
        return f"""
          <rect x="91" y="{86 + bob}" width="82" height="116" rx="10" fill="{LEATHER}" stroke="{OUTLINE}" stroke-width="6"/>
          <path d="M 151 {90 + bob} V {198 + bob}" stroke="{LEATHER_LIGHT}" stroke-width="7" opacity=".65"/>
          <path d="M 98 {112 + bob} H 166" stroke="{LEATHER_LIGHT}" stroke-width="5" opacity=".45"/>
        """
    return f"""
      <rect x="35" y="{83 + bob}" width="186" height="121" rx="10" fill="{LEATHER}" stroke="{OUTLINE}" stroke-width="6"/>
      <rect x="43" y="{91 + bob}" width="170" height="105" rx="6" fill="none" stroke="{LEATHER_LIGHT}" stroke-width="4" opacity=".42"/>
      <path d="M 44 {111 + bob} H 212" stroke="{LEATHER_LIGHT}" stroke-width="5" opacity=".34"/>
    """


def _face(view: str, bob: float) -> str:
    if view == "n":
        # Back seam makes the away-facing views readable without adding a new facial design.
        return f"""
          <path d="M 57 {143 + bob} Q 128 {162 + bob} 199 {143 + bob}" fill="none" stroke="{TRIM}" stroke-width="4" opacity=".6"/>
          <rect x="87" y="{101 + bob}" width="16" height="12" rx="3" fill="{BRASS}" stroke="{OUTLINE}" stroke-width="2"/>
          <rect x="153" y="{101 + bob}" width="16" height="12" rx="3" fill="{BRASS}" stroke="{OUTLINE}" stroke-width="2"/>
        """
    mouth_x = 155 if view == "e" else 128
    mouth_width = 16 if view == "e" else 35
    return f"""
      <path d="M {mouth_x - mouth_width} {150 + bob} Q {mouth_x} {177 + bob} {mouth_x + mouth_width} {150 + bob}"
            fill="none" stroke="{OUTLINE}" stroke-width="5" stroke-linecap="round"/>
    """


def _character(direction: str, frame: int) -> str:
    mirrored = direction == "w"
    view = "e" if mirrored else direction

    # Frame zero is neutral. Frames 1-4 are contact, passing, opposite contact, passing.
    cycles = (
        (0.0, 0.0, 0.0, 0.0),
        (0.0, -13.0, 13.0, 11.0),
        (-5.0, -2.0, 2.0, -2.0),
        (0.0, 13.0, -13.0, -11.0),
        (-5.0, 2.0, -2.0, 2.0),
    )
    bob, left_leg, right_leg, arm_swing = cycles[frame]
    body_bottom = 203 + bob
    foot_y = 225.0

    if view == "e":
        left_leg_x, right_leg_x = 116.0, 142.0
        left_arm_x, right_arm_x = 94.0, 170.0
        arm_reach = 28.0
    else:
        left_leg_x, right_leg_x = 102.0, 154.0
        left_arm_x, right_arm_x = 37.0, 219.0
        arm_reach = 27.0

    left_hand_x = left_arm_x - arm_reach
    right_hand_x = right_arm_x + arm_reach
    left_hand_y = 141.0 + bob + arm_swing
    right_hand_y = 141.0 + bob - arm_swing

    transform = "translate(256 0) scale(-1 1)" if mirrored else ""
    return f"""
      <g transform="{transform}">
        <ellipse cx="128" cy="228" rx="72" ry="10" fill="#1a1720" opacity=".18"/>
        {_arm(left_arm_x, 137 + bob, left_hand_x, left_hand_y)}
        {_arm(right_arm_x, 137 + bob, right_hand_x, right_hand_y)}
        {_leg(left_leg_x, body_bottom - 3, left_leg, foot_y)}
        {_leg(right_leg_x, body_bottom - 3, right_leg, foot_y)}
        {_handle(view, bob)}
        {_body(view, bob)}
        {_eyes(view, bob)}
        {_face(view, bob)}
      </g>
    """


def generate_walk_atlas() -> str:
    cells = []
    for row, direction in enumerate(DIRECTIONS):
        for column in range(COLUMNS):
            x = column * CELL_SIZE
            y = row * CELL_SIZE
            cells.append(f'<g transform="translate({x} {y})">{_character(direction, column)}</g>')

    width = COLUMNS * CELL_SIZE
    height = len(DIRECTIONS) * CELL_SIZE
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">
  <title>Briefcase four-direction idle and walk atlas</title>
  <desc>Rows: south, east, north, west. Columns: idle and four walk frames.</desc>
  {''.join(cells)}
</svg>
"""


def generate_hidden_briefcase() -> str:
    # Reuse the south-facing character's exact silhouette and palette, but replace
    # the face and limbs with ordinary case hardware.
    artwork = f"""
      <ellipse cx="128" cy="211" rx="72" ry="10" fill="#1a1720" opacity=".18"/>
      {_handle("s", 0.0)}
      {_body("s", 0.0)}
      <path d="M 43 139 H 213" stroke="{TRIM}" stroke-width="5" opacity=".72"/>
      <g fill="{BRASS}" stroke="{OUTLINE}" stroke-width="3">
        <rect x="76" y="126" width="20" height="22" rx="4"/>
        <rect x="160" y="126" width="20" height="22" rx="4"/>
      </g>
      <circle cx="86" cy="137" r="3" fill="{OUTLINE}"/>
      <circle cx="170" cy="137" r="3" fill="{OUTLINE}"/>
      <path d="M 55 181 Q 128 194 201 181" fill="none" stroke="{TRIM}" stroke-width="4" opacity=".5"/>
    """
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{CELL_SIZE}" height="{CELL_SIZE}" viewBox="0 0 {CELL_SIZE} {CELL_SIZE}">
  <title>Ordinary briefcase disguise</title>
  <desc>The animated briefcase's leather body with ordinary locks and no face or limbs.</desc>
  {artwork}
</svg>
"""


if __name__ == "__main__":
    assets = Path(__file__).resolve().parents[1] / "assets"
    walk_output = assets / "briefcase_walk.svg"
    hidden_output = assets / "briefcase_hidden.svg"
    walk_output.write_text(generate_walk_atlas(), encoding="utf-8")
    hidden_output.write_text(generate_hidden_briefcase(), encoding="utf-8")
    print(walk_output)
    print(hidden_output)
