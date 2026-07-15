"""Crop run frames: kill filename labels (incl. gray) and pad under feet."""
from pathlib import Path

from PIL import Image

SRC = Path(r"C:\Users\islam\Desktop\player")
DST = Path(r"C:\Users\islam\Desktop\mine\flutter_application_1\assets\player")


def chroma(r: int, g: int, b: int) -> int:
    return max(r, g, b) - min(r, g, b)


def avg(r: int, g: int, b: int) -> float:
    return (r + g + b) / 3.0


def is_bg(r: int, g: int, b: int, a: int) -> bool:
    if a < 20:
        return True
    if max(r, g, b) < 28:
        return True
    return avg(r, g, b) >= 220 and chroma(r, g, b) <= 30


def is_labelish(r: int, g: int, b: int, a: int) -> bool:
    """Filename text: light/mid gray, almost no color."""
    if a < 20:
        return False
    return avg(r, g, b) >= 100 and chroma(r, g, b) <= 40


def is_colored_body(r: int, g: int, b: int, a: int) -> bool:
    """Boots/clothes with real color — not gray labels."""
    if a < 35 or is_bg(r, g, b, a):
        return False
    return chroma(r, g, b) >= 22 and avg(r, g, b) < 245


def clean_one(path: Path) -> Image.Image:
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if is_bg(r, g, b, a):
                px[x, y] = (0, 0, 0, 0)

    # Wipe label band: gray/white text sits under the character.
    y0 = int(h * 0.72)
    for y in range(y0, h):
        # Wide low-chroma spans = text rows
        label_xs = []
        for x in range(w):
            r, g, b, a = px[x, y]
            if is_labelish(r, g, b, a):
                label_xs.append(x)
        if len(label_xs) >= 10:
            for x in label_xs:
                px[x, y] = (0, 0, 0, 0)
        # Hard strip at the very bottom
        if y >= int(h * 0.88):
            for x in range(w):
                r, g, b, a = px[x, y]
                if a > 0 and chroma(r, g, b) <= 45:
                    px[x, y] = (0, 0, 0, 0)

    # Feet = last row with colored body (boots), keep soft shadow just below.
    feet = 0
    for y in range(h):
        body = 0
        for x in range(w):
            r, g, b, a = px[x, y]
            if is_colored_body(r, g, b, a):
                body += 1
        if body >= 6:
            feet = y

    # Allow a few px of soft gray shadow under the soles.
    shadow_end = min(h - 1, feet + 6)
    for y in range(feet + 1, shadow_end + 1):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 20:
                continue
            # Keep only soft gray shadow near center, wipe text leftovers
            if chroma(r, g, b) <= 40 and 40 <= avg(r, g, b) <= 170:
                continue
            px[x, y] = (0, 0, 0, 0)

    for y in range(shadow_end + 1, h):
        for x in range(w):
            px[x, y] = (0, 0, 0, 0)

    crop_bottom = shadow_end
    minx, miny, maxx, maxy = w, h, -1, -1
    for y in range(0, crop_bottom + 1):
        for x in range(w):
            if px[x, y][3] > 28:
                if x < minx:
                    minx = x
                if x > maxx:
                    maxx = x
                if y < miny:
                    miny = y
                if y > maxy:
                    maxy = y
    if maxx < minx:
        raise RuntimeError(f"empty after clean: {path.name}")

    minx = max(0, minx - 2)
    miny = max(0, miny - 2)
    maxx = min(w - 1, maxx + 2)
    maxy = min(h - 1, maxy + 2)
    return im.crop((minx, miny, maxx + 1, maxy + 1))


def main() -> None:
    DST.mkdir(parents=True, exist_ok=True)
    for i in range(1, 11):
        name = f"run_{i:02d}.png"
        cropped = clean_one(SRC / name)
        cropped.save(DST / name, optimize=True)
        print(f"{name}: {cropped.size[0]}x{cropped.size[1]}")
    print("done")


if __name__ == "__main__":
    main()
