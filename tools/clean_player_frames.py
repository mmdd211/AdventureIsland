from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image


SOURCE_DIR = Path(__file__).resolve().parents[1] / "data" / "player"
OUTPUT_DIR = SOURCE_DIR / "cleaned"


def is_magenta(red: int, green: int, blue: int) -> bool:
    # Generated sheets use magenta as the chroma key. Include its antialiased
    # edge colors, while leaving the character's peach skin and dark purple
    # hair intact.
    return (
        red >= 100
        and blue >= 85
        and green <= 235
        and red - green >= 15
        and blue - green >= 15
    )


def is_background(red: int, green: int, blue: int) -> bool:
    near_white = red > 235 and green > 235 and blue > 235
    near_black = red < 28 and green < 28 and blue < 28
    return near_white or near_black or is_magenta(red, green, blue)


def clean_image(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    visited = [[False for _ in range(width)] for _ in range(height)]
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if x < 0 or x >= width or y < 0 or y >= height or visited[y][x]:
            continue
        visited[y][x] = True
        red, green, blue, alpha = pixels[x, y]
        if alpha == 0 or is_background(red, green, blue):
            pixels[x, y] = (0, 0, 0, 0)
            queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))

    # Remove detached chroma-key islands as well. Some generated frames have a
    # transparent moat around an inset magenta rectangle, so edge flood-fill
    # alone cannot reach every key-colored pixel.
    for y in range(height):
        for x in range(width):
            red, green, blue, alpha = pixels[x, y]
            if alpha > 0 and is_magenta(red, green, blue):
                pixels[x, y] = (0, 0, 0, 0)

    return rgba


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    sources = list(SOURCE_DIR.glob("*-frame-*.png"))
    sources.extend(SOURCE_DIR.glob("frame-*.png"))
    for source in sorted(sources):
        cleaned = clean_image(Image.open(source))
        cleaned.save(OUTPUT_DIR / source.name)
        print(f"cleaned {source.name}")


if __name__ == "__main__":
    main()
