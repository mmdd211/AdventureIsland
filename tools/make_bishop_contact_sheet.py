from PIL import Image, ImageDraw
from pathlib import Path

root = Path(r"D:\KAFA\Workspace\ohter\AdventureIsland\assets\sprites\monsters\whisper_root")
states = [
    ("idle", 6),
    ("move", 6),
    ("attack", 7),
    ("skill", 8),
    ("hurt", 3),
    ("evolve", 8),
    ("death", 6),
]
cell = 112
pad = 8
label_h = 18
max_cols = max(n for _, n in states)
rows = len(states)
sheet_w = pad + max_cols * (cell + pad)
sheet_h = pad + rows * (cell + pad + label_h)
sheet = Image.new("RGBA", (sheet_w, sheet_h), (24, 24, 28, 255))
draw = ImageDraw.Draw(sheet)
for r, (state, count) in enumerate(states):
    y0 = pad + r * (cell + pad + label_h)
    draw.text((pad, y0), f"{state} x{count}", fill=(220, 220, 220, 255))
    for i in range(count):
        p = root / f"whisper_root_bishop_{state}_{i:02d}.png"
        if not p.exists():
            continue
        im = Image.open(p).convert("RGBA").resize((cell, cell), Image.Resampling.LANCZOS)
        sheet.alpha_composite(im, (pad + i * (cell + pad), y0 + label_h))
out = Path(r"D:\KAFA\Workspace\ohter\AdventureIsland\data\monsters\raw\bishop_all_states_contact.png")
sheet.save(out)
print(out, sheet.size)

# audit
edge_bad = touch = 0
files = sorted(root.glob("whisper_root_bishop_*.png"))
print("total", len(files))
for p in files:
    im = Image.open(p).convert("RGBA")
    px = im.load()
    w, h = im.size
    xs, ys = [], []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] >= 20:
                xs.append(x)
                ys.append(y)
    if xs:
        bb = (min(xs), min(ys), max(xs), max(ys))
        if bb[0] == 0 or bb[1] == 0 or bb[2] == w - 1 or bb[3] == h - 1:
            touch += 1
            print("TOUCH", p.name, bb)
    for x in range(w):
        for y in (0, h - 1):
            r, g, b, a = px[x, y]
            if a >= 20 and r > 180 and b > 140 and g < 100 and (r - g) > 60 and (b - g) > 40:
                edge_bad += 1
    for y in range(h):
        for x in (0, w - 1):
            r, g, b, a = px[x, y]
            if a >= 20 and r > 180 and b > 140 and g < 100 and (r - g) > 60 and (b - g) > 40:
                edge_bad += 1
print("edge_magenta_total", edge_bad, "edge_touch_frames", touch)
