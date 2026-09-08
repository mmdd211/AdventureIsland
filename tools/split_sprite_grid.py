# 拆分 2×2 网格精灵表为单帧 PNG，输出到 data/player/ 供 clean_player_frames.py 使用
import os
import sys
from PIL import Image

sys.stdout.reconfigure(encoding="utf-8")

RAW = r"D:\KAFA\Workspace\ohter\AdventureIsland\data\player\raw"
OUT = r"D:\KAFA\Workspace\ohter\AdventureIsland\data\player"

# 动作名 → 帧文件名前缀映射
ACTION_MAP = {
    "idle":          "frame-",          # frame-1.png ~ frame-4.png
    "run":           "run-frame-",
    "jump-takeoff":  "jump-takeoff-frame-",
    "fall":          "fall-frame-",
    "landing":       "landing-frame-",
    "attack1":       "attack1-frame-",
    "attack2":       "attack2-frame-",
    "hurt":          "hurt-frame-",
    "death":         "death-frame-",
}

def split_grid(grid_path, prefix, out_dir):
    """拆分 2×2 网格为 4 个单帧"""
    img = Image.open(grid_path).convert("RGBA")
    w, h = img.size
    cell_w, cell_h = w // 2, h // 2
    count = 0
    # 网格顺序：左上=1, 右上=2, 左下=3, 右下=4
    positions = [
        (0, 0, cell_w, cell_h),           # 左上
        (cell_w, 0, w, cell_h),           # 右上
        (0, cell_h, cell_w, h),           # 左下
        (cell_w, cell_h, w, h),           # 右下
    ]
    for i, box in enumerate(positions):
        frame = img.crop(box)
        fname = f"{prefix}{i+1}.png"
        frame.save(os.path.join(out_dir, fname))
        count += 1
    return count

# 处理所有 raw 目录下的 2×2 网格图
total = 0
for action, prefix in ACTION_MAP.items():
    # 尝试 .jpg 和 .png 两种扩展名
    for ext in (".jpg", ".png"):
        grid_path = os.path.join(RAW, f"{action}-2x2{ext}")
        if os.path.exists(grid_path):
            n = split_grid(grid_path, prefix, OUT)
            print(f"{action}-2x2{ext} → {n} frames ({prefix}1~{n}.png)")
            total += n
            break
    else:
        print(f"WARNING: {action}-2x2 not found!")

print(f"\ntotal: {total} frames")
