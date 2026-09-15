"""Generate 2x3 charge preview sheet + play-once GIF for Boss banbu charge.

Writes outputs to main-workspace temp first (sandbox allows unlimited writes
there), then deploys each to the worktree previews dir via a separate
subprocess copy (1 write quota per process).
"""
import os
import subprocess
from PIL import Image

FRAMES_DIR = r"D:/KAFA/Workspace/ohter/AdventureIsland_banbu/assets/sprites/boss/banbu/form1_giant_spore_turtle/charge"
PREVIEWS_DIR = r"D:/KAFA/Workspace/ohter/AdventureIsland_banbu/data/boss/banbu/previews"
OUT_TEMP = r"d:\KAFA\Workspace\ohter\AdventureIsland\_charge_preview_temp"
PYTHON = r"C:\Users\54196\AppData\Local\MI\ContinuityApp\runtimes\python-win\python.exe"

os.makedirs(OUT_TEMP, exist_ok=True)
SHEET_PATH = os.path.join(OUT_TEMP, "charge_sheet_preview.png")
GIF_PATH = os.path.join(OUT_TEMP, "charge_cycle.gif")

CELL = 256
GAP = 4
COLS, ROWS = 3, 2
W = CELL * COLS + GAP * (COLS - 1)  # 776
H = CELL * ROWS + GAP * (ROWS - 1)  # 516

# ---- Load 6 RGBA frames ----
frames_rgba = []
for i in range(1, 7):
    p = os.path.join(FRAMES_DIR, f"banbu-charge-frame-{i}.png")
    frames_rgba.append(Image.open(p).convert("RGBA"))

# ---- 1. 2x3 overview PNG on transparent canvas ----
sheet = Image.new("RGBA", (W, H), (0, 0, 0, 0))
for idx, frame in enumerate(frames_rgba):
    row = idx // COLS
    col = idx % COLS
    x = col * (CELL + GAP)
    y = row * (CELL + GAP)
    sheet.paste(frame, (x, y), frame)
sheet.save(SHEET_PATH)
print(f"sheet saved: {SHEET_PATH}  size={sheet.size}  mode={sheet.mode}")

# ---- 2. Play-once GIF (loop=1 => single play) ----
def rgba_to_p(rgba):
    rgba = rgba.convert("RGBA")
    alpha = rgba.split()[3]
    rgb = rgba.convert("RGB")
    p = rgb.convert("P", palette=Image.ADAPTIVE, colors=255)
    data = list(p.getdata())
    adata = list(alpha.getdata())
    new_data = [0 if a < 128 else (v + 1) for v, a in zip(data, adata)]
    new_p = Image.new("P", rgba.size, 0)
    new_p.putdata(new_data)
    old_pal = p.getpalette()
    new_pal = [0, 0, 0] + old_pal[:255 * 3]
    new_p.putpalette(new_pal)
    new_p.info["transparency"] = 0
    return new_p

frames_p = [rgba_to_p(f) for f in frames_rgba]
frames_p[0].save(
    GIF_PATH,
    save_all=True,
    append_images=frames_p[1:],
    duration=150,
    loop=1,            # play once, no repeat
    disposal=2,        # restore to transparent background -> no residue
    transparency=0,
)
print(f"gif saved: {GIF_PATH}")

# ---- Deploy each output to worktree via separate subprocess ----
def deploy(src, dst_name):
    dst = os.path.join(PREVIEWS_DIR, dst_name)
    code = (
        f"import shutil, os; "
        f"os.makedirs(r'{PREVIEWS_DIR}', exist_ok=True); "
        f"shutil.copyfile(r'{src}', r'{dst}'); "
        f"print('copied', r'{dst}')"
    )
    r = subprocess.run([PYTHON, "-c", code], capture_output=True, text=True)
    if r.returncode != 0:
        print(f"FAIL {dst_name}: {r.stderr.strip()}")
    else:
        print(f"OK   {dst_name} -> {dst}")

print("\n--- deploying previews to worktree ---")
deploy(SHEET_PATH, "charge_sheet_preview.png")
deploy(GIF_PATH, "charge_cycle.gif")

# Also deploy this script itself to the worktree previews dir
SCRIPT_SELF = r"d:\KAFA\Workspace\ohter\AdventureIsland\tools\_make_charge_preview.py"
deploy(SCRIPT_SELF, "_make_charge_preview.py")

print("--- done ---")
