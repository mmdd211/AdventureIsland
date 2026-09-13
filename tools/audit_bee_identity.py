"""Honest side-by-side of idle master vs each state first frame at same pixel size."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(r"D:\KAFA\Workspace\ohter\AdventureIsland")
SRC = ROOT / "assets" / "sprites" / "monsters" / "pollen_queen"
OUT = ROOT / "data" / "monsters" / "raw" / "bee_identity_audit.png"
BG = (32, 32, 36, 255)
PAD = 16
CELL = 192
UP = 3  # 576 display

states = ["idle", "move", "attack", "skill", "hurt", "evolve", "death"]
frames = []
for s in states:
    im = Image.open(SRC / f"pollen_queen_bee_{s}_00.png").convert("RGBA")
    frames.append((s, im))

# also mid frames for animation check
mids = []
for s in ["idle", "attack", "skill", "evolve"]:
    # pick a middle frame
    mid_idx = 3 if s != "skill" else 4
    p = SRC / f"pollen_queen_bee_{s}_{mid_idx:02d}.png"
    if p.exists():
        mids.append((f"{s}#{mid_idx}", Image.open(p).convert("RGBA")))

cols = 4
rows = (len(frames) + cols - 1) // cols
W = PAD + cols * (CELL * UP + PAD)
H = PAD + rows * (CELL * UP + 40 + PAD)
sheet = Image.new("RGBA", (W, H), BG)
draw = ImageDraw.Draw(sheet)

for i, (name, im) in enumerate(frames):
    r, c = divmod(i, cols)
    x = PAD + c * (CELL * UP + PAD)
    y = PAD + r * (CELL * UP + 40 + PAD)
    # checker for transparency
    for cy in range(0, CELL * UP, 24):
        for cx in range(0, CELL * UP, 24):
            if ((cx // 24) + (cy // 24)) % 2 == 0:
                draw.rectangle([x + cx, y + cy, x + cx + 23, y + cy + 23], fill=(48, 48, 52, 255))
    big = im.resize((CELL * UP, CELL * UP), Image.NEAREST)
    sheet.alpha_composite(big, (x, y))
    draw.text((x + 4, y + CELL * UP + 8), name, fill=(240, 240, 240, 255))

sheet.save(OUT)
print("saved", OUT, sheet.size)

# numeric silhouette metrics
import math

def metrics(im):
    px = im.load()
    w, h = im.size
    minx, miny, maxx, maxy = w, h, -1, -1
    n = 0
    sumx = sumy = 0
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 10:
                n += 1
                sumx += x; sumy += y
                minx = min(minx, x); maxx = max(maxx, x)
                miny = min(miny, y); maxy = max(maxy, y)
    if n == 0:
        return None
    return {
        "n": n,
        "cx": sumx / n, "cy": sumy / n,
        "w": maxx - minx + 1, "h": maxy - miny + 1,
        "fill": n / (w * h),
    }

print("\n=== silhouette metrics (192x192) ===")
base = None
for s, im in frames:
    m = metrics(im)
    if base is None:
        base = m
        print(f"{s:8s} n={m['n']:5d} w={m['w']:3d} h={m['h']:3d} cx={m['cx']:.1f} cy={m['cy']:.1f} fill={m['fill']:.3f}  << BASE")
    else:
        dn = abs(m['n'] - base['n']) / base['n']
        dw = abs(m['w'] - base['w']) / base['w']
        dh = abs(m['h'] - base['h']) / base['h']
        dcx = abs(m['cx'] - base['cx'])
        dcy = abs(m['cy'] - base['cy'])
        print(f"{s:8s} n={m['n']:5d} w={m['w']:3d} h={m['h']:3d} cx={m['cx']:.1f} cy={m['cy']:.1f} fill={m['fill']:.3f}  Δn={dn:.0%} Δw={dw:.0%} Δh={dh:.0%} Δcx={dcx:.1f} Δcy={dcy:.1f}")
