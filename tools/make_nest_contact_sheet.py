from PIL import Image
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

from PIL import ImageDraw

draw = ImageDraw.Draw(sheet)
for r, (state, count) in enumerate(states):
    y0 = pad + r * (cell + pad + label_h)
    draw.text((pad, y0), f"{state} x{count}", fill=(220, 220, 220, 255))
    for i in range(count):
        p = root / f"whisper_root_nest_{state}_{i:02d}.png"
        if not p.exists():
            continue
        im = Image.open(p).convert("RGBA")
        im = im.resize((cell, cell), Image.Resampling.LANCZOS)
        x0 = pad + i * (cell + pad)
        sheet.alpha_composite(im, (x0, y0 + label_h))

out = root.parent.parent.parent / "data" / "monsters" / "raw" / "nest_all_states_contact.png"
# path: assets/sprites/monsters -> repo/data/monsters/raw
out = Path(r"D:\KAFA\Workspace\ohter\AdventureIsland\data\monsters\raw\nest_all_states_contact.png")
sheet.save(out)
print(out, sheet.size)
