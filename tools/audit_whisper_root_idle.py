from PIL import Image
from pathlib import Path

out = Path(r"D:\KAFA\Workspace\ohter\AdventureIsland\assets\sprites\monsters\whisper_root")
files = sorted(out.glob("whisper_root_nest_idle_*.png"))
print(f"frames: {len(files)}")


def is_magentaish(r, g, b, a):
    return a < 20 or (r > 180 and b > 140 and g < 100 and (r - g) > 60 and (b - g) > 40)


for p in files:
    im = Image.open(p).convert("RGBA")
    px = im.load()
    w, h = im.size
    edge_bad = 0
    for x in range(w):
        for y in (0, h - 1):
            r, g, b, a = px[x, y]
            if a >= 20 and is_magentaish(r, g, b, a):
                edge_bad += 1
    for y in range(h):
        for x in (0, w - 1):
            r, g, b, a = px[x, y]
            if a >= 20 and is_magentaish(r, g, b, a):
                edge_bad += 1
    inner_clear = 0
    opaque = 0
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            if px[x, y][3] < 20:
                inner_clear += 1
            else:
                opaque += 1
    white_br = 0
    for y in range(h // 2, h):
        for x in range(w // 2, w):
            r, g, b, a = px[x, y]
            if a >= 200 and r > 230 and g > 230 and b > 230:
                white_br += 1
    xs, ys = [], []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] >= 20:
                xs.append(x)
                ys.append(y)
    bb = (min(xs), min(ys), max(xs), max(ys)) if xs else None
    touch = None
    if bb:
        touch = bb[0] == 0 or bb[1] == 0 or bb[2] == w - 1 or bb[3] == h - 1
    print(
        f"{p.name}: size={im.size} opaque={opaque} inner_clear={inner_clear} "
        f"edge_magenta={edge_bad} white_br={white_br} bbox={bb} edge_touch={touch}"
    )
