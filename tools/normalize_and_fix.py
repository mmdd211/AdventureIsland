# normalize + fix 合并脚本：cleaned 960×960 → normalized 256×256
#
# 流程：alpha 硬化 → 碎片清理 → 统一缩放 → 脚底/头部锚点对齐
# 用 idle 帧作为比例基准，所有帧缩放到相同高度
import os
import sys
from PIL import Image
from collections import deque

sys.stdout.reconfigure(encoding="utf-8")

CLEANED = r"D:\KAFA\Workspace\ohter\AdventureIsland\data\player\cleaned"
NORMALIZED = r"D:\KAFA\Workspace\ohter\AdventureIsland\assets\sprites\player"
SIZE = 256
BASELINE = 244   # 脚底线
HEAD_X = 140     # 头部锚点 x
HARDEN = 128     # alpha 硬化阈值
LARGE_COMP = 400 # 大组件阈值
TARGET_HEIGHT = 200  # 目标角色高度（在 256 画布中占 200px，上下各留 28px 边距）

# 空中动作列表（用 center 对齐而非 feet）
AIRBORNE = {"jump-takeoff", "fall", "death"}

def harden(img):
    """alpha 二值化：≥128 不透明，否则全透明"""
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= HARDEN else (0, 0, 0, 0)
    return img

def find_components(img):
    """8 邻域连通组件"""
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
    """删碎片：保留主体 + 附近大组件"""
    comps, labels = find_components(img)
    if not comps:
        return img
    main = max(comps, key=lambda c: c["size"])
    main_idx = comps.index(main)
    m_x0, m_y0 = main["x0"] - 20, main["y0"] - 20
    m_x1, m_y1 = main["x1"] + 20, main["y1"] + 20
    keep = set()
    for i, c in enumerate(comps):
        near = not (c["x1"] < m_x0 or c["x0"] > m_x1 or c["y1"] < m_y0 or c["y0"] > m_y1)
        if i == main_idx or (near and c["size"] >= 30) or c["size"] >= 200:
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
    """大组件联合边界"""
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
    # 头部锚点（顶部 30% 波段的水平中心）
    band_bottom = y0 + int((y1 - y0) * 0.30)
    px = img.load()
    hx0, hx1 = img.width, -1
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

def process(fname):
    path = os.path.join(CLEANED, fname)
    img = Image.open(path).convert("RGBA")
    # 1. 边缘硬化
    img = harden(img)
    # 2. 碎片清理
    img = clean_debris(img)
    # 3. 裁剪到内容边界
    bounds = kept_bounds(img)
    if bounds[2] < 0:
        print(f"  WARNING: {fname} is empty after cleaning!")
        return None, None
    x0, y0, x1, y1 = bounds
    content = img.crop((x0, y0, x1 + 1, y1 + 1))
    cw, ch = content.size
    # 4. 统一缩放（按高度对齐 TARGET_HEIGHT）
    scale = TARGET_HEIGHT / ch
    new_w = max(1, round(cw * scale))
    new_h = max(1, round(ch * scale))
    content = content.resize((new_w, new_h), Image.NEAREST)
    # 5. 放入 256×256 画布
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    # 判断对齐方式
    action = fname.replace("-frame-" + fname.split("-frame-")[-1], "")
    is_airborne = action in AIRBORNE
    if is_airborne:
        # center 对齐
        paste_x = (SIZE - new_w) // 2
        paste_y = (SIZE - new_h) // 2
    else:
        # feet 对齐
        paste_x = (SIZE - new_w) // 2
        paste_y = BASELINE - new_h
    canvas.paste(content, (paste_x, paste_y), content)
    # 6. 精确对齐（两轮）
    for _ in range(2):
        _, feet, head_x = large_union(canvas)
        if feet is None:
            break
        if is_airborne:
            # center 对齐：居中
            kb = kept_bounds(canvas)
            if kb[2] >= 0:
                cx = (kb[0] + kb[2]) // 2
                cy = (kb[1] + kb[3]) // 2
                canvas = shift_image(canvas, SIZE // 2 - cx, SIZE // 2 - cy)
        else:
            # feet 对齐
            canvas = shift_image(canvas, HEAD_X - head_x, BASELINE - feet)
    # 保存
    canvas.save(os.path.join(NORMALIZED, fname))
    # 统计
    _, feet, head_x = large_union(canvas)
    kb = kept_bounds(canvas)
    if kb[2] >= 0 and feet is not None:
        return feet, head_x
    return None, None

def shift_image(img, sx, sy):
    if sx == 0 and sy == 0:
        return img
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(img, (sx, sy), img)
    return out

# 处理所有帧
NORMALIZED_DIR = NORMALIZED
os.makedirs(NORMALIZED_DIR, exist_ok=True)

print(f"{'frame':<28}{'feet':>6}{'headX':>7}")
for f in sorted(os.listdir(CLEANED)):
    if not f.endswith(".png"):
        continue
    feet, hx = process(f)
    if feet is not None:
        print(f"{f:<28}{feet:>6}{hx:>7}")
    else:
        print(f"{f:<28}  EMPTY")
print("\ndone")
