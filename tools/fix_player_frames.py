# 修复主角帧：边缘硬化 + 碎片清理 + 比例修正 + 脚底/头部锚点对齐
#
# ⚠️ 一次性迁移脚本：从 git HEAD 恢复源帧后处理并覆盖。
# 每次运行都会对 run/walk 帧再乘一次 SCALE（1.07/1.18），
# 重复执行会导致角色越跑越大，仅在帧未修复时运行。
import io
import os
import subprocess
import sys
from PIL import Image

sys.stdout.reconfigure(encoding="utf-8")

NORMALIZED = r"D:\KAFA\Workspace\ohter\AdventureIsland\data\player\normalized"
REPO = r"D:\KAFA\Workspace\ohter\AdventureIsland"
SIZE = 256
BASELINE = 244
HEAD_X = 140
HARDEN = 128
LARGE_COMP = 500  # 大组件阈值：判定为角色身体的一部分

SCALE = {}
for i in range(1, 5):
    SCALE[f"run-frame-{i}.png"] = 1.07
    SCALE[f"walk-frame-{i}.png"] = 1.18

def git_restore(fname):
    out = subprocess.run(["git", "show", f"HEAD:data/player/normalized/{fname}"],
                         cwd=REPO, capture_output=True)
    if out.returncode != 0:
        raise RuntimeError(f"git show failed: {fname}")
    return Image.open(io.BytesIO(out.stdout)).convert("RGBA")

def harden(img):
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= HARDEN else (0, 0, 0, 0)
    return img

def find_components(img):
    px = img.load()
    w, h = img.size
    labels = [[-1] * w for _ in range(h)]
    comps = []
    for y in range(h):
        for x in range(w):
            if labels[y][x] != -1 or px[x, y][3] == 0:
                continue
            label = len(comps)
            queue = [(x, y)]
            labels[y][x] = label
            head = 0
            x0, x1, y0, y1 = x, x, y, y
            while head < len(queue):
                cx, cy = queue[head]
                head += 1
                x0 = min(x0, cx); x1 = max(x1, cx)
                y0 = min(y0, cy); y1 = max(y1, cy)
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        if dx == 0 and dy == 0:
                            continue
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h and labels[ny][nx] == -1 and px[nx, ny][3] > 0:
                            labels[ny][nx] = label
                            queue.append((nx, ny))
            comps.append({"size": len(queue), "x0": x0, "y0": y0, "x1": x1, "y1": y1})
    return comps, labels

def clean_debris(img):
    """删碎片：保留主体 + 附近(≥40px) + 任意大块(≥150px)"""
    comps, labels = find_components(img)
    if not comps:
        return img
    main = max(comps, key=lambda c: c["size"])
    main_idx = comps.index(main)
    m_x0, m_y0 = main["x0"] - 16, main["y0"] - 16
    m_x1, m_y1 = main["x1"] + 16, main["y1"] + 16
    keep = set()
    for i, c in enumerate(comps):
        near = not (c["x1"] < m_x0 or c["x0"] > m_x1 or c["y1"] < m_y0 or c["y0"] > m_y1)
        if i == main_idx or (near and c["size"] >= 40) or c["size"] >= 150:
            keep.add(i)
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            l = labels[y][x]
            if l >= 0 and l not in keep:
                px[x, y] = (0, 0, 0, 0)
    return img

def large_union(img):
    """大组件联合边界：返回 (union_bbox, feet_y, head_x)"""
    comps, _ = find_components(img)
    large = [c for c in comps if c["size"] >= LARGE_COMP]
    if not large:
        large = [max(comps, key=lambda c: c["size"])] if comps else []
    if not large:
        return None, None, None
    x0 = min(c["x0"] for c in large)
    y0 = min(c["y0"] for c in large)
    x1 = max(c["x1"] for c in large)
    y1 = max(c["y1"] for c in large)
    feet = y1
    band_bottom = y0 + int((y1 - y0) * 0.30)
    px = img.load()
    hx0, hx1 = SIZE, -1
    for y in range(y0, band_bottom + 1):
        for x in range(x0, x1 + 1):
            if px[x, y][3] > 0:
                hx0 = min(hx0, x); hx1 = max(hx1, x)
    head_x = (hx0 + hx1) // 2 if hx1 >= 0 else (x0 + x1) // 2
    return (x0, y0, x1, y1), feet, head_x

def kept_bounds(img):
    px = img.load()
    w, h = img.size
    x0, y0, x1, y1 = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 0:
                x0 = min(x0, x); x1 = max(x1, x)
                y0 = min(y0, y); y1 = max(y1, y)
    return x0, y0, x1, y1

def shift_image(img, sx, sy):
    if sx == 0 and sy == 0:
        return img
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(img, (sx, sy), img)
    return out

def process(fname):
    img = git_restore(fname)
    img = harden(img)
    img = clean_debris(img)
    scale = SCALE.get(fname, 1.0)
    if scale != 1.0:
        bounds, feet, head_x = large_union(img)
        if bounds is not None:
            x0, y0, x1, y1 = bounds
            region = img.crop((x0, y0, x1 + 1, y1 + 1))
            nw = max(1, round(region.width * scale))
            nh = max(1, round(region.height * scale))
            region = region.resize((nw, nh), Image.NEAREST)
            paste_x = HEAD_X - round((head_x - x0) * scale)
            paste_y = BASELINE - nh
            canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
            canvas.paste(region, (paste_x, paste_y), region)
            img = canvas
    # 精确对齐（两轮，用大组件联合锚点）
    for _ in range(2):
        _, feet, head_x = large_union(img)
        if feet is None:
            break
        img = shift_image(img, HEAD_X - head_x, BASELINE - feet)
    img.save(os.path.join(NORMALIZED, fname))
    _, feet, head_x = large_union(img)
    kb = kept_bounds(img)
    return feet, head_x, kb[2] - kb[0] + 1, kb[3] - kb[1] + 1

print(f"{'frame':<28}{'feet':>5}{'headX':>7}{'w':>5}{'h':>5}")
for f in sorted(os.listdir(NORMALIZED)):
    if not f.endswith(".png"):
        continue
    feet, hx, w, h = process(f)
    print(f"{f:<28}{feet:>5}{hx:>7}{w:>5}{h:>5}")
print("\ndone")
