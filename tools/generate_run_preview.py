# 生成 run 动画预览：1×8 精灵表放大图 + 循环 GIF
# 输入：assets/sprites/player/run-frame-1~8.png（256×256，透明背景）
# 输出：tools/run_previews/run_sheet_preview.png、run_cycle.gif
import os
import sys
from pathlib import Path

from PIL import Image

sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(r"D:\KAFA\Workspace\ohter\AdventureIsland")
SRC = ROOT / "assets" / "sprites" / "player"
OUT = ROOT / "tools" / "run_previews"
SCALE = 3
BG = (222, 218, 204, 255)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    frames = [Image.open(SRC / f"run-frame-{i}.png").convert("RGBA") for i in range(1, 9)]
    for f in frames:
        if f.size != (256, 256):
            print(f"WARNING: unexpected size {f.size}")
    enlarged = [f.resize((f.width * SCALE, f.height * SCALE), Image.Resampling.NEAREST) for f in frames]

    # 1×8 精灵表放大图
    sheet_w = sum(f.width for f in enlarged)
    sheet_h = max(f.height for f in enlarged)
    sheet = Image.new("RGBA", (sheet_w, sheet_h), BG)
    x = 0
    for f in enlarged:
        sheet.alpha_composite(f, (x, 0))
        x += f.width
    sheet.save(OUT / "run_sheet_preview.png")
    print(f"generated {OUT / 'run_sheet_preview.png'} ({sheet.size})")

    # 循环 GIF（每帧 100ms，循环播放）
    gif_frames = []
    for f in enlarged:
        bg = Image.new("RGBA", f.size, BG)
        bg.alpha_composite(f)
        gif_frames.append(bg.convert("P", palette=Image.Palette.ADAPTIVE))
    gif_frames[0].save(
        OUT / "run_cycle.gif",
        save_all=True,
        append_images=gif_frames[1:],
        duration=100,
        loop=0,
    )
    print(f"generated {OUT / 'run_cycle.gif'} (8 frames, 100ms/frame)")


if __name__ == "__main__":
    main()
