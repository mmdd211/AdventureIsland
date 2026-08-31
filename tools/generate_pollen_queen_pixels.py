from __future__ import annotations

import math
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw


TARGET_SIZES = {"bee": 192, "dancer": 224}
LOGICAL_SIZES = {"bee": 64, "dancer": 72}
FRAME_COUNTS = {"idle": 6, "move": 6, "attack": 7, "skill": 8, "hurt": 3, "evolve": 8, "death": 6}
FRAME_FPS = {"idle": 8, "move": 10, "attack": 14, "skill": 12, "hurt": 14, "evolve": 8, "death": 8}

OUTLINE = (36, 20, 17, 255)
DARK = (56, 27, 20, 255)
ABDOMEN = (106, 49, 24, 255)
HONEY = (196, 122, 32, 255)
HONEY_LIGHT = (232, 164, 62, 255)
POLLEN = (255, 224, 106, 255)
CORE = (255, 240, 176, 255)
PETAL_DARK = (112, 31, 52, 255)
PETAL = (184, 54, 84, 255)
PETAL_LIGHT = (242, 122, 98, 255)
SKIN = (244, 214, 160, 255)
SKIN_DARK = (178, 120, 86, 255)
HAIR = (231, 189, 119, 255)
HAIR_DARK = (140, 77, 46, 255)
WING = (204, 183, 150, 220)
WING_LIGHT = (244, 226, 190, 210)
CLOUD = (255, 214, 96, 184)
PETAL_TRAIL = (216, 79, 106, 186)


@dataclass
class Canvas:
    image: Image.Image
    pixels: Image.Image


def new_canvas(size: int) -> Canvas:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    return Canvas(image=image, pixels=ImageDraw.Draw(image))


def px(draw: ImageDraw.ImageDraw, x: int, y: int, color: tuple) -> None:
    draw.point((int(round(x)), int(round(y))), fill=color)


def ellipse(draw: ImageDraw.ImageDraw, x0: int, y0: int, x1: int, y1: int, color: tuple) -> None:
    draw.ellipse((x0, y0, x1, y1), fill=color, outline=OUTLINE, width=1)


def line(draw: ImageDraw.ImageDraw, start: tuple[int, int], end: tuple[int, int], color: tuple, width: int = 1) -> None:
    draw.line((start, end), fill=color, width=width)


def draw_bee_base(draw: ImageDraw.ImageDraw, phase: float, state: str, index: int, count: int) -> None:
    sway = math.sin(phase * math.tau)
    progress = index / max(1, count - 1) if count > 1 else 0.0
    if state == "idle":
        wing_open = 0.30 + sway * 0.12
        pitch = sway * 1.0
    elif state == "move":
        wing_open = 0.46 + sway * 0.24
        pitch = sway * 2.4
    elif state == "attack":
        wing_open = 0.12 - progress * 0.04
        pitch = -4.0 + progress * 6.0
    elif state == "skill":
        wing_open = 0.72 + sway * 0.14
        pitch = -1.5 + progress
    elif state == "hurt":
        wing_open = 0.10
        pitch = 2.0 - progress * 1.5
    elif state == "evolve":
        wing_open = 0.20 + progress * 0.66
        pitch = 3.0 - progress * 5.0
    else:
        wing_open = 0.18 * (1.0 - progress)
        pitch = 2.0 + progress * 2.0
    bob = round(pitch)
    cx, cy = 32, 36 + bob

    # Wings: two large insect membranes with clear facets.
    for side in (-1, 1):
        root = (cx + side * 6, cy - 9)
        tip = (cx + side * (14 + wing_open * 24), cy - (8 + wing_open * 20) - sway * 2)
        lower = (cx + side * 17, cy - 1)
        draw.polygon([root, tip, lower], fill=WING, outline=OUTLINE)
        draw.polygon([(root[0] + side * 2, root[1] + 2), (tip[0] - side * 3, tip[1] + 4), (lower[0] - side * 2, lower[1] + 1)], fill=WING_LIGHT)
        line(draw, root, tip, HAIR_DARK)
        line(draw, root, lower, HAIR_DARK)

    # Abdomen: oversized honey bands and pollen core.
    ellipse(draw, cx - 27, cy + 1, cx + 6, cy + 23, DARK)
    ellipse(draw, cx - 24, cy + 3, cx + 3, cy + 20, ABDOMEN)
    for index, band in enumerate((-18, -9, 0)):
        y = cy + 7 + index * 4
        line(draw, (cx + band, y), (cx + 3, y + 2), OUTLINE, 2)
        line(draw, (cx + band + 2, y - 1), (cx + 1, y + 1), HONEY)
    ellipse(draw, cx - 22, cy + 5, cx - 15, cy + 11, HONEY_LIGHT)
    ellipse(draw, cx - 20, cy + 7, cx - 17, cy + 9, POLLEN)
    tail_reach = 2 if state not in ("attack", "move") else 5
    line(draw, (cx - 29, cy + 19), (cx - 35 - tail_reach, cy + 25 + tail_reach), DARK, 2)
    line(draw, (cx - 34 - tail_reach, cy + 24 + tail_reach), (cx - 39 - tail_reach, cy + 29 + tail_reach), HONEY)

    # Thorax, flower collar, face and crown.
    ellipse(draw, cx + 1, cy - 13, cx + 17, cy + 4, DARK)
    ellipse(draw, cx + 4, cy - 11, cx + 14, cy + 1, ABDOMEN)
    for petal_index in range(6):
        angle = -2.5 + petal_index * 0.5 + (0.10 if state == "skill" else 0)
        tip = (cx + 8 + math.cos(angle) * 9, cy - 13 + math.sin(angle) * 8)
        draw.polygon([(cx + 8, cy - 12), tip, (cx + 10, cy - 8)], fill=PETAL, outline=OUTLINE)
        line(draw, (cx + 8, cy - 12), tip, PETAL_LIGHT)
    ellipse(draw, cx + 7, cy - 17, cx + 17, cy - 7, SKIN_DARK)
    ellipse(draw, cx + 8, cy - 16, cx + 16, cy - 8, SKIN)
    px(draw, cx + 10, cy - 13, OUTLINE)
    px(draw, cx + 14, cy - 13, OUTLINE)
    line(draw, (cx + 8, cy - 11), (cx + 16, cy - 11), HAIR_DARK)
    draw.polygon([(cx + 10, cy - 20), (cx + 13, cy - 25), (cx + 16, cy - 20)], fill=HONEY, outline=OUTLINE)
    draw.polygon([(cx + 15, cy - 20), (cx + 18, cy - 24), (cx + 20, cy - 19)], fill=PETAL, outline=OUTLINE)
    line(draw, (cx + 9, cy - 20), (cx + 6, cy - 26), HAIR_DARK, 2)
    line(draw, (cx + 18, cy - 20), (cx + 21, cy - 26), HAIR_DARK, 2)

    # Legs and attack spur.
    for leg in range(3):
        y = cy + 3 + leg * 5
        stretch = 2 if state in ("attack", "move") else 0
        line(draw, (cx + 3, y), (cx + 12 + leg + stretch, y + 3), DARK, 2)
        line(draw, (cx + 12 + leg + stretch, y + 3), (cx + 18 + leg + stretch, y + 1), HONEY)
        line(draw, (cx - 4, y), (cx - 12 - leg, y + 4), DARK, 2)

    if state == "move":
        for trail in range(4):
            px(draw, cx - 30 - trail * 6, cy + 13 + trail * 2, CLOUD if trail < 2 else HONEY_LIGHT)
    elif state == "attack":
        for spark in range(5):
            px(draw, cx + 24 + spark * 4, cy - 8 + spark * 3, POLLEN if spark % 2 == 0 else CORE)
        for wind in range(4):
            line(draw, (cx - 28 + wind * 3, cy - 2 + wind * 6), (cx - 36 + wind * 3, cy - 3 + wind * 6), CLOUD)
    elif state == "skill":
        for cloud_index in range(10):
            angle = math.tau * cloud_index / 10 + progress * 1.6
            radius = 8 + progress * 12
            x = int(cx - 10 + math.cos(angle) * radius)
            y = int(cy + 14 + math.sin(angle) * radius * 0.48)
            px(draw, x, y, CLOUD if cloud_index % 2 == 0 else POLLEN)
            if cloud_index % 4 == 0:
                px(draw, x - 1, y, HONEY_LIGHT)
    elif state == "evolve":
        for mote in range(8):
            angle = math.tau * mote / 8 - progress * 2.0
            radius = 6 + progress * 15
            x = int(cx + 4 + math.cos(angle) * radius)
            y = int(cy - 3 + math.sin(angle) * radius * 0.60)
            px(draw, x, y, CORE if progress > 0.5 else HONEY_LIGHT)


def draw_dancer_base(draw: ImageDraw.ImageDraw, phase: float, state: str, index: int, count: int) -> None:
    sway = math.sin(phase * math.tau)
    progress = index / max(1, count - 1) if count > 1 else 0.0
    if state == "idle":
        skirt_sway = sway * 0.5
        arm_lift = sway * 0.4
    elif state == "move":
        skirt_sway = sway * 1.8
        arm_lift = sway * 0.9
    elif state == "attack":
        skirt_sway = -0.9 + progress * 1.6
        arm_lift = -0.5 + progress * 1.8
    elif state == "skill":
        skirt_sway = 1.2 + math.sin(progress * math.pi) * 1.2
        arm_lift = 1.0 + math.sin(progress * math.pi) * 0.7
    elif state == "hurt":
        skirt_sway = -0.4
        arm_lift = -0.3
    elif state == "evolve":
        skirt_sway = 0.5 + progress
        arm_lift = 0.4 + progress * 1.2
    else:
        skirt_sway = -0.2
        arm_lift = -0.2
    cx, cy = 36, 35

    # Petal cape opens behind the shoulders.
    for side in (-1, 1):
        for index in range(3):
            root = (cx + side * 9, cy - 7 + index * 2)
            tip = (cx + side * (22 + index * 5), cy - 20 + index * 11 + skirt_sway * 3)
            fill = PETAL if index == 0 else (PETAL_LIGHT if index == 1 else PETAL_DARK)
            draw.polygon([root, tip, (root[0] + side * 2, root[1] + 8)], fill=fill, outline=OUTLINE)
            line(draw, root, tip, CORE if index == 0 else HONEY_LIGHT)

    # Layered skirt, body and pollen core.
    for layer in range(4):
        width = 9 + layer * 5 + int((skirt_sway + (1.0 if state == "skill" else 0.0)) * layer * 0.7)
        y = cy + 4 + layer * 7
        fill = PETAL_DARK if layer in (0, 2) else PETAL
        draw.polygon([
            (cx - width, y), (cx + width, y), (cx + width + 3, y + 8),
            (cx + width * 0.4, y + 12), (cx - width * 0.4, y + 12), (cx - width - 3, y + 8)
        ], fill=fill, outline=OUTLINE)
        line(draw, (cx - width, y + 4), (cx + width, y + 4), PETAL_LIGHT if layer % 2 else HONEY)
    ellipse(draw, cx - 7, cy - 11, cx + 7, cy + 7, DARK)
    ellipse(draw, cx - 5, cy - 9, cx + 5, cy + 5, HAIR_DARK)
    ellipse(draw, cx - 3, cy - 7, cx + 3, cy + 3, ABDOMEN)
    ellipse(draw, cx - 2, cy - 5, cx + 2, cy + 1, POLLEN)
    px(draw, cx, cy - 2, CORE)

    # Arms and upper body.
    line(draw, (cx - 6, cy - 7), (cx - 18, cy - 14 - arm_lift * 6), DARK, 2)
    line(draw, (cx + 6, cy - 7), (cx + 18, cy - 8 + arm_lift * 5), DARK, 2)
    px(draw, cx - 19, cy - 15 - arm_lift * 6, SKIN)
    px(draw, cx + 19, cy - 7 + arm_lift * 5, SKIN)

    # Hair, face and large crown.
    ellipse(draw, cx - 8, cy - 25, cx + 8, cy - 8, HAIR_DARK)
    ellipse(draw, cx - 7, cy - 24, cx + 7, cy - 10, HAIR)
    ellipse(draw, cx - 5, cy - 21, cx + 5, cy - 12, SKIN)
    px(draw, cx - 2, cy - 18, OUTLINE)
    px(draw, cx + 2, cy - 18, OUTLINE)
    line(draw, (cx - 3, cy - 15), (cx + 3, cy - 15), HAIR_DARK)
    draw.polygon([(cx - 10, cy - 27), (cx - 7, cy - 37), (cx - 4, cy - 27)], fill=PETAL, outline=OUTLINE)
    draw.polygon([(cx - 3, cy - 29), (cx, cy - 42), (cx + 3, cy - 29)], fill=HONEY, outline=OUTLINE)
    draw.polygon([(cx + 4, cy - 27), (cx + 7, cy - 37), (cx + 10, cy - 27)], fill=PETAL_LIGHT, outline=OUTLINE)

    if state == "attack":
        for arc in range(5):
            px(draw, cx + 24 + arc * 3, cy - 14 + arc * 5, PETAL_LIGHT if arc < 3 else CORE)
        line(draw, (cx + 20, cy - 2), (cx + 34, cy - 12), PETAL_TRAIL, 2)
    elif state == "skill":
        for lane in range(3):
            lane_y = cy + 18 + lane * 8
            for step in range(5):
                x = cx - 24 + step * 12 + lane * 4
                y = lane_y - int(abs(step - 2) * 2)
                px(draw, x, y, PETAL_TRAIL if step % 2 == 0 else PETAL_LIGHT)
                if progress > 0.35 and step in (1, 3):
                    px(draw, x + 1, y + 1, CORE)
    elif state == "move":
        for trail in range(4):
            px(draw, cx - 26 - trail * 5, cy + 18 + trail * 5 + int(math.sin(trail * 1.3) * 2), PETAL_TRAIL if trail < 2 else PETAL_LIGHT)
    elif state == "evolve":
        for mote in range(10):
            angle = math.tau * mote / 10 + progress * 1.4
            radius = 8 + progress * 16
            x = int(cx + math.cos(angle) * radius)
            y = int(cy + 8 + math.sin(angle) * radius * 0.55)
            px(draw, x, y, CORE if progress > 0.55 else PETAL_LIGHT)


def frame_canvas(subject: str, state: str, index: int, count: int) -> Image.Image:
    # Idle/move sine loops can produce symmetric integer pixel pairs; this offset
    # keeps every exported pose distinct without breaking the loop feel.
    phase = (index + 0.18) / max(1, count)
    logical = LOGICAL_SIZES[subject]
    canvas = new_canvas(logical)
    if subject == "bee":
        draw_bee_base(canvas.pixels, phase, state, index, count)
    else:
        draw_dancer_base(canvas.pixels, phase, state, index, count)

    if state == "attack":
        angle = -5.0 + (index / max(1, count - 1)) * 10.0
        canvas.image = canvas.image.rotate(angle, resample=Image.Resampling.NEAREST, center=(logical * 0.62, logical * 0.42))
        canvas.pixels = ImageDraw.Draw(canvas.image)
        center = (int(logical * 0.78), int(logical * 0.40))
        for offset in range(-2, 3):
            px(canvas.pixels, center[0] + offset * 3, center[1] + offset, POLLEN if subject == "bee" else PETAL_LIGHT)
    elif state == "skill":
        cx, cy = logical // 2, int(logical * 0.48)
        for particle in range(14):
            angle = math.tau * particle / 14 + phase * math.tau
            radius = logical * 0.22 + phase * logical * 0.20
            color = POLLEN if subject == "bee" else PETAL_LIGHT
            px(canvas.pixels, cx + math.cos(angle) * radius, cy + math.sin(angle) * radius * 0.72, color)
    elif state == "hurt":
        canvas.image = canvas.image.rotate(2 if index % 2 else -2, resample=Image.Resampling.NEAREST, center=(logical // 2, logical // 2))
        canvas.pixels = ImageDraw.Draw(canvas.image)
        overlay = Image.new("RGBA", canvas.image.size, (255, 70, 84, 58))
        canvas.image = Image.alpha_composite(canvas.image, overlay)
        canvas.pixels = ImageDraw.Draw(canvas.image)
    elif state == "evolve":
        for particle in range(18):
            x = logical // 2 + math.cos(math.tau * particle / 18) * (logical * 0.12 + phase * logical * 0.24)
            y = logical * 0.52 - math.sin(math.tau * particle / 18) * (logical * 0.10 + phase * logical * 0.22)
            px(canvas.pixels, x, y, CORE)
    elif state == "death":
        fade = 1.0 - index / max(1, count - 1)
        alpha = canvas.image.getchannel("A").point(lambda value: int(value * fade))
        canvas.image.putalpha(alpha)
        canvas.pixels = ImageDraw.Draw(canvas.image)

    return canvas.image


def are_frames_equal(left: Image.Image, right: Image.Image) -> bool:
    if left.size != right.size:
        return False
    return left.tobytes() == right.tobytes()


def upscale(image: Image.Image, target: int) -> Image.Image:
    return image.resize((target, target), Image.Resampling.NEAREST)


def generate(output: Path) -> None:
    output.mkdir(parents=True, exist_ok=True)
    previews = Path("tools/pollen_queen_previews")
    previews.mkdir(parents=True, exist_ok=True)

    for subject, target in TARGET_SIZES.items():
        for state, count in FRAME_COUNTS.items():
            frames = [upscale(frame_canvas(subject, state, index, count), target) for index in range(count)]
            if any(are_frames_equal(frames[i], frames[i + 1]) for i in range(len(frames) - 1)):
                raise RuntimeError(f"{subject}/{state} has duplicate adjacent frames")
            for index, frame in enumerate(frames):
                frame.save(output / f"pollen_queen_{subject}_{state}_{index:02d}.png")
            gif_frames = [frame.convert("P", colors=64) for frame in frames]
            gif_frames[0].save(
                previews / f"pollen_queen_{subject}_{state}.gif",
                save_all=True,
                append_images=gif_frames[1:],
                duration=int(1000 / FRAME_FPS[state]),
                loop=0,
                disposal=2,
                transparency=0,
            )

    cell = max(TARGET_SIZES.values())
    sheet = Image.new("RGBA", (cell * len(FRAME_COUNTS), cell * 2), (18, 21, 27, 255))
    for row, subject in enumerate(("bee", "dancer")):
        for column, state in enumerate(FRAME_COUNTS):
            frame = Image.open(output / f"pollen_queen_{subject}_{state}_00.png")
            sheet.alpha_composite(frame, (column * cell, row * cell))
    sheet.save(previews / "pollen_queen_contact_sheet.png")
    print("generated hand-pixelled dynamic pollen queen")


if __name__ == "__main__":
    generate(Path("assets/sprites/monsters/pollen_queen"))
