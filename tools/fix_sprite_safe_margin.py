"""Shrink frame content so transparent margin is >= safe_px on all sides."""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def content_bbox(im: Image.Image) -> tuple[int, int, int, int] | None:
    px = im.load()
    w, h = im.size
    xs, ys = [], []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] >= 20:
                xs.append(x)
                ys.append(y)
    if not xs:
        return None
    return min(xs), min(ys), max(xs), max(ys)


def fix_one(path: Path, safe: int, force_scale: float | None = None) -> bool:
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    bb = content_bbox(im)
    if bb is None:
        return False
    x0, y0, x1, y1 = bb
    cw, ch = x1 - x0 + 1, y1 - y0 + 1
    max_w = w - 2 * safe
    max_h = h - 2 * safe
    scale = min(max_w / cw, max_h / ch)
    if force_scale is not None:
        scale = min(scale, force_scale)
    if scale >= 0.995:
        # already fits with margin; still re-center if needed
        scale = 1.0

    if scale < 0.995:
        new_w = max(1, int(round(cw * scale)))
        new_h = max(1, int(round(ch * scale)))
        crop = im.crop((x0, y0, x1 + 1, y1 + 1)).resize((new_w, new_h), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        # center content
        ox = (w - new_w) // 2
        oy = (h - new_h) // 2
        canvas.alpha_composite(crop, (ox, oy))
        canvas.save(path)
        return True

    # re-center existing content if margins uneven
    margins = (x0, y0, w - 1 - x1, h - 1 - y1)
    if min(margins) >= safe and max(margins) - min(margins) <= 2:
        return False
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    crop = im.crop((x0, y0, x1 + 1, y1 + 1))
    ox = (w - cw) // 2
    oy = (h - ch) // 2
    canvas.alpha_composite(crop, (ox, oy))
    canvas.save(path)
    return True


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("roots", nargs="+")
    p.add_argument("--safe", type=int, default=8)
    p.add_argument("--scale", type=float, default=None)
    args = p.parse_args()
    files: list[Path] = []
    for r in args.roots:
        path = Path(r)
        if path.is_file():
            files.append(path)
        else:
            files.extend(sorted(path.rglob("*.png")))
    changed = 0
    for f in files:
        if fix_one(f, args.safe, args.scale):
            changed += 1
            print("fixed", f.name)
    print(f"changed={changed}/{len(files)}")


if __name__ == "__main__":
    main()
