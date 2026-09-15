#!/usr/bin/env python3
"""sprite_pipeline.py — 统一精灵表后处理管线

整合 tools/ 中碎片化的后处理脚本为一个参数化入口。
支持 process / verify / assemble 三个子命令。

用法:
  python sprite_pipeline.py process --input raw.png --rows 2 --cols 3 --output-dir out/
  python sprite_pipeline.py verify --input-dir out/ --reference out/frame_00.png
  python sprite_pipeline.py assemble --input-dir out/ --output strip.png --layout 1x8
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image

sys.stdout.reconfigure(encoding="utf-8")


# ── 色键检测 ──────────────────────────────────────────────

def is_key_color(r: int, g: int, b: int, a: int, key: str) -> bool:
    if a < 20:
        return True
    if key == "green":
        return g > 180 and r < 110 and b < 110 and g > r + 60 and g > b + 60
    # magenta (default): 宽容差以识别 AI 生成的偏色洋红
    if r > 210 and g > 210 and b > 210 and abs(r - g) < 25 and abs(g - b) < 25:
        return True
    return r >= 150 and b >= 130 and g <= 120 and (r - g) >= 50 and (b - g) >= 50


def key_out_background(img: Image.Image, key: str = "magenta") -> Image.Image:
    """色键去除背景,返回透明 RGBA。"""
    rgba = img.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if is_key_color(r, g, b, a, key):
                px[x, y] = (0, 0, 0, 0)
            else:
                px[x, y] = (r, g, b, 255)
    return rgba


# ── 网格切帧 ──────────────────────────────────────────────

def split_grid(img: Image.Image, rows: int, cols: int) -> list[Image.Image]:
    """按 rows×cols 网格行优先切分为单帧。"""
    w, h = img.size
    cell_w, cell_h = w // cols, h // rows
    frames = []
    for r in range(rows):
        for c in range(cols):
            box = (c * cell_w, r * cell_h, (c + 1) * cell_w, (r + 1) * cell_h)
            frames.append(img.crop(box))
    return frames


# ── 对齐与缩放 ────────────────────────────────────────────

def find_subject_bbox(img: Image.Image, alpha_threshold: int = 20) -> tuple[int, int, int, int] | None:
    """找到非透明像素的边界框。"""
    bbox = img.getbbox()
    if bbox is None:
        return None
    return bbox


def align_frames(frames: list[Image.Image], align: str = "center", cell_size: int = 128) -> list[Image.Image]:
    """将各帧主体对齐到统一锚点后放入固定尺寸画布。"""
    result = []
    for frame in frames:
        canvas = Image.new("RGBA", (cell_size, cell_size), (0, 0, 0, 0))
        bbox = find_subject_bbox(frame)
        if bbox is None:
            result.append(canvas)
            continue
        subject = frame.crop(bbox)
        sw, sh = subject.size

        if align == "feet":
            x = (cell_size - sw) // 2
            y = cell_size - sh - max(1, cell_size // 16)  # 底部留一点边距
        elif align == "bottom":
            x = (cell_size - sw) // 2
            y = cell_size - sh
        else:  # center
            x = (cell_size - sw) // 2
            y = (cell_size - sh) // 2

        canvas.paste(subject, (max(0, x), max(0, y)))
        result.append(canvas)
    return result


def scale_frames_shared(frames: list[Image.Image], cell_size: int, fit_scale: float = 0.85) -> list[Image.Image]:
    """共享缩放: 取所有帧主体的最大尺寸,统一缩放比例。"""
    max_w, max_h = 0, 0
    for frame in frames:
        bbox = find_subject_bbox(frame)
        if bbox:
            max_w = max(max_w, bbox[2] - bbox[0])
            max_h = max(max_h, bbox[3] - bbox[1])
    if max_w == 0 or max_h == 0:
        return frames

    target = int(cell_size * fit_scale)
    scale = min(target / max_w, target / max_h, 1.0)
    if scale >= 0.99:
        return frames

    result = []
    for frame in frames:
        nw, nh = int(frame.width * scale), int(frame.height * scale)
        result.append(frame.resize((nw, nh), Image.NEAREST))
    return result


# ── QC 指标 ────────────────────────────────────────────────

def compute_qc(frames: list[Image.Image]) -> dict:
    """计算帧间一致性 QC 指标。"""
    heights = []
    centers_y = []
    edge_touch = 0

    for i, frame in enumerate(frames):
        bbox = find_subject_bbox(frame)
        if bbox is None:
            continue
        h = bbox[3] - bbox[1]
        cy = (bbox[1] + bbox[3]) / 2.0
        heights.append(h)
        centers_y.append(cy)

        # 检查是否触边
        if bbox[0] <= 1 or bbox[1] <= 1 or bbox[2] >= frame.width - 1 or bbox[3] >= frame.height - 1:
            edge_touch += 1

    if not heights:
        return {"body_scale_cv": 0.0, "anchor_y_std": 0.0, "edge_touch_frames": 0, "frame_count": 0}

    import math
    mean_h = sum(heights) / len(heights)
    var_h = sum((h - mean_h) ** 2 for h in heights) / len(heights)
    cv = math.sqrt(var_h) / mean_h if mean_h > 0 else 0.0

    mean_cy = sum(centers_y) / len(centers_y)
    var_cy = sum((cy - mean_cy) ** 2 for cy in centers_y) / len(centers_y)
    std_cy = math.sqrt(var_cy)

    return {
        "body_scale_cv": round(cv, 4),
        "anchor_y_std": round(std_cy / max(1, mean_h), 4),
        "edge_touch_frames": edge_touch,
        "frame_count": len(frames),
        "mean_subject_height": round(mean_h, 1),
    }


# ── Scale Profile ──────────────────────────────────────────

def write_scale_profile(path: Path, cell_size: int, fit_scale: float, align: str, qc: dict, name: str = "") -> None:
    profile = {
        "version": 1,
        "name": name,
        "cell_size": cell_size,
        "fit_scale": fit_scale,
        "align": align,
        "mean_subject_height": qc.get("mean_subject_height", 0),
        "body_scale_cv": qc.get("body_scale_cv", 0),
    }
    path.write_text(json.dumps(profile, indent=2, ensure_ascii=False), encoding="utf-8")


def load_scale_profile(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


# ── 子命令: process ────────────────────────────────────────

def cmd_process(args) -> None:
    input_path = Path(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    raw = Image.open(input_path)
    print(f"输入: {input_path} ({raw.size[0]}x{raw.size[1]})")

    # 1. 色键
    keyed = key_out_background(raw, args.key)
    keyed.save(output_dir / "sheet-transparent.png")
    print(f"色键完成 ({args.key})")

    # 2. 切帧
    frames = split_grid(keyed, args.rows, args.cols)
    print(f"切帧完成: {args.rows}x{args.cols} = {len(frames)} 帧")

    # 3. 缩放 (共享)
    if args.scale_profile:
        profile = load_scale_profile(Path(args.scale_profile))
        cell_size = profile["cell_size"]
        fit_scale = profile["fit_scale"]
        align = profile["align"]
        print(f"使用 Scale Profile: cell={cell_size}, fit={fit_scale}, align={align}")
    else:
        cell_size = args.cell_size
        fit_scale = args.fit_scale
        align = args.align

    frames = scale_frames_shared(frames, cell_size, fit_scale)

    # 4. 对齐
    frames = align_frames(frames, align, cell_size)

    # 5. 保存帧
    for i, frame in enumerate(frames):
        frame.save(output_dir / f"frame_{i:02d}.png")
    print(f"输出 {len(frames)} 帧到 {output_dir}/")

    # 6. QC
    qc = compute_qc(frames)
    meta = {
        "input": str(input_path),
        "rows": args.rows,
        "cols": args.cols,
        "key": args.key,
        "cell_size": cell_size,
        "fit_scale": fit_scale,
        "align": align,
        "qc": qc,
    }
    (output_dir / "pipeline-meta.json").write_text(
        json.dumps(meta, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    print(f"QC: scale_cv={qc['body_scale_cv']}, anchor_std={qc['anchor_y_std']}, edge_touch={qc['edge_touch_frames']}")

    # 7. 可选写 Scale Profile
    if args.write_scale_profile:
        write_scale_profile(
            Path(args.write_scale_profile), cell_size, fit_scale, align, qc,
            name=args.profile_name or input_path.stem,
        )
        print(f"Scale Profile 已写入: {args.write_scale_profile}")


# ── 子命令: verify ─────────────────────────────────────────

def cmd_verify(args) -> None:
    input_dir = Path(args.input_dir)
    frames = sorted(input_dir.glob("frame_*.png"))
    if not frames:
        print(f"错误: {input_dir} 中未找到 frame_*.png")
        sys.exit(1)

    images = [Image.open(f) for f in frames]
    qc = compute_qc(images)

    print(f"帧数: {qc['frame_count']}")
    print(f"body_scale_cv: {qc['body_scale_cv']} (目标 ≤ 0.08)")
    print(f"anchor_y_std:  {qc['anchor_y_std']} (目标 ≤ 0.05)")
    print(f"edge_touch:    {qc['edge_touch_frames']} (目标 = 0)")

    ok = qc["body_scale_cv"] <= 0.08 and qc["anchor_y_std"] <= 0.05 and qc["edge_touch_frames"] == 0
    print(f"结果: {'PASS' if ok else 'FAIL'}")
    sys.exit(0 if ok else 1)


# ── 子命令: assemble ───────────────────────────────────────

def cmd_assemble(args) -> None:
    input_dir = Path(args.input_dir)
    frames = sorted(input_dir.glob("frame_*.png"))
    if not frames:
        print(f"错误: {input_dir} 中未找到 frame_*.png")
        sys.exit(1)

    parts = args.layout.lower().split("x")
    rows, cols = int(parts[0]), int(parts[1])
    images = [Image.open(f) for f in frames]

    if len(images) != rows * cols:
        print(f"警告: 帧数 {len(images)} ≠ 布局 {rows}x{cols}={rows*cols}")

    cell_w = images[0].width
    cell_h = images[0].height
    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (0, 0, 0, 0))

    for i, img in enumerate(images[: rows * cols]):
        r, c = divmod(i, cols)
        sheet.paste(img, (c * cell_w, r * cell_h))

    output = Path(args.output)
    sheet.save(output)
    print(f"组装完成: {output} ({sheet.size[0]}x{sheet.size[1]}, {rows}x{cols})")


# ── CLI ────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="统一精灵表后处理管线")
    sub = parser.add_subparsers(dest="command", required=True)

    # process
    p = sub.add_parser("process", help="色键抠图 + 切帧 + 缩放 + 对齐 + QC")
    p.add_argument("--input", required=True, help="原始精灵表路径")
    p.add_argument("--rows", type=int, default=2, help="网格行数")
    p.add_argument("--cols", type=int, default=3, help="网格列数")
    p.add_argument("--key", choices=["magenta", "green"], default="magenta", help="色键颜色")
    p.add_argument("--cell-size", type=int, default=128, help="输出帧尺寸")
    p.add_argument("--fit-scale", type=float, default=0.85, help="主体占画布比例")
    p.add_argument("--align", choices=["center", "feet", "bottom"], default="center", help="对齐锚点")
    p.add_argument("--output-dir", required=True, help="输出目录")
    p.add_argument("--scale-profile", help="引用已有 Scale Profile JSON")
    p.add_argument("--write-scale-profile", help="写出 Scale Profile JSON 路径")
    p.add_argument("--profile-name", help="Profile 名称")
    p.set_defaults(func=cmd_process)

    # verify
    v = sub.add_parser("verify", help="检查帧间一致性 QC")
    v.add_argument("--input-dir", required=True, help="包含 frame_*.png 的目录")
    v.set_defaults(func=cmd_verify)

    # assemble
    a = sub.add_parser("assemble", help="从帧组装网格/条带")
    a.add_argument("--input-dir", required=True, help="包含 frame_*.png 的目录")
    a.add_argument("--output", required=True, help="输出图片路径")
    a.add_argument("--layout", default="1x8", help="布局如 2x4, 1x8")
    a.set_defaults(func=cmd_assemble)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
