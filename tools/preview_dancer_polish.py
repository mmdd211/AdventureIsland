# Build side-by-side polish comparison for dancer idle peak frame.
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "sprites" / "monsters" / "pollen_queen" / "pollen_queen_dancer_idle_03.png"
OUT = ROOT / "data" / "monsters" / "raw" / "dancer_polish_compare.png"


def quantize_rgba(img: Image.Image, colors: int) -> Image.Image:
    rgba = img.convert("RGBA")
    a = rgba.getchannel("A")
    q = rgba.convert("RGB").quantize(colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    out = q.convert("RGBA")
    out.putalpha(a)
    return out


def pixelate_content(img: Image.Image, block: int) -> Image.Image:
    if block <= 1:
        return img
    rgba = img.convert("RGBA")
    a = rgba.getchannel("A")
    rgb = rgba.convert("RGB")
    w, h = rgb.size
    sw, sh = max(1, w // block), max(1, h // block)
    big = rgb.resize((sw, sh), Image.Resampling.BOX).resize((w, h), Image.Resampling.NEAREST)
    a_big = a.resize((sw, sh), Image.Resampling.BOX).resize((w, h), Image.Resampling.NEAREST)
    ap = a_big.load()
    for y in range(h):
        for x in range(w):
            ap[x, y] = 255 if ap[x, y] >= 128 else 0
    out = big.convert("RGBA")
    out.putalpha(a_big)
    return out


def game_scale(img: Image.Image, s: float = 0.88) -> Image.Image:
    w = int(round(img.width * s))
    h = int(round(img.height * s))
    return img.resize((w, h), Image.Resampling.NEAREST)


def ncolors(img: Image.Image) -> int:
    px = img.convert("RGBA").load()
    s = set()
    for y in range(img.height):
        for x in range(img.width):
            if px[x, y][3] > 10:
                s.add(px[x, y][:3])
    return len(s)


def main() -> None:
    src = Image.open(SRC).convert("RGBA")
    variants = [
        ("current", src),
        ("q64", quantize_rgba(src, 64)),
        ("b2_q48", quantize_rgba(pixelate_content(src, 2), 48)),
        ("b2_q32", quantize_rgba(pixelate_content(src, 2), 32)),
        ("b3_q48", quantize_rgba(pixelate_content(src, 3), 48)),
    ]
    # top row: full 224 variants; bottom row: game-scale 0.88 NEAREST
    cell = 224
    pad = 16
    top_h = cell
    bot_h = int(round(cell * 0.88))
    W = pad + len(variants) * (cell + pad)
    H = pad + top_h + 24 + bot_h + pad
    sheet = Image.new("RGBA", (W, H), (28, 24, 32, 255))

    # dark checker for alpha readability
    px = sheet.load()
    for y in range(H):
        for x in range(W):
            if ((x // 8) + (y // 8)) % 2 == 0:
                if px[x, y][3] == 255:
                    px[x, y] = (36, 32, 40, 255)

    labels = []
    for i, (name, im) in enumerate(variants):
        x0 = pad + i * (cell + pad)
        sheet.paste(im, (x0, pad), im)
        gs = game_scale(im, 0.88)
        gx = x0 + (cell - gs.width) // 2
        gy = pad + top_h + 24
        sheet.paste(gs, (gx, gy), gs)
        labels.append(f"{name} c={ncolors(im)}")

    # draw labels as tiny bars (no font dependency) — write a sidecar txt
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    (OUT.parent / "dancer_polish_compare.txt").write_text("\n".join(labels), encoding="utf-8")
    print("wrote", OUT)
    for line in labels:
        print(line)


if __name__ == "__main__":
    main()
