"""Audit boss frames for in-game rectangular-border artifacts.

Flags:
- EDGE_TOUCH: opaque content touches/nearly touches canvas edge (cut wings / box rim)
- TIGHT_MARGIN: min transparent margin < safe_px
- RECT_RESIDUE: large opaque blob outside main body component near frame border
- STRAIGHT_CUT: long straight run of opaque pixels along a canvas edge
- MAGENTA_EDGE: chroma residue on/near edges
"""
from __future__ import annotations

import argparse
import sys
from collections import deque
from pathlib import Path

from PIL import Image

SAFE_PX = 4
STRAIGHT_MIN = 24
RESIDUE_MIN = 40


def is_magentaish(r: int, g: int, b: int, a: int) -> bool:
    if a < 20:
        return False
    return r > 180 and b > 140 and g < 100 and (r - g) > 60 and (b - g) > 40


def analyze(path: Path, safe_px: int = SAFE_PX) -> dict:
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    px = im.load()

    xs: list[int] = []
    ys: list[int] = []
    edge_opaque = {"t": 0, "b": 0, "l": 0, "r": 0}
    magenta_edge = 0

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 20:
                continue
            xs.append(x)
            ys.append(y)
            if y == 0:
                edge_opaque["t"] += 1
            if y == h - 1:
                edge_opaque["b"] += 1
            if x == 0:
                edge_opaque["l"] += 1
            if x == w - 1:
                edge_opaque["r"] += 1
            if x <= 2 or y <= 2 or x >= w - 3 or y >= h - 3:
                if is_magentaish(r, g, b, a):
                    magenta_edge += 1

    flags: list[str] = []
    details: dict = {"file": path.name}

    if not xs:
        flags.append("EMPTY")
        details["flags"] = flags
        return details

    bb = (min(xs), min(ys), max(xs), max(ys))
    margins = {
        "left": bb[0],
        "top": bb[1],
        "right": w - 1 - bb[2],
        "bottom": h - 1 - bb[3],
    }
    min_margin = min(margins.values())
    details["bbox"] = bb
    details["margins"] = margins
    details["min_margin"] = min_margin
    details["edge_opaque"] = edge_opaque
    details["magenta_edge"] = magenta_edge

    if any(edge_opaque[k] > 8 for k in edge_opaque):
        flags.append("EDGE_TOUCH")
    if min_margin < safe_px:
        flags.append("TIGHT_MARGIN")
    if magenta_edge > 12:
        flags.append("MAGENTA_EDGE")

    # Straight-cut: long continuous opaque run on a border line
    def max_run(coords: list[tuple[int, int]]) -> int:
        if not coords:
            return 0
        best = run = 1
        for i in range(1, len(coords)):
            if coords[i][0] == coords[i - 1][0] + 1 and coords[i][1] == coords[i - 1][1]:
                run += 1
                best = max(best, run)
            else:
                run = 1
        return best

    top_run = max_run([(x, 0) for x in range(w) if px[x, 0][3] >= 20])
    bot_run = max_run([(x, h - 1) for x in range(w) if px[x, h - 1][3] >= 20])
    left_run = max_run([(y, 0) for y in range(h) if px[0, y][3] >= 20])
    right_run = max_run([(y, 0) for y in range(h) if px[w - 1, y][3] >= 20])
    details["straight_runs"] = {
        "top": top_run,
        "bottom": bot_run,
        "left": left_run,
        "right": right_run,
    }
    if max(top_run, bot_run, left_run, right_run) >= STRAIGHT_MIN:
        flags.append("STRAIGHT_CUT")

    # Residue: opaque components that do not touch main bbox interior much
    # Simple: count opaque pixels in 3px frame band that are isolated from center mass
    band = 0
    for y in range(h):
        for x in range(w):
            if x >= 3 and y >= 3 and x < w - 3 and y < h - 3:
                continue
            if px[x, y][3] >= 20:
                band += 1
    details["border_band_opaque"] = band
    # If border band has content AND bbox is nearly full canvas → crop/box risk
    if band >= RESIDUE_MIN and min_margin < safe_px * 2:
        flags.append("RECT_RESIDUE")

    details["flags"] = flags
    return details


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("roots", nargs="+", help="directories of png frames")
    p.add_argument("--safe", type=int, default=SAFE_PX)
    args = p.parse_args()

    roots = [Path(r) for r in args.roots]
    files: list[Path] = []
    for root in roots:
        if root.is_file():
            files.append(root)
        else:
            files.extend(sorted(root.rglob("*.png")))

    bad: list[dict] = []
    total = 0
    for f in files:
        total += 1
        d = analyze(f, safe_px=args.safe)
        if d.get("flags"):
            bad.append(d)

    print(f"scanned={total} flagged={len(bad)}")
    for d in bad:
        print(
            f"{d['file']}: flags={d['flags']} min_margin={d.get('min_margin')} "
            f"bbox={d.get('bbox')} edge={d.get('edge_opaque')} "
            f"runs={d.get('straight_runs')} band={d.get('border_band_opaque')} "
            f"mag={d.get('magenta_edge')}"
        )
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
