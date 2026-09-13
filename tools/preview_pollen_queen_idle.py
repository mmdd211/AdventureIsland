"""Preview idle 6-frame strip on a light background."""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(r"D:\KAFA\Workspace\ohter\AdventureIsland")
SRC = ROOT / "assets" / "sprites" / "monsters" / "pollen_queen"
OUT = ROOT / "data" / "monsters" / "raw" / "pollen_queen_bee_idle_preview.png"
BG = (222, 218, 204, 255)
UP = 2

frames = []
for i in range(6):
    im = Image.open(SRC / f"pollen_queen_bee_idle_{i:02d}.png").convert("RGBA")
    frames.append(im)

w = sum(f.width * UP for f in frames) + 8 * (len(frames) + 1)
h = frames[0].height * UP + 32
sheet = Image.new("RGBA", (w, h), BG)
draw = ImageDraw.Draw(sheet)
x = 8
for i, f in enumerate(frames):
    big = f.resize((f.width * UP, f.height * UP), Image.NEAREST)
    sheet.alpha_composite(big, (x, 8))
    draw.text((x, h - 18), f"idle_{i:02d}", fill=(40, 40, 40, 255))
    x += big.width + 8
sheet.save(OUT)
print("saved", OUT)

# size / pad check
for i in range(6):
    im = Image.open(SRC / f"pollen_queen_bee_idle_{i:02d}.png")
    assert im.size == (192, 192), im.size
    bbox = im.getbbox()
    assert bbox, f"empty {i}"
print("all idle frames 192x192 non-empty")
