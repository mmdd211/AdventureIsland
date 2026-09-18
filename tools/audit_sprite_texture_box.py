"""Detect animation frames whose texture rectangle will be visible in-game.

Flags within each animation clip:
- FRAME_JITTER: content bbox w/h varies too much frame-to-frame (box size pops)
- FX_CLIP: opaque pixels touch canvas edge (FX cut by texture rect)
- NEAR_FULL: content fills >92% of canvas width/height (rect almost fully used)
"""
from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path

from PIL import Image

CLIP_RE = re.compile(r"^(?P<prefix>.+)_(?P<form>[^_]+)_(?P<state>[^_]+)_(?P<idx>\d+)\.png$")


def bbox_of(path: Path):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    px = im.load()
    xs, ys = [], []
    edge = 0
    for y in range(h):
        for x in range(w):
            if px[x, y][3] >= 20:
                xs.append(x)
                ys.append(y)
                if x == 0 or y == 0 or x == w - 1 or y == h - 1:
                    edge += 1
    if not xs:
        return None
    return (min(xs), min(ys), max(xs), max(ys), w, h, edge)


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("root")
    p.add_argument("--jitter", type=float, default=0.18, help="max relative bbox size delta")
    p.add_argument("--full", type=float, default=0.92)
    args = p.parse_args()
    root = Path(args.root)
    clips: dict[str, list[tuple[str, dict]]] = defaultdict(list)

    for f in sorted(root.glob("*.png")):
        m = CLIP_RE.match(f.name)
        if not m:
            continue
        bb = bbox_of(f)
        if not bb:
            continue
        x0, y0, x1, y1, w, h, edge = bb
        cw, ch = x1 - x0 + 1, y1 - y0 + 1
        clips[f"{m['prefix']}_{m['form']}_{m['state']}"].append(
            (
                f.name,
                {
                    "cw": cw,
                    "ch": ch,
                    "w": w,
                    "h": h,
                    "edge": edge,
                    "fill_w": cw / w,
                    "fill_h": ch / h,
                    "margins": (x0, y0, w - 1 - x1, h - 1 - y1),
                },
            )
        )

    flagged = 0
    for clip, items in sorted(clips.items()):
        widths = [d["cw"] for _, d in items]
        heights = [d["ch"] for _, d in items]
        w_jit = (max(widths) - min(widths)) / max(1, max(widths))
        h_jit = (max(heights) - min(heights)) / max(1, max(heights))
        issues = []
        if w_jit > args.jitter or h_jit > args.jitter:
            issues.append(f"FRAME_JITTER w={w_jit:.2f} h={h_jit:.2f}")
        for name, d in items:
            if d["edge"] > 12:
                issues.append(f"FX_CLIP {name} edge={d['edge']}")
            if d["fill_w"] > args.full or d["fill_h"] > args.full:
                issues.append(
                    f"NEAR_FULL {name} fill={d['fill_w']:.2f}x{d['fill_h']:.2f}"
                )
        if issues:
            flagged += 1
            print(f"{clip}: frames={len(items)}")
            for iss in issues[:12]:
                print(f"  {iss}")
            if len(issues) > 12:
                print(f"  ... +{len(issues)-12} more")
    print(f"clips={len(clips)} flagged_clips={flagged}")
    return 1 if flagged else 0


if __name__ == "__main__":
    sys.exit(main())
