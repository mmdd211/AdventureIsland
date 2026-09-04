from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw


TARGET_SIZES = {"turtle": (216, 168), "gatekeeper": (216, 264)}
LOGICAL_SIZES = {"turtle": (72, 56), "gatekeeper": (72, 88)}
FRAME_COUNTS = {"idle": 6, "move": 6, "attack": 7, "skill": 8, "hurt": 3, "evolve": 8, "death": 6}
FRAME_FPS = {"idle": 7, "move": 9, "attack": 13, "skill": 11, "hurt": 13, "evolve": 7, "death": 7}

OUTLINE = (22, 27, 19, 255)
DARK = (45, 56, 40, 255)
MOSS = (79, 111, 56, 255)
MOSS_LIGHT = (124, 139, 74, 255)
STONE = (128, 118, 84, 255)
STONE_LIGHT = (170, 155, 110, 255)
CAP_DARK = (129, 44, 32, 255)
CAP = (184, 64, 47, 255)
CAP_LIGHT = (215, 95, 69, 255)
CREAM = (238, 223, 192, 255)
WOOD = (135, 91, 49, 255)
WOOD_DARK = (84, 56, 30, 255)
WOOD_LIGHT = (181, 129, 72, 255)
IRON = (95, 104, 112, 255)
SPORE = (140, 69, 200, 255)
SPORE_LIGHT = (192, 122, 240, 255)
SPORE_GLOW = (233, 197, 255, 255)
SKIN = (94, 118, 75, 255)
SKIN_DARK = (55, 74, 48, 255)


def new_canvas(size: tuple[int, int]) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)


def px(draw: ImageDraw.ImageDraw, x: float, y: float, color: tuple) -> None:
    draw.point((int(round(x)), int(round(y))), fill=color)


def ellipse(draw: ImageDraw.ImageDraw, box: tuple[float, float, float, float], color: tuple, outline: tuple = OUTLINE) -> None:
    draw.ellipse(box, fill=color, outline=outline, width=1)


def line(draw: ImageDraw.ImageDraw, start: tuple[float, float], end: tuple[float, float], color: tuple, width: int = 1) -> None:
    draw.line((start, end), fill=color, width=width)


def draw_small_mushroom(draw: ImageDraw.ImageDraw, x: float, y: float, scale: float = 1.0) -> None:
    width = max(2, int(5 * scale))
    height = max(2, int(4 * scale))
    draw.ellipse((x - width, y - height, x + width, y), fill=CAP, outline=OUTLINE)
    draw.rectangle((x - 1, y - 2, x + 1, y + 2), fill=CREAM, outline=OUTLINE)
    px(draw, x - width // 2, y - height // 2, CREAM)


def draw_turtle(draw: ImageDraw.ImageDraw, phase: float, state: str, index: int, count: int) -> None:
    progress = index / max(1, count - 1) if count > 1 else 0.0
    breath = math.sin(phase * math.tau)
    if state == "idle":
        body_shift = 0
        body_bob = round(breath)
        leg_phase = 0.0
    elif state == "move":
        body_shift = round(breath * 2)
        body_bob = round(math.sin(phase * math.tau * 2) * 1.5)
        leg_phase = phase * math.tau
    elif state == "attack":
        body_shift = round(-1.5 + progress * 3.0)
        body_bob = round(math.sin(progress * math.pi) * 1.0)
        leg_phase = 0.0
    elif state == "skill":
        body_shift = round(math.sin(progress * math.pi) * 3.0)
        body_bob = round(math.sin(progress * math.tau) * 2.0)
        leg_phase = phase * math.tau
    elif state == "hurt":
        body_shift = 2 if index % 2 else -2
        body_bob = 1
        leg_phase = 0.0
    elif state == "evolve":
        body_shift = 0
        body_bob = round(-progress * 3.0)
        leg_phase = 0.0
    else:
        body_shift = 0
        body_bob = round(progress * 3.0)
        leg_phase = 0.0

    cx = 38 + body_shift
    cy = 31 + body_bob

    # Heavy legs stay visible under the shell.
    for leg_index, leg_x in enumerate((18, 30, 48, 58)):
        swing = int(math.sin(leg_phase + leg_index * math.pi * 0.5) * 2)
        draw.rectangle((leg_x - 6, cy + 5, leg_x + 6, cy + 19 + swing), fill=SKIN_DARK, outline=OUTLINE)
        draw.rectangle((leg_x - 5, cy + 12 + swing, leg_x + 5, cy + 17 + swing), fill=SKIN, outline=OUTLINE)
        for claw in range(3):
            draw.polygon(
                [(leg_x - 4 + claw * 4, cy + 16 + swing), (leg_x - 2 + claw * 4, cy + 22 + swing), (leg_x + claw * 4, cy + 16 + swing)],
                fill=CREAM,
                outline=OUTLINE,
            )

    # Head and short neck face left.
    ellipse(draw, (4, cy - 7, 24, cy + 13), SKIN_DARK)
    ellipse(draw, (6, cy - 5, 20, cy + 11), SKIN)
    draw.polygon([(3, cy + 1), (0, cy + 4), (3, cy + 7)], fill=CREAM, outline=OUTLINE)
    px(draw, 9, cy - 1, OUTLINE)
    px(draw, 10, cy, CREAM)
    line(draw, (8, cy + 7), (16, cy + 5), OUTLINE, 1)

    # Stone-and-moss shell.
    ellipse(draw, (cx - 29, cy - 23, cx + 31, cy + 17), DARK)
    ellipse(draw, (cx - 26, cy - 20, cx + 28, cy + 14), STONE)
    for plate in ((-18, -12), (0, -16), (16, -10), (-8, 0), (10, -2)):
        ellipse(draw, (cx + plate[0] - 7, cy + plate[1] - 5, cx + plate[0] + 7, cy + plate[1] + 6), MOSS)
        line(draw, (cx + plate[0] - 4, cy + plate[1] + 2), (cx + plate[0] + 4, cy + plate[1] - 1), MOSS_LIGHT)

    # Red canopy with irregular cream patches.
    draw.polygon(
        [(cx - 30, cy - 12), (cx - 20, cy - 29), (cx + 1, cy - 34), (cx + 22, cy - 28), (cx + 31, cy - 10), (cx + 18, cy - 16), (cx, cy - 12), (cx - 18, cy - 16)],
        fill=CAP,
        outline=OUTLINE,
    )
    for spot in ((-18, -22, 6), (-2, -27, 4), (13, -22, 5), (-9, -15, 3), (20, -15, 3)):
        ellipse(draw, (cx + spot[0] - spot[2], cy + spot[1] - spot[2] // 2, cx + spot[0] + spot[2], cy + spot[1] + spot[2] // 2), CREAM, OUTLINE)
    draw_small_mushroom(draw, cx - 20, cy - 24, 0.8)
    draw_small_mushroom(draw, cx + 1, cy - 31, 1.1)
    draw_small_mushroom(draw, cx + 20, cy - 23, 0.9)

    # Twin spore cannon bulbs on the back.
    for bulb_index, bulb_x in enumerate((cx - 16, cx + 8)):
        bulb_y = cy - 23 + (2 if bulb_index else 0)
        radius = 8 if bulb_index == 0 else 7
        ellipse(draw, (bulb_x - radius, bulb_y - radius, bulb_x + radius, bulb_y + radius), CREAM, OUTLINE)
        ellipse(draw, (bulb_x - radius + 2, bulb_y - radius + 2, bulb_x + radius - 2, bulb_y + radius - 2), STONE_LIGHT, OUTLINE)
        draw.ellipse((bulb_x - 3, bulb_y - 4, bulb_x + 3, bulb_y + 1), fill=SPORE, outline=OUTLINE)
        if state in ("attack", "skill"):
            pulse = 1 + int(math.sin(progress * math.pi) * 2)
            draw.ellipse((bulb_x - pulse, bulb_y - pulse - 2, bulb_x + pulse, bulb_y + pulse - 1), fill=SPORE_LIGHT, outline=OUTLINE)

    # Tail, moss drips and action effects.
    line(draw, (cx + 30, cy + 3), (cx + 38, cy + 9), DARK, 2)
    px(draw, cx + 39, cy + 10, MOSS_LIGHT)
    for drip in ((10, 8), (25, 12), (43, 10), (58, 7)):
        line(draw, (cx + drip[0], cy - 4), (cx + drip[0], cy + drip[1]), MOSS, 1)
        px(draw, cx + drip[0], cy + drip[1] + 1, MOSS_LIGHT)

    if state == "move":
        for dust in range(5):
            x = cx - 34 + dust * 4
            y = cy + 20 + (dust % 2)
            px(draw, x, y, MOSS_LIGHT if dust % 2 else SPORE_LIGHT)
    elif state == "attack":
        for shot in range(4):
            x = -6 - shot * 7 - progress * 4
            y = cy - 2 + shot
            draw.ellipse((x - 3, y - 3, x + 3, y + 3), fill=SPORE, outline=OUTLINE)
            px(draw, x - 1, y - 1, SPORE_GLOW)
    elif state == "skill":
        if progress < 0.55:
            # Spore pool charges and splashes beneath the boss.
            pool_width = 8 + progress * 24
            draw.ellipse((cx - pool_width, cy + 19, cx + pool_width, cy + 28), fill=SPORE, outline=SPORE_LIGHT)
            for splash in range(7):
                x = cx - pool_width + splash * pool_width * 2 / 6
                y = cy + 20 - int(math.sin(splash * 1.7 + phase * math.tau) * 3)
                px(draw, x, y, SPORE_GLOW if splash % 2 else SPORE_LIGHT)
        else:
            # Shell roll folds the legs and adds rotational motion lines.
            for roll_line in range(4):
                line(draw, (cx - 34, cy - 6 + roll_line * 6), (cx - 22, cy - 6 + roll_line * 6), SPORE_LIGHT)


def draw_gatekeeper(draw: ImageDraw.ImageDraw, phase: float, state: str, index: int, count: int) -> None:
    progress = index / max(1, count - 1) if count > 1 else 0.0
    breath = math.sin(phase * math.tau)
    if state == "idle":
        lean = round(breath)
        hammer_lift = 0.0
        shield_bob = round(breath)
    elif state == "move":
        lean = round(breath * 2)
        hammer_lift = 0.2 + breath * 0.1
        shield_bob = round(breath * 2)
    elif state == "attack":
        lean = 2 if progress > 0.55 else -2
        hammer_lift = -1.0 + progress * 1.9
        shield_bob = 0
    elif state == "skill":
        lean = round(math.sin(progress * math.pi) * 2)
        hammer_lift = 0.4
        shield_bob = round(math.sin(progress * math.tau) * 2)
    elif state == "hurt":
        lean = 3 if index % 2 else -3
        hammer_lift = 0.1
        shield_bob = 0
    elif state == "evolve":
        lean = 0
        hammer_lift = 0.8 * progress
        shield_bob = round(-progress * 2)
    else:
        lean = round(progress * 2)
        hammer_lift = -0.3 * progress
        shield_bob = 0

    cx = 36 + lean
    top = 8 + (1 if state in ("idle", "move") else 0)

    # Stubby rooted legs.
    for leg_x in (26, 46):
        draw.rectangle((leg_x - 8, 63, leg_x + 8, 80), fill=SKIN_DARK, outline=OUTLINE)
        draw.rectangle((leg_x - 7, 70, leg_x + 7, 76), fill=SKIN, outline=OUTLINE)
        for claw in range(3):
            draw.polygon([(leg_x - 6 + claw * 5, 76), (leg_x - 3 + claw * 5, 82), (leg_x + claw * 5, 76)], fill=CREAM, outline=OUTLINE)

    # Barrel shield held on the left.
    shield_x = 15 + (2 if state in ("attack", "skill") else 0)
    shield_y = 50 + shield_bob
    ellipse(draw, (shield_x - 14, shield_y - 15, shield_x + 14, shield_y + 17), WOOD_DARK)
    ellipse(draw, (shield_x - 11, shield_y - 12, shield_x + 11, shield_y + 14), WOOD)
    for band in (-7, 0, 7):
        line(draw, (shield_x - 11, shield_y + band), (shield_x + 11, shield_y + band), IRON, 2)
    draw.rectangle((shield_x - 4, shield_y - 5, shield_x + 4, shield_y + 5), fill=CREAM, outline=OUTLINE)
    draw.rectangle((shield_x - 2, shield_y - 3, shield_x + 2, shield_y + 1), fill=CAP, outline=OUTLINE)

    # Broad apron and body.
    draw.polygon([(cx - 17, 36), (cx + 17, 36), (cx + 19, 66), (cx - 19, 66)], fill=MOSS, outline=OUTLINE)
    draw.polygon([(cx - 11, 43), (cx + 11, 43), (cx + 13, 66), (cx - 13, 66)], fill=WOOD_DARK, outline=OUTLINE)
    draw.rectangle((cx - 16, 54, cx + 16, 60), fill=WOOD, outline=OUTLINE)
    draw.rectangle((cx - 3, 54, cx + 3, 60), fill=CREAM, outline=OUTLINE)
    for patch in ((cx - 11, 47), (cx + 8, 50), (cx, 62)):
        ellipse(draw, (patch[0] - 2, patch[1] - 2, patch[0] + 2, patch[1] + 2), MOSS_LIGHT)

    # Face hidden by a heavy beard, beneath a broad mushroom hat.
    draw.polygon(
        [(cx - 29, top + 14), (cx - 18, top - 4), (cx, top - 8), (cx + 18, top - 4), (cx + 29, top + 14), (cx + 12, top + 9), (cx, top + 12), (cx - 12, top + 9)],
        fill=CAP,
        outline=OUTLINE,
    )
    for spot in ((-18, 2, 5), (-4, -2, 4), (11, 2, 5), (0, 8, 3)):
        ellipse(draw, (cx + spot[0] - spot[2], top + spot[1] - spot[2] // 2, cx + spot[0] + spot[2], top + spot[1] + spot[2] // 2), CREAM, outline=OUTLINE)
    draw_small_mushroom(draw, cx - 16, top - 1, 0.8)
    draw_small_mushroom(draw, cx + 15, top - 1, 0.9)
    draw.rectangle((cx - 13, top + 12, cx + 13, top + 26), fill=SKIN, outline=OUTLINE)
    px(draw, cx - 5, top + 16, SPORE_GLOW)
    px(draw, cx + 5, top + 16, SPORE_GLOW)
    draw.polygon([(cx - 12, top + 22), (cx + 12, top + 22), (cx + 9, top + 38), (cx - 9, top + 38)], fill=CREAM, outline=OUTLINE)
    for strand in range(4):
        line(draw, (cx - 8 + strand * 5, top + 25), (cx - 7 + strand * 5, top + 36), MOSS_LIGHT)

    # Massive hammer held on the right.
    hammer_swing = hammer_lift * 12
    handle_top = (cx + 24, top + 6 + hammer_swing)
    handle_bottom = (cx + 15, 66 + hammer_swing * 0.4)
    line(draw, handle_bottom, handle_top, WOOD_DARK, 4)
    line(draw, handle_bottom, handle_top, WOOD_LIGHT, 2)
    draw.polygon(
        [(handle_top[0] - 11, handle_top[1] - 6), (handle_top[0] + 12, handle_top[1] - 9), (handle_top[0] + 12, handle_top[1] + 10), (handle_top[0] - 11, handle_top[1] + 7)],
        fill=STONE,
        outline=OUTLINE,
    )
    draw.polygon(
        [(handle_top[0] - 7, handle_top[1] - 2), (handle_top[0] + 8, handle_top[1] - 4), (handle_top[0] + 8, handle_top[1] + 6), (handle_top[0] - 7, handle_top[1] + 4)],
        fill=STONE_LIGHT,
        outline=OUTLINE,
    )
    for crack in range(3):
        line(draw, (handle_top[0] - 6 + crack * 6, handle_top[1] - 3), (handle_top[0] - 3 + crack * 6, handle_top[1] + 4), MOSS, 1)

    # Small mushrooms colonize the armour.
    draw_small_mushroom(draw, cx - 13, 39, 0.7)
    draw_small_mushroom(draw, cx + 14, 43, 0.8)
    draw_small_mushroom(draw, cx - 2, 58, 0.6)

    if state == "move":
        for dust in range(5):
            px(draw, cx - 28 + dust * 14, 82 + dust % 2, MOSS_LIGHT if dust % 2 else SPORE_LIGHT)
    elif state == "attack":
        impact_y = 72 + progress * 6
        impact_x = cx + 31
        for ray in range(7):
            angle = math.pi * (0.15 + ray / 6.0)
            x = impact_x + math.cos(angle) * (8 + progress * 12)
            y = impact_y + math.sin(angle) * (6 + progress * 8)
            px(draw, x, y, CREAM if ray % 2 else SPORE_LIGHT)
        line(draw, (impact_x - 12, impact_y + 4), (impact_x + 12, impact_y + 4), CREAM, 2)
    elif state == "skill":
        if progress < 0.5:
            # Barrel spill: a wooden cask tumbles and bursts into spores.
            barrel_x = cx + 24 - progress * 42
            barrel_y = 50 + math.sin(progress * math.pi) * 22
            draw.rectangle((barrel_x - 7, barrel_y - 9, barrel_x + 7, barrel_y + 9), fill=WOOD, outline=OUTLINE)
            for band in (-4, 0, 4):
                line(draw, (barrel_x - 7, barrel_y + band), (barrel_x + 7, barrel_y + band), IRON, 1)
            draw.ellipse((barrel_x - 4, barrel_y - 5, barrel_x + 4, barrel_y + 2), fill=SPORE, outline=OUTLINE)
        else:
            # Cap bulwark: a mushroom wall rises in front.
            barrier_progress = (progress - 0.5) * 2
            for cap_index in range(5):
                cap_x = cx - 28 + cap_index * 12
                cap_y = 68 - barrier_progress * 7
                draw.ellipse((cap_x - 8, cap_y - 8, cap_x + 8, cap_y + 2), fill=CAP, outline=OUTLINE)
                px(draw, cap_x - 3, cap_y - 5, CREAM)
                draw.rectangle((cap_x - 2, cap_y, cap_x + 2, cap_y + 5), fill=CREAM, outline=OUTLINE)
    elif state == "evolve":
        for mote in range(12):
            angle = math.tau * mote / 12 - progress * 1.5
            radius = 8 + progress * 18
            px(draw, cx + math.cos(angle) * radius, 42 + math.sin(angle) * radius * 0.55, SPORE_GLOW if progress > 0.5 else SPORE_LIGHT)


def frame_canvas(form_id: str, state: str, index: int, count: int) -> Image.Image:
    # A small phase offset keeps sine poses from collapsing into duplicate frames.
    phase = (index + 0.18) / max(1, count)
    logical = LOGICAL_SIZES[form_id]
    image, draw = new_canvas(logical)
    if form_id == "turtle":
        draw_turtle(draw, phase, state, index, count)
    else:
        draw_gatekeeper(draw, phase, state, index, count)

    if state == "idle":
        # Low drifting spores keep idle frames distinct at integer pixel scale.
        for mote in range(6):
            angle = math.tau * mote / 6 + phase * math.tau * 0.7
            radius = logical[0] * 0.22 + (mote % 3) * 3
            x = logical[0] * 0.5 + math.cos(angle) * radius
            y = logical[1] * 0.42 + math.sin(angle) * radius * 0.35
            px(draw, x, y, SPORE_LIGHT if mote % 2 else SPORE_GLOW)
    elif state == "evolve":
        progress = index / max(1, count - 1)
        for mote in range(16):
            angle = math.tau * mote / 16 + progress * 1.8
            radius = logical[0] * (0.12 + progress * 0.24) + (mote % 3) * 2
            x = logical[0] * 0.5 + math.cos(angle) * radius
            y = logical[1] * 0.48 + math.sin(angle) * radius * 0.52
            color = SPORE_GLOW if progress > 0.55 or mote % 3 == 0 else SPORE_LIGHT
            px(draw, x, y, color)
            if mote % 4 == index % 4:
                px(draw, x + 1, y - 1, CREAM)
    elif state == "move":
        # A travelling spore trail makes heavy movement readable frame to frame.
        for mote in range(7):
            trail = (index * 0.22 + mote / 7.0) % 1.0
            x = logical[0] * 0.72 - trail * logical[0] * 0.52
            y = logical[1] * (0.58 + mote * 0.06) + math.sin(trail * math.tau) * 2.0
            color = SPORE_LIGHT if mote % 3 else SPORE_GLOW
            px(draw, x, y, color)
            if mote % 2 == index % 2:
                px(draw, x - 1, y, MOSS_LIGHT)

    if state == "hurt":
        overlay = Image.new("RGBA", image.size, (255, 74, 88, 64))
        image = Image.alpha_composite(image, overlay)
    elif state == "death":
        progress = index / max(1, count - 1)
        alpha = image.getchannel("A").point(lambda value: int(value * max(0.10, 1.0 - progress * 0.78)))
        image.putalpha(alpha)

    return image


def upscale(image: Image.Image, target: tuple[int, int]) -> Image.Image:
    return image.resize(target, Image.Resampling.NEAREST)


def are_frames_equal(left: Image.Image, right: Image.Image) -> bool:
    return left.size == right.size and left.tobytes() == right.tobytes()


def generate(output: Path) -> None:
    output.mkdir(parents=True, exist_ok=True)
    previews = Path("tools/mushroom_guardian_previews")
    previews.mkdir(parents=True, exist_ok=True)
    (previews / ".gdignore").touch()

    for form_id, target in TARGET_SIZES.items():
        for state, count in FRAME_COUNTS.items():
            frames = [upscale(frame_canvas(form_id, state, index, count), target) for index in range(count)]
            if any(are_frames_equal(frames[i], frames[i + 1]) for i in range(len(frames) - 1)):
                raise RuntimeError(f"{form_id}/{state} has duplicate adjacent frames")
            for index, frame in enumerate(frames):
                frame.save(output / f"mushroom_guardian_{form_id}_{state}_{index:02d}.png")
            gif_frames = [frame.convert("P", colors=64) for frame in frames]
            gif_frames[0].save(
                previews / f"mushroom_guardian_{form_id}_{state}.gif",
                save_all=True,
                append_images=gif_frames[1:],
                duration=int(1000 / FRAME_FPS[state]),
                loop=0,
                disposal=2,
                transparency=0,
            )

    cell_width = max(size[0] for size in TARGET_SIZES.values())
    cell_height = max(size[1] for size in TARGET_SIZES.values())
    sheet = Image.new("RGBA", (cell_width * len(FRAME_COUNTS), cell_height * 2), (18, 21, 27, 255))
    for row, form_id in enumerate(("turtle", "gatekeeper")):
        for column, state in enumerate(FRAME_COUNTS):
            frame = Image.open(output / f"mushroom_guardian_{form_id}_{state}_00.png")
            x = column * cell_width + (cell_width - frame.width) // 2
            y = row * cell_height + (cell_height - frame.height) // 2
            sheet.alpha_composite(frame, (x, y))
    sheet.save(previews / "mushroom_guardian_contact_sheet.png")
    print("generated hand-pixelled dynamic mushroom guardian")


if __name__ == "__main__":
    generate(Path("assets/sprites/monsters/mushroom_guardian"))
