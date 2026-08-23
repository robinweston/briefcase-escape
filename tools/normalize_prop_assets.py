#!/usr/bin/env python3
"""Tightly crop transparent scenery while retaining uniform edge padding."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def remove_chroma_key(image: Image.Image, tolerance: int) -> Image.Image:
    """Convert the generated #ff00ff backdrop to alpha without touching art."""
    rgba = image.convert("RGBA")
    pixels = []
    for red, green, blue, alpha in rgba.getdata():
        distance = max(abs(red - 255), abs(green), abs(blue - 255))
        generated_magenta = (
            red >= 100
            and blue >= 100
            and abs(red - blue) <= 72
            and min(red, blue) - green >= 72
        )
        if distance <= tolerance or generated_magenta:
            pixels.append((red, green, blue, 0))
        else:
            pixels.append((red, green, blue, alpha))
    rgba.putdata(pixels)
    return rgba


def normalize(path: Path, padding_ratio: float, chroma_tolerance: int | None) -> None:
    with Image.open(path) as source:
        image = source.convert("RGBA")
        if chroma_tolerance is not None:
            image = remove_chroma_key(image, chroma_tolerance)
        alpha_bounds = image.getchannel("A").getbbox()
        if alpha_bounds is None:
            raise ValueError(f"{path}: image is fully transparent")

        left, top, right, bottom = alpha_bounds
        padding = round(max(right - left, bottom - top) * padding_ratio)
        crop_bounds = (
            max(0, left - padding),
            max(0, top - padding),
            min(image.width, right + padding),
            min(image.height, bottom + padding),
        )
        normalized = image.crop(crop_bounds)
        normalized.save(path, optimize=True)
        print(f"Normalized {path}: {image.size} -> {normalized.size}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Crop transparent scenery to its silhouette with consistent padding."
    )
    parser.add_argument("images", nargs="+", type=Path)
    parser.add_argument("--padding-ratio", type=float, default=0.04)
    parser.add_argument(
        "--chroma-key-magenta",
        action="store_true",
        help="remove a generated #ff00ff backdrop before cropping",
    )
    parser.add_argument(
        "--chroma-tolerance",
        type=int,
        default=40,
        help="maximum per-channel distance from #ff00ff (default: 40)",
    )
    args = parser.parse_args()
    if not 0.0 <= args.padding_ratio <= 0.25:
        parser.error("--padding-ratio must be between 0 and 0.25")
    if not 0 <= args.chroma_tolerance <= 64:
        parser.error("--chroma-tolerance must be between 0 and 64")

    for image_path in args.images:
        normalize(
            image_path,
            args.padding_ratio,
            args.chroma_tolerance if args.chroma_key_magenta else None,
        )


if __name__ == "__main__":
    main()
