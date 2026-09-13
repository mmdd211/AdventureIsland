# Robust sheet processor: auto-detect grid, key magenta, match idle size.
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "sprites" / "monsters" / "pollen_queen"
CELLS_OUT = ROOT / "data" / "monsters" / "raw" / "cells"
IDLE_REF = OUT / "pollen_queen_bee_idle_00.png"
SIZE = 192
HARDEN = 128
TARGET_H = 130  # match idle content height


def is_near_white(r: int, g: int, b: int) -> bool:
    return r > 210 and g > 210 and b > 210 and abs(r - g) < 25 and abs(g - b) < 25


def is_key_color(r: int, g: int, b: int, a: int, key: str = "magenta") -> bool:
    if a < 20:
        return True
    if key == "green":
        # 奶白/粉裙是合法主体：绿幕模式绝不把 near-white 当背景
        return g > 180 and r < 110 and b < 110 and g > r + 60 and g > b + 60
    # white sheet gutters from image_gen grids (magenta path only)
    if is_near_white(r, g, b):
        return True
    # 放宽容差以识别 AI 生成的偏色洋红背景(b 通道偏差可达 60+)
    return r >= 150 and b >= 130 and g <= 120 and (r - g) >= 50 and (b - g) >= 50


def is_magenta(r: int, g: int, b: int) -> bool:
    """供 detect_grid 使用的洋红检测别名。"""
    return is_key_color(r, g, b, 255, "magenta")


def key_bg(img: Image.Image, key: str = "magenta") -> Image.Image:
    """Key chroma globally, then border-flood the same predicate."""
    from collections import deque

    rgba = img.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if is_key_color(r, g, b, a, key):
                px[x, y] = (0, 0, 0, 0)
            else:
                px[x, y] = (r, g, b, 255 if a >= HARDEN else 0)

    visited = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or visited[y][x]:
            continue
        r, g, b, a = px[x, y]
        if a >= 20 and not is_key_color(r, g, b, a, key):
            continue
        visited[y][x] = True
        px[x, y] = (0, 0, 0, 0)
        q.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    if key == "green":
        rgba = despill_green(rgba)
    return rgba


def despill_green(img: Image.Image) -> Image.Image:
    """Clamp green fringe on soft chroma edges (AI sheets bleed #00FF00)."""
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 20:
                continue
            if g > r + 12 and g > b + 12:
                px[x, y] = (r, max(r, b), b, a)
    return rgba


def fill_pinholes(img: Image.Image) -> Image.Image:
    """Fill 1px transparent pinholes left by filtered resample + alpha harden."""
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    to_fill: list[tuple[int, int, tuple[int, int, int, int]]] = []
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            if px[x, y][3] >= 20:
                continue
            opaque_neighbors = []
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = px[x + dx, y + dy]
                if n[3] >= 20:
                    opaque_neighbors.append(n)
            if len(opaque_neighbors) >= 3:
                r = sum(n[0] for n in opaque_neighbors) // len(opaque_neighbors)
                g = sum(n[1] for n in opaque_neighbors) // len(opaque_neighbors)
                b = sum(n[2] for n in opaque_neighbors) // len(opaque_neighbors)
                to_fill.append((x, y, (r, g, b, 255)))
    for x, y, c in to_fill:
        px[x, y] = c
    return rgba


def content_bbox(img: Image.Image):
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


def opaque_count(img: Image.Image) -> int:
    px = img.load()
    n = 0
    for y in range(img.height):
        for x in range(img.width):
            if px[x, y][3] > 0:
                n += 1
    return n


def largest_component_bbox(img: Image.Image):
    """Anchor on the largest blob, then absorb nearby parts (wings/stinger)."""
    from collections import deque

    w, h = img.size
    px = img.load()
    labels = [[-1] * w for _ in range(h)]
    boxes: list[tuple[int, int, int, int, int]] = []
    next_label = 0
    for y0 in range(h):
        for x0 in range(w):
            if labels[y0][x0] != -1 or px[x0, y0][3] == 0:
                continue
            q: deque[tuple[int, int]] = deque([(x0, y0)])
            labels[y0][x0] = next_label
            size = 0
            minx, miny, maxx, maxy = x0, y0, x0, y0
            while q:
                x, y = q.popleft()
                size += 1
                minx = min(minx, x)
                maxx = max(maxx, x)
                miny = min(miny, y)
                maxy = max(maxy, y)
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        if dx == 0 and dy == 0:
                            continue
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h and labels[ny][nx] == -1 and px[nx, ny][3] > 0:
                            labels[ny][nx] = next_label
                            q.append((nx, ny))
            next_label += 1
            boxes.append((minx, miny, maxx, maxy, size))
    if not boxes:
        return None
    main = max(boxes, key=lambda b: b[4])
    margin = 120
    minx, miny, maxx, maxy = main[0], main[1], main[2], main[3]
    for b in boxes:
        if b is main:
            continue
        if b[2] < minx - margin or b[0] > maxx + margin or b[3] < miny - margin or b[1] > maxy + margin:
            continue
        if b[4] < 40:
            continue
        minx = min(minx, b[0])
        miny = min(miny, b[1])
        maxx = max(maxx, b[2])
        maxy = max(maxy, b[3])
    return minx, miny, maxx, maxy


def detect_grid(img: Image.Image, key: str = "magenta") -> tuple[int, int]:
    """Find cols/rows by scanning for chroma gutters (magenta or green)."""
    w, h = img.size
    px = img.load()

    def is_gutter_pixel(r: int, g: int, b: int) -> bool:
        return is_key_color(r, g, b, 255, key) or is_near_white(r, g, b)

    def col_is_gutter(x: int) -> bool:
        for y in range(0, h, 4):
            if not is_gutter_pixel(*px[x, y][:3]):
                return False
        return True

    def row_is_gutter(y: int) -> bool:
        for x in range(0, w, 4):
            if not is_gutter_pixel(*px[x, y][:3]):
                return False
        return True

    gutters_x = [x for x in range(w) if col_is_gutter(x)]
    gutters_y = [y for y in range(h) if row_is_gutter(y)]

    def count_splits(gutters: list[int], total: int) -> int:
        if not gutters:
            return 1
        # group consecutive
        groups = []
        start = gutters[0]
        prev = gutters[0]
        for g in gutters[1:]:
            if g == prev + 1:
                prev = g
                continue
            groups.append((start + prev) // 2)
            start = prev = g
        groups.append((start + prev) // 2)
        # only keep interior gutters
        interior = [g for g in groups if 8 < g < total - 8]
        return len(interior) + 1

    cols = count_splits(gutters_x, w)
    rows = count_splits(gutters_y, h)
    return cols, rows


def split_cells(img: Image.Image, cols: int, rows: int, key: str = "magenta") -> list[Image.Image]:
    w, h = img.size
    cw, ch = w // cols, h // rows
    cells = []
    margin = max(4, min(cw, ch) // 12)
    for r in range(rows):
        for c in range(cols):
            x0, y0 = c * cw, r * ch
            x1, y1 = (c + 1) * cw, (r + 1) * ch
            cell = img.crop((x0 + margin, y0 + margin, x1 - margin, y1 - margin))
            cells.append(key_bg(cell, key))
    return cells


def place_to_target_height(img: Image.Image, target_h: int, size: int = SIZE) -> Image.Image:
    bbox = largest_component_bbox(img)
    if bbox is None:
        bbox = content_bbox(img)
    if bbox is None:
        return Image.new("RGBA", (size, size), (0, 0, 0, 0))
    minx, miny, maxx, maxy = bbox
    crop = img.crop((minx, miny, maxx + 1, maxy + 1))
    cw, ch = crop.size
    scale = target_h / max(1, ch)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    if nw > size - 8 or nh > size - 8:
        scale = min((size - 8) / cw, (size - 8) / ch)
        nw = max(1, int(round(cw * scale)))
        nh = max(1, int(round(ch * scale)))
    if (nw, nh) != (cw, ch):
        # Downscale AI sheets with LANCZOS (NEAREST discards detail → mush).
        # Upscale stays NEAREST to keep hard pixel edges.
        resample = Image.Resampling.LANCZOS if scale < 1.0 else Image.Resampling.NEAREST
        crop = crop.resize((nw, nh), resample)
        # Re-harden alpha after filtered resample so cutout edges stay 1-bit.
        cpx = crop.load()
        for y in range(crop.height):
            for x in range(crop.width):
                r, g, b, a = cpx[x, y]
                cpx[x, y] = (r, g, b, 255 if a >= HARDEN else 0)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(crop, ((size - nw) // 2, (size - nh) // 2), crop)
    return canvas


def shift_image(img: Image.Image, sx: int, sy: int, size: int) -> Image.Image:
    """Translate img by (sx, sy) on a fresh `size`x`size` transparent canvas."""
    if sx == 0 and sy == 0:
        return img
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(img, (sx, sy), img)
    return out


def refine_center_alignment(img: Image.Image, size: int, rounds: int = 2) -> Image.Image:
    """Two-round precise center alignment: shift the largest-component bbox
    geometric center to (size//2, size//2). Filters small parts (spore pouches)
    via largest_component_bbox's internal size/margin rules."""
    for _ in range(rounds):
        bbox = largest_component_bbox(img)
        if bbox is None:
            bbox = content_bbox(img)
        if bbox is None:
            break
        minx, miny, maxx, maxy = bbox
        cx = (minx + maxx) // 2
        cy = (miny + maxy) // 2
        sx = size // 2 - cx
        sy = size // 2 - cy
        if sx == 0 and sy == 0:
            break
        img = shift_image(img, sx, sy, size)
    return img


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--sheet", required=True)
    p.add_argument("--state", required=True)
    p.add_argument("--pick", default="")
    p.add_argument("--cols", type=int, default=0)
    p.add_argument("--rows", type=int, default=0)
    p.add_argument("--form", default="bee")
    p.add_argument("--prefix", default="pollen_queen")
    p.add_argument("--key", default="magenta", choices=["magenta", "green"])
    p.add_argument("--out-dir", default="",
                   help="output dir for final frames (default: pollen_queen OUT)")
    p.add_argument("--cells-dir", default="",
                   help="intermediate debug cells dir (default: CELLS_OUT)")
    p.add_argument("--size", type=int, default=SIZE,
                   help="canvas square size in px (default 192)")
    p.add_argument("--target-h", type=int, default=TARGET_H,
                   help="boss body height in canvas px (default 130)")
    p.add_argument("--frame-template", default="{prefix}-{state}-frame-{n}.png",
                   help="filename template; {n} is 1-based, also accepts "
                        "{prefix}/{state}/{form}/{out_i}/{out_i:02d}")
    args = p.parse_args()

    sheet_path = Path(args.sheet)
    if not sheet_path.is_absolute():
        sheet_path = ROOT / sheet_path
    sheet = Image.open(sheet_path).convert("RGBA")

    if args.cols and args.rows:
        cols, rows = args.cols, args.rows
    else:
        cols, rows = detect_grid(sheet, args.key)
    print(f"grid {cols}x{rows} cell {sheet.width // cols}x{sheet.height // rows}")

    cells = split_cells(sheet, cols, rows, args.key)

    # cells dir (debug intermediate) -- CLI overrides fallback constant
    if args.cells_dir:
        cell_dir_root = Path(args.cells_dir)
        if not cell_dir_root.is_absolute():
            cell_dir_root = ROOT / cell_dir_root
    else:
        cell_dir_root = CELLS_OUT
    cell_dir = cell_dir_root / f"{args.prefix}_{args.form}_{args.state}_v2"
    cell_dir.mkdir(parents=True, exist_ok=True)
    for i, cell in enumerate(cells):
        cell.save(cell_dir / f"cell_{i:02d}.png")

    if args.pick:
        picks = [int(x) for x in args.pick.split(",") if x.strip() != ""]
    else:
        picks = list(range(len(cells)))

    if max(picks) >= len(cells):
        raise SystemExit(f"pick {picks} exceeds {len(cells)}")

    # output dir -- CLI overrides fallback constant (pollen_queen OUT)
    if args.out_dir:
        out_dir = Path(args.out_dir)
        if not out_dir.is_absolute():
            out_dir = ROOT / out_dir
    else:
        out_dir = OUT
    out_dir.mkdir(parents=True, exist_ok=True)

    size = args.size
    target_h = args.target_h
    print(f"canvas={size} target_h={target_h} out={out_dir}")
    ok = 0
    for out_i, cell_i in enumerate(picks):
        framed = place_to_target_height(cells[cell_i], target_h, size)
        # two-round precise center alignment on the final canvas
        framed = refine_center_alignment(framed, size, rounds=2)
        if args.key == "green":
            framed = despill_green(framed)
            framed = fill_pinholes(framed)

        n = opaque_count(framed)
        bb = content_bbox(framed)
        w = bb[2] - bb[0] + 1 if bb else 0
        h = bb[3] - bb[1] + 1 if bb else 0
        flag = "OK" if n > 4000 and w > 70 and h > 90 else "WEAK"
        if flag == "OK":
            ok += 1

        # body bbox + geometric center via largest component (post-refine should be ~centered)
        body = largest_component_bbox(framed)
        if body:
            bx0, by0, bx1, by1 = body
            cx = (bx0 + bx1) // 2
            cy = (by0 + by1) // 2
            bw = bx1 - bx0 + 1
            bh = by1 - by0 + 1
        else:
            cx = cy = bw = bh = 0

        fname = args.frame_template.format(
            prefix=args.prefix, state=args.state, form=args.form,
            n=out_i + 1, out_i=out_i,
        )
        path = out_dir / fname
        framed.save(path)
        print(f"{fname} <- cell {cell_i} size={framed.size} "
              f"body={bw}x{bh} center=({cx},{cy}) opaque={n} {flag}")
    print(f"wrote {ok}/{len(picks)} strong frames")


if __name__ == "__main__":
    main()
