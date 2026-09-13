"""First-frame strip of all bee states for identity review."""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(r"D:\KAFA\Workspace\ohter\AdventureIsland")
SRC = ROOT / "assets" / "sprites" / "monsters" / "pollen_queen"
OUT = ROOT / "data" / "monsters" / "raw" / "pollen_queen_bee_states_identity.png"
BG = (222, 218, 204, 255)
STATES = ["idle", "move", "attack", "skill", "hurt", "evolve", "death"]
UP = 2

frames = []
for state in STATES:
    path = SRC / f"pollen_queen_bee_{state}_00.png"
    frames.append((state, Image.open(path).convert("RGBA")))

w = sum(im.width * UP for _, im in frames) + 10 * (len(frames) + 1)
h = frames[0][1].height * UP + 36
sheet = Image.new("RGBA", (w, h), BG)
draw = ImageDraw.Draw(sheet)
x = 10
for state, im in frames:
    big = im.resize((im.width * UP, im.height * UP), Image.NEAREST)
    sheet.alpha_composite(big, (x, 8))
    draw.text((x, h - 20), state, fill=(30, 30, 30, 255))
    x += big.width + 10
sheet.save(OUT)
print("saved", OUT, sheet.size)
