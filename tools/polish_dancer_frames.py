# Polish dancer frames: quantize + optional pixel-block for in-game crispness.
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "sprites" / "monsters" / "pollen_queen"


def quantize_rgba(img: Image.Image, colors: int) -> Image.Image:
    """Quantize RGB while keeping alpha. Median-cut on opaque pixels only."""
    rgba = img.convert("RGBA")
    a = rgba.getchannel("A")
    rgb = rgba.convert("RGB")
    q = rgb.quantize(colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    out = q.convert("RGBA")
    out.putalpha(a)
    return out


def pixelate_content(img: Image.Image, block: int) -> Image.Image:
    """Snap opaque content to a block grid via downscale-box + NEAREST upscale."""
    if block <= 1:
        return img
    rgba = img.convert("RGBA")
    a = rgba.getchannel("A")
    rgb = rgba.convert("RGB")
    w, h = rgb.size
    sw = max(1, w // block)
    sh = max(1, h // block)
    small = rgb.resize((sw, sh), Image.Resampling.BOX)
    big = small.resize((w, h), Image.Resampling.NEAREST)
    # alpha: harden then same snap so edges stay chunky
    a_small = a.resize((sw, sh), Image.Resampling.BOX)
    a_big = a_small.resize((w, h), Image.Resampling.NEAREST)
    # re-threshold alpha after snap
    ap = a_big.load()
    for y in range(h):
        for x in range(w):
            ap[x, y] = 255 if ap[x, y] >= 128 else 0
    out = big.convert("RGBA")
    out.putalpha(a_big)
    return out


def count_colors(img: Image.Image) -> int:
    px = img.convert("RGBA").load()
    cols = set()
    for y in range(img.height):
        for x in range(img.width):
            if px[x, y][3] > 10:
                cols.add(px[x, y][:3])
    return len(cols)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--form", default="dancer")
    p.add_argument("--states", default="idle,move")
    p.add_argument("--colors", type=int, default=48)
    p.add_argument("--block", type=int, default=2)
    p.add_argument("--dry-run", action="store_true")
    args = p.parse_args()

    states = [s.strip() for s in args.states.split(",") if s.strip()]
    for state in states:
        for i in range(6):
            path = OUT / f"pollen_queen_{args.form}_{state}_{i:02d}.png"
            if not path.exists():
                print("MISSING", path.name)
                continue
            src = Image.open(path).convert("RGBA")
            before = count_colors(src)
            # pixel-block first, then quantize (quantize-before-pixelate re-creates colors via BOX)
            work = pixelate_content(src, args.block)
            work = quantize_rgba(work, args.colors)
            after = count_colors(work)
            print(f"{path.name} colors {before}->{after} block={args.block} q={args.colors}")
            if not args.dry_run:
                work.save(path)


if __name__ == "__main__":
    main()
