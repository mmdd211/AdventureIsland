# Split pollen_queen bee hover 3x3 → 192x192 idle/move frames
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "monsters" / "raw"
SHEET = RAW / "pollen_queen_bee_hover_3x3_v1.png"
CELLS_DIR = RAW / "pollen_queen_bee_hover_cells"
OUT = ROOT / "assets" / "sprites" / "monsters" / "pollen_queen"
SIZE = 192
HARDEN = 128
# 9-cell grid → pick 6 keyframes preserving wing open/close arc
# cells are 0..8 row-major: 1,2,4,5,7,8 (1-based) → indices 0,1,3,4,6,7
IDLE_PICK = [0, 1, 3, 4, 6, 7]


def is_magenta(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    if a < HARDEN:
        return True
    return r > 180 and b > 180 and g < 90


def key_out_magenta(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < HARDEN or (r > 180 and b > 180 and g < 90):
                px[x, y] = (0, 0, 0, 0)
            else:
                px[x, y] = (r, g, b, 255)
    return rgba


def content_bbox(img: Image.Image) -> tuple[int, int, int, int] | None:
    px = img.load()
    w, h = img.size
    minx, miny, maxx, maxy = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 0:
                minx = min(minx, x)
                miny = min(miny, y)
                maxx = max(maxx, x)
                maxy = max(maxy, y)
    if maxx < 0:
        return None
    return minx, miny, maxx, maxy


def place_centered(img: Image.Image, size: int = SIZE) -> Image.Image:
    bbox = content_bbox(img)
    if bbox is None:
        return Image.new("RGBA", (size, size), (0, 0, 0, 0))
    minx, miny, maxx, maxy = bbox
    crop = img.crop((minx, miny, maxx + 1, maxy + 1))
    # Fit inside ~64% safe area of the canvas
    safe = int(size * 0.68)
    cw, ch = crop.size
    scale = min(safe / cw, safe / ch, 1.0)
    # Prefer scaling up if content is tiny relative to canvas
    if max(cw, ch) < safe * 0.85:
        scale = safe / max(cw, ch)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    if (nw, nh) != (cw, ch):
        crop = crop.resize((nw, nh), Image.NEAREST)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ox = (size - nw) // 2
    oy = (size - nh) // 2
    canvas.paste(crop, (ox, oy), crop)
    return canvas


def main() -> None:
    if not SHEET.exists():
        raise SystemExit(f"missing sheet: {SHEET}")
    CELLS_DIR.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    sheet = Image.open(SHEET).convert("RGBA")
    sw, sh = sheet.size
    cw, ch = sw // 3, sh // 3
    cells: list[Image.Image] = []
    for row in range(3):
        for col in range(3):
            cell = sheet.crop((col * cw, row * ch, (col + 1) * cw, (row + 1) * ch))
            keyed = key_out_magenta(cell)
            path = CELLS_DIR / f"cell_{row * 3 + col:02d}.png"
            keyed.save(path)
            cells.append(keyed)
            print(f"cell {row * 3 + col}: saved {path.name}")

    if len(cells) != 9:
        raise SystemExit(f"expected 9 cells, got {len(cells)}")

    idle_frames = [place_centered(cells[i]) for i in IDLE_PICK]
    for idx, frame in enumerate(idle_frames):
        idle_path = OUT / f"pollen_queen_bee_idle_{idx:02d}.png"
        move_path = OUT / f"pollen_queen_bee_move_{idx:02d}.png"
        frame.save(idle_path)
        frame.save(move_path)
        bbox = content_bbox(frame)
        pad = 0
        if bbox:
            minx, miny, maxx, maxy = bbox
            pad = min(minx, miny, SIZE - 1 - maxx, SIZE - 1 - maxy)
        print(f"idle/move {idx:02d}: source cell {IDLE_PICK[idx]} pad={pad}")

    print(f"wrote 6 idle + 6 move frames to {OUT}")


if __name__ == "__main__":
    main()
