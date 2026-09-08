from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


LOGICAL_SIZE = (64, 48)
PREVIEW_SCALE = 5

OUTLINE = (28, 27, 29, 255)
OUTLINE_SOFT = (54, 49, 47, 255)
HAIR = (30, 29, 35, 255)
HAIR_MID = (48, 46, 54, 255)
HAIR_LIGHT = (72, 68, 76, 255)
SKIN_SHADOW = (196, 142, 91, 255)
SKIN = (235, 183, 119, 255)
SKIN_LIGHT = (249, 210, 151, 255)
SKIN_HIGHLIGHT = (255, 229, 177, 255)
EYE = (24, 25, 29, 255)
EYE_SHINE = (255, 250, 228, 255)
SHIRT = (239, 240, 225, 255)
SHIRT_LIGHT = (255, 255, 242, 255)
SHIRT_SHADOW = (194, 202, 190, 255)
SHORTS = (39, 41, 43, 255)
SHORTS_LIGHT = (65, 65, 66, 255)
STRAP = (29, 30, 32, 255)
STRAP_LIGHT = (61, 62, 63, 255)
SHOE = (31, 33, 37, 255)
SHOE_LIGHT = (68, 71, 76, 255)
SOLE = (244, 243, 226, 255)
SOLE_SHADOW = (184, 188, 181, 255)
GROUND = (47, 48, 45, 90)


def rect(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], color: tuple) -> None:
    draw.rectangle(box, fill=color)


def pixel(draw: ImageDraw.ImageDraw, x: int, y: int, color: tuple) -> None:
    draw.point((x, y), fill=color)


def draw_boy() -> Image.Image:
    image = Image.new("RGBA", LOGICAL_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    # Hair is built as an uneven silhouette so the top reads as loose hair.
    draw.polygon(
        [(23, 12), (22, 10), (24, 8), (26, 8), (26, 6), (29, 6),
         (29, 4), (32, 4), (32, 2), (35, 2), (36, 4), (40, 4),
         (40, 6), (43, 6), (43, 8), (45, 9), (45, 12), (47, 13),
         (46, 17), (44, 17), (44, 20), (41, 20), (40, 17),
         (38, 19), (35, 17), (33, 20), (30, 17), (28, 20),
         (25, 18), (23, 20), (21, 18), (22, 15), (20, 14)],
        fill=OUTLINE,
    )
    rect(draw, (24, 9, 43, 14), HAIR)
    rect(draw, (27, 7, 40, 9), HAIR_MID)
    rect(draw, (30, 5, 34, 7), HAIR_MID)
    rect(draw, (38, 7, 42, 10), HAIR_LIGHT)
    rect(draw, (23, 11, 27, 16), HAIR_MID)
    rect(draw, (41, 11, 44, 16), HAIR_MID)
    pixel(draw, 28, 6, HAIR_LIGHT)
    pixel(draw, 35, 4, HAIR_LIGHT)

    # Round face, ears, and warm pixel shading.
    draw.polygon(
        [(25, 13), (41, 13), (43, 15), (43, 20), (41, 22),
         (38, 24), (29, 24), (25, 22), (23, 19), (23, 15)],
        fill=OUTLINE,
    )
    rect(draw, (23, 16, 25, 19), SKIN_SHADOW)
    rect(draw, (41, 16, 43, 19), SKIN_SHADOW)
    draw.polygon(
        [(26, 13), (40, 13), (41, 15), (41, 20), (39, 22),
         (36, 23), (30, 23), (26, 21), (25, 19), (25, 15)],
        fill=SKIN,
    )
    rect(draw, (27, 14, 39, 15), SKIN_LIGHT)
    rect(draw, (26, 18, 40, 20), SKIN_LIGHT)
    rect(draw, (28, 21, 39, 22), SKIN_SHADOW)
    rect(draw, (27, 14, 30, 14), SKIN_HIGHLIGHT)

    # Jagged fringe sits over the forehead, with no straight hat-like brim.
    rect(draw, (24, 12, 28, 15), HAIR)
    rect(draw, (29, 12, 31, 14), HAIR)
    rect(draw, (33, 12, 35, 15), HAIR)
    rect(draw, (37, 12, 40, 14), HAIR)
    pixel(draw, 28, 12, HAIR_MID)
    pixel(draw, 36, 12, HAIR_LIGHT)

    # Large dark eyes, tiny highlights, and a quiet neutral expression.
    rect(draw, (27, 15, 32, 19), EYE)
    rect(draw, (35, 15, 40, 19), EYE)
    rect(draw, (28, 15, 29, 16), EYE_SHINE)
    rect(draw, (36, 15, 37, 16), EYE_SHINE)
    pixel(draw, 32, 17, SKIN_SHADOW)
    rect(draw, (31, 20, 35, 20), OUTLINE_SOFT)
    rect(draw, (32, 21, 34, 21), SKIN_SHADOW)

    # Small neck and a white T-shirt with a clean, broad silhouette.
    rect(draw, (30, 22, 36, 25), OUTLINE)
    rect(draw, (31, 22, 35, 25), SKIN)
    draw.polygon(
        [(27, 23), (31, 24), (35, 24), (39, 23), (42, 25),
         (43, 31), (41, 34), (25, 34), (23, 31), (24, 25)],
        fill=OUTLINE,
    )
    draw.polygon(
        [(28, 24), (31, 25), (35, 25), (38, 24), (40, 25),
         (41, 31), (40, 33), (26, 33), (25, 30), (26, 25)],
        fill=SHIRT,
    )
    rect(draw, (28, 24, 30, 25), SHIRT_LIGHT)
    rect(draw, (36, 24, 38, 25), SHIRT_LIGHT)
    rect(draw, (26, 29, 27, 32), SHIRT_SHADOW)
    rect(draw, (39, 28, 41, 32), SHIRT_SHADOW)
    rect(draw, (30, 25, 36, 26), SHIRT_LIGHT)

    # One diagonal sling bag strap is the main identifying clothing detail.
    draw.line((27, 24, 39, 34), fill=STRAP, width=2)
    pixel(draw, 29, 26, STRAP_LIGHT)
    pixel(draw, 34, 30, STRAP_LIGHT)
    rect(draw, (38, 32, 42, 36), OUTLINE)
    rect(draw, (39, 33, 41, 35), STRAP)
    pixel(draw, 40, 33, STRAP_LIGHT)
    pixel(draw, 31, 26, (81, 139, 156, 255))

    # Short sleeves and hands remain separate from the shirt body.
    rect(draw, (21, 25, 25, 32), OUTLINE)
    rect(draw, (22, 26, 25, 30), SHIRT)
    rect(draw, (22, 30, 26, 33), SKIN_SHADOW)
    rect(draw, (23, 30, 25, 32), SKIN_LIGHT)
    rect(draw, (41, 25, 45, 32), OUTLINE)
    rect(draw, (41, 26, 44, 30), SHIRT)
    rect(draw, (40, 30, 44, 33), SKIN_SHADOW)
    rect(draw, (41, 30, 43, 32), SKIN_LIGHT)
    pixel(draw, 22, 26, SHIRT_LIGHT)
    pixel(draw, 43, 26, SHIRT_LIGHT)

    # Dark shorts with a visible center split.
    rect(draw, (25, 33, 41, 39), OUTLINE)
    rect(draw, (26, 34, 32, 38), SHORTS)
    rect(draw, (34, 34, 40, 38), SHORTS)
    rect(draw, (27, 34, 31, 35), SHORTS_LIGHT)
    rect(draw, (35, 34, 39, 35), SHORTS_LIGHT)
    rect(draw, (32, 35, 33, 38), OUTLINE_SOFT)

    # Bare lower legs and chunky black sneakers with white soles.
    rect(draw, (27, 38, 32, 42), OUTLINE)
    rect(draw, (34, 38, 39, 42), OUTLINE)
    rect(draw, (28, 38, 30, 41), SKIN)
    rect(draw, (35, 38, 37, 41), SKIN)
    pixel(draw, 28, 40, SKIN_LIGHT)
    pixel(draw, 35, 40, SKIN_LIGHT)
    rect(draw, (23, 41, 32, 45), OUTLINE)
    rect(draw, (34, 41, 43, 45), OUTLINE)
    rect(draw, (24, 41, 30, 43), SHOE)
    rect(draw, (35, 41, 41, 43), SHOE)
    rect(draw, (23, 43, 32, 44), SOLE)
    rect(draw, (34, 43, 43, 44), SOLE)
    rect(draw, (25, 44, 31, 45), SHOE_LIGHT)
    rect(draw, (36, 44, 42, 45), SHOE_LIGHT)
    pixel(draw, 28, 42, SOLE_SHADOW)
    pixel(draw, 38, 42, SOLE_SHADOW)

    return image


def main() -> None:
    preview_dir = Path(__file__).parent / "player_previews"
    preview_dir.mkdir(parents=True, exist_ok=True)
    frame = draw_boy()
    frame.save(preview_dir / "player_boy_idle_00.png")

    enlarged = frame.resize(
        (LOGICAL_SIZE[0] * PREVIEW_SCALE, LOGICAL_SIZE[1] * PREVIEW_SCALE),
        Image.Resampling.NEAREST,
    )
    background = Image.new("RGBA", enlarged.size, (222, 218, 204, 255))
    background.alpha_composite(enlarged)
    preview_draw = ImageDraw.Draw(background)
    preview_draw.ellipse((100, 220, 220, 233), fill=GROUND)
    background.save(preview_dir / "player_boy_idle_preview.png")
    print(f"generated {preview_dir / 'player_boy_idle_00.png'}")
    print(f"generated {preview_dir / 'player_boy_idle_preview.png'}")


if __name__ == "__main__":
    main()
