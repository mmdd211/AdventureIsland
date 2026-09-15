"""One-off: build 3x3 walk preview sheet + looped cycle GIF for Boss banbu."""
import os
from PIL import Image

WALK_DIR = r"D:/KAFA/Workspace/ohter/AdventureIsland_banbu/assets/sprites/boss/banbu/form1_giant_spore_turtle/walk"
OUT_DIR = r"D:/KAFA/Workspace/ohter/AdventureIsland_banbu/data/boss/banbu/previews"
SHEET_PATH = os.path.join(OUT_DIR, "walk_sheet_preview.png")
GIF_PATH = os.path.join(OUT_DIR, "walk_cycle.gif")

CELL = 256
GAP = 4
SIZE = CELL * 3 + GAP * 2  # 772

# ---- Load 9 RGBA frames ----
frames_rgba = []
for i in range(1, 10):
    p = os.path.join(WALK_DIR, f"banbu-walk-frame-{i}.png")
    frames_rgba.append(Image.open(p).convert("RGBA"))

# ---- 1. 3x3 overview PNG on transparent canvas ----
sheet = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
for idx, frame in enumerate(frames_rgba):
    row = idx // 3
    col = idx % 3
    x = col * (CELL + GAP)
    y = row * (CELL + GAP)
    sheet.paste(frame, (x, y), frame)  # frame doubles as its own mask -> clean alpha
sheet.save(SHEET_PATH)
print(f"sheet saved: {SHEET_PATH}  size={sheet.size}  mode={sheet.mode}")

# ---- 2. Looped GIF (P mode, adaptive palette, index 0 reserved for transparency) ----
def rgba_to_p(rgba):
    """RGBA -> P with adaptive palette; index 0 = transparent (alpha<128), 1..255 = colors."""
    rgba = rgba.convert("RGBA")
    alpha = rgba.split()[3]
    rgb = rgba.convert("RGB")
    p = rgb.convert("P", palette=Image.ADAPTIVE, colors=255)  # indices 0..254
    data = list(p.getdata())        # 0..254
    adata = list(alpha.getdata())   # 0..255
    new_data = [0 if a < 128 else (v + 1) for v, a in zip(data, adata)]
    new_p = Image.new("P", rgba.size, 0)
    new_p.putdata(new_data)
    old_pal = p.getpalette()        # 768 values (256*3), only first 255 used
    new_pal = [0, 0, 0] + old_pal[:255 * 3]  # idx0 transparent + 255 colors = 768
    new_p.putpalette(new_pal)
    new_p.info["transparency"] = 0
    return new_p

frames_p = [rgba_to_p(f) for f in frames_rgba]
frames_p[0].save(
    GIF_PATH,
    save_all=True,
    append_images=frames_p[1:],
    duration=120,
    loop=0,
    disposal=2,        # restore to background (transparent) between frames -> no residue
    transparency=0,
)
print(f"gif saved: {GIF_PATH}")
