# run 帧比例手术（v7）：按躯干高度缩放 + 腿部独立压短
# 病根：之前按总身高缩放，跑姿腿伸开 → 头被压小 15%
# 方案：上半身（头顶→裙摆底）缩放到 idle 躯干 173px；裙下腿部独立缩放
import sys
import os
from PIL import Image

sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from clean_player_frames import clean_image

SRC = r"D:\KAFA\Workspace\ohter\AdventureIsland\data\player"
DST = r"D:\KAFA\Workspace\ohter\AdventureIsland\assets\sprites\player"
PREV = r"D:\KAFA\Workspace\ohter\AdventureIsland\tools\run_previews"

SIZE = 256
BASELINE = 255
HEAD_X = 140
HARDEN = 128
LARGE_COMP = 400

# idle 实测：躯干（头顶→裙摆底）= 240-66 = 174，取 173
TARGET_TORSO = 173
# 腿部目标高度（裙摆→脚底）：触地伸展 28 | 蓄力压缩 20 | 过渡 24 | 腾空蹬直 30
LEGS = {1: 28, 2: 20, 3: 24, 4: 30, 5: 28, 6: 20, 7: 24, 8: 30}

def is_navy(r, g, b, a):
    return a > 0 and b > 80 and b > r + 30 and b > g + 20 and r < 110

def find_skirt_seam(img, top_y, feet):
    """裙摆底 = 自下而上第一行 navy 像素数>=3 的行"""
    px = img.load()
    w, h = img.size
    for y in range(feet, top_y, -1):
        cnt = 0
        for x in range(w):
            if is_navy(*px[x, y]):
                cnt += 1
        if cnt >= 3:
            return y
    return None

def harden(img):
    px = img.load(); w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= HARDEN else (0, 0, 0, 0)
    return img

def find_components(img):
    px = img.load(); w, h = img.size
    labels = [[-1]*w for _ in range(h)]
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
                cx, cy = queue[head]; head += 1
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
    px = img.load(); w, h = img.size
    for y in range(h):
        for x in range(w):
            l = labels[y][x]
            if l >= 0 and l not in keep:
                px[x, y] = (0, 0, 0, 0)
    return img

def kept_bounds(img):
    px = img.load(); w, h = img.size
    x0, y0, x1, y1 = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 0:
                x0 = min(x0, x); x1 = max(x1, x)
                y0 = min(y0, y); y1 = max(y1, y)
    return x0, y0, x1, y1

def remove_ground_shadow(img):
    bounds = kept_bounds(img)
    if bounds[2] < 0:
        return img
    x0, y0, x1, y1 = bounds
    zone_top = y0 + (y1 - y0) * 3 // 4
    px = img.load()
    for y in range(zone_top, y1 + 1):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a > 0 and r - g >= 15 and b - g >= 15:
                px[x, y] = (0, 0, 0, 0)
    return img

def canvas_head_x(img):
    """顶部 30% 区域的不透明像素水平中心"""
    kb = kept_bounds(img)
    if kb[2] < 0:
        return None
    x0, y0, x1, y1 = kb
    band_bottom = y0 + int((y1 - y0) * 0.30)
    px = img.load()
    hx0, hx1 = img.width, -1
    for y in range(y0, band_bottom + 1):
        for x in range(x0, x1 + 1):
            if px[x, y][3] > 0:
                hx0 = min(hx0, x); hx1 = max(hx1, x)
    return (hx0 + hx1) // 2 if hx1 >= 0 else (x0 + x1) // 2

def head_width(img):
    """头部区域（顶部40%）内最大行宽"""
    kb = kept_bounds(img)
    if kb[2] < 0:
        return 0
    x0, y0, x1, y1 = kb
    band_bottom = y0 + int((y1 - y0) * 0.40)
    px = img.load()
    hw = 0
    for y in range(y0, band_bottom + 1):
        rw0, rw1 = img.width, -1
        for x in range(img.width):
            if px[x, y][3] > 0:
                rw0 = min(rw0, x); rw1 = max(rw1, x)
        if rw1 >= 0:
            hw = max(hw, rw1 - rw0 + 1)
    return hw

# ===== 批量处理 8 帧 =====
results = []
for i in range(1, 9):
    fname = f"run-frame-{i}.png"
    print(f"\n=== {fname} ===")
    img = Image.open(os.path.join(SRC, fname)).convert("RGBA")

    img = clean_image(img)
    img = remove_ground_shadow(img)
    img = harden(img)
    img = clean_debris(img)
    x0, y0, x1, y1 = kept_bounds(img)
    if x1 < 0:
        print("  EMPTY!")
        results.append((i, None))
        continue
    top_y, feet = y0, y1

    seam = find_skirt_seam(img, top_y, feet)
    if seam is None or not (top_y + (feet - top_y) * 0.5 <= seam <= feet - 4):
        print(f"  seam detect FAILED (seam={seam}), skip surgery, fallback torso ratio")
        seam = top_y + int((feet - top_y) * 0.78)
    torso_raw = seam + 1 - top_y
    legs_raw = feet - seam
    k_up = TARGET_TORSO / torso_raw
    legs_target = LEGS[i]
    print(f"  raw: top={top_y} seam={seam} feet={feet} torso={torso_raw} legs={legs_raw} k_up={k_up:.3f}")

    upper = img.crop((0, top_y, img.width, seam + 1))
    legs = img.crop((0, seam + 1, img.width, feet + 1))
    # 裁掉左右空白，便于定中心
    ub = kept_bounds(upper); lb = kept_bounds(legs)
    upper = upper.crop((ub[0], 0, ub[2] + 1, upper.height))
    if lb[2] >= 0:
        legs = legs.crop((lb[0], 0, lb[2] + 1, legs.height))
    uw = max(1, round(upper.width * k_up))
    lw = max(1, round(legs.width * k_up))
    upper_s = upper.resize((uw, TARGET_TORSO), Image.NEAREST)
    legs_s = legs.resize((lw, legs_target), Image.NEAREST)

    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.paste(upper_s, ((SIZE - uw) // 2, BASELINE + 1 - legs_target - TARGET_TORSO), upper_s)
    canvas.paste(legs_s, ((SIZE - lw) // 2, BASELINE + 1 - legs_target), legs_s)
    # head_x 对齐（整体平移，脚底不动）
    hx = canvas_head_x(canvas)
    if hx is not None and hx != HEAD_X:
        out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        out.paste(canvas, (HEAD_X - hx, 0), canvas)
        canvas = out

    canvas.save(os.path.join(DST, fname))

    kb = kept_bounds(canvas)
    H = kb[3] - kb[1] + 1
    hw = head_width(canvas)
    print(f"  result: top={kb[1]} feet={kb[3]} H={H} headW={hw} legs={LEGS[i]}")
    results.append((i, {"H": H, "headW": hw, "top": kb[1], "legs": LEGS[i]}))

print("\n===== 汇总（v7 躯干缩放 + 分段腿部）=====")
print(f"{'frame':>7} {'topY':>5} {'H':>4} {'headW':>6} {'legs':>5}  (idle: top=66 H=190 headW≈112)")
all_ok = True
for i, r in results:
    if r is None:
        print(f"  {i:>5}  FAILED")
        all_ok = False
        continue
    ok = abs(r["headW"] - 112) <= 8 and r["legs"] == LEGS[i]
    if not ok:
        all_ok = False
    print(f"  {i:>5} {r['top']:>5} {r['H']:>4} {r['headW']:>6} {r['legs']:>5}  {'OK' if ok else 'CHECK'}")
print(f"\n{'ALL OK' if all_ok else 'NEED REVIEW'}")

# ===== 预览 =====
SCALE = 2
frames = [Image.open(os.path.join(DST, f"run-frame-{i}.png")).convert("RGBA") for i in range(1, 9)]
fw, fh = frames[0].size
sheet = Image.new("RGBA", (fw * SCALE * 8 + 9 * 8, fh * SCALE + 16), (222, 218, 204, 255))
for i, f in enumerate(frames):
    big = f.resize((fw * SCALE, fh * SCALE), Image.NEAREST)
    sheet.paste(big, (8 + i * (fw * SCALE + 8), 8), big)
sheet.save(os.path.join(PREV, "all8_run_v7.png"))
print("preview: tools\\run_previews\\all8_run_v7.png")

gif_path = os.path.join(PREV, "run_cycle_v7.gif")
bg = Image.new("RGBA", (SIZE, SIZE), (222, 218, 204, 255))
frames_gif = []
for f in frames:
    frame = bg.copy()
    frame.paste(f, (0, 0), f)
    frames_gif.append(frame.convert("P", palette=Image.ADAPTIVE))
frames_gif[0].save(gif_path, save_all=True, append_images=frames_gif[1:], duration=100, loop=0)
print("gif: tools\\run_previews\\run_cycle_v7.gif")

# idle vs run-1 对比图
idle = Image.open(os.path.join(DST, "frame-1.png")).convert("RGBA")
run1 = frames[0]
comp = Image.new("RGBA", (256 * 4 + 24, 256 * 2 + 8), (222, 218, 204, 255))
idle2 = idle.resize((512, 512), Image.NEAREST)
run2 = run1.resize((512, 512), Image.NEAREST)
comp.paste(idle2, (8, 4), idle2)
comp.paste(run2, (256 * 2 + 16, 4), run2)
comp.save(os.path.join(PREV, "compare_idle_vs_run_v7.png"))
print("compare: tools\\run_previews\\compare_idle_vs_run_v7.png")
