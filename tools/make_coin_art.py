# Draws the gold coin's textures: prizes/coin_shade.png and prizes/coin_normal.png.
# Run from the repo root: python tools/make_coin_art.py
#
# One texture covers the whole coin, laid out the way Godot's CylinderMesh expects: the edge
# across the top half, and the two faces side by side in the bottom half.
#
# The shade texture is gray because it multiplies the material's color. That color stays in
# the material, where the prize value table reads it.
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

FACE = 1024  # Width of one face in pixels.
FONT = "C:/Windows/Fonts/impact.ttf"
RELIEF = 26.0  # How steep the raised parts look.
REEDS = 150  # Ridges around the coin's edge.


def text_mask() -> np.ndarray:
    image = Image.new("L", (FACE, FACE), 0)
    draw = ImageDraw.Draw(image)
    draw.text((FACE / 2, FACE * 0.34), "COMP", font=ImageFont.truetype(FONT, 250), fill=255, anchor="mm")
    draw.text((FACE / 2, FACE * 0.64), "460", font=ImageFont.truetype(FONT, 330), fill=255, anchor="mm")
    return np.asarray(image, dtype=np.float32) / 255.0


def bead_mask() -> np.ndarray:
    image = Image.new("L", (FACE, FACE), 0)
    draw = ImageDraw.Draw(image)
    for i in range(56):
        angle = 2.0 * np.pi * i / 56
        x = FACE / 2 + 0.415 * FACE * np.cos(angle)
        y = FACE / 2 + 0.415 * FACE * np.sin(angle)
        draw.ellipse((x - 11, y - 11, x + 11, y + 11), fill=255)
    return np.asarray(image, dtype=np.float32) / 255.0


def smooth(mask: np.ndarray, radius: float) -> np.ndarray:
    image = Image.fromarray((mask * 255).astype(np.uint8))
    return np.asarray(image.filter(ImageFilter.GaussianBlur(radius)), dtype=np.float32) / 255.0


def to_normal(height: np.ndarray) -> np.ndarray:
    dy, dx = np.gradient(height)
    # Godot wants green pointing up the image, and rows run down it.
    normal = np.stack([-dx * RELIEF, dy * RELIEF, np.ones_like(height)], axis=-1)
    normal /= np.linalg.norm(normal, axis=-1, keepdims=True)
    return normal * 0.5 + 0.5


def make_face() -> tuple[np.ndarray, np.ndarray]:
    rows, cols = np.mgrid[0:FACE, 0:FACE]
    radius = np.hypot(cols - FACE / 2 + 0.5, rows - FACE / 2 + 0.5) / (FACE / 2)
    rim = (radius > 0.9).astype(np.float32)
    text = text_mask()
    beads = bead_mask()
    raised = np.maximum.reduce([rim, text, beads])
    height = smooth(rim, 5) + 0.8 * smooth(text, 4) + 0.5 * smooth(beads, 3)
    # The field between the raised parts is darker, with a little extra shadow beside them,
    # so the lettering still reads when the coin isn't catching the light.
    shadow = smooth(raised, 14)
    shade = 0.62 + 0.38 * smooth(raised, 2) - 0.12 * shadow * (1.0 - raised)
    return np.clip(shade, 0.0, 1.0), to_normal(height)


def make_edge() -> tuple[np.ndarray, np.ndarray]:
    columns = np.arange(2 * FACE, dtype=np.float32)
    ridges = np.sin(2.0 * np.pi * REEDS * columns / (2 * FACE))
    height = np.tile(0.5 + 0.5 * ridges, (FACE, 1))
    shade = np.tile(0.86 + 0.14 * ridges, (FACE, 1))
    return shade, to_normal(height * 2.0)


def main() -> None:
    edge_shade, edge_normal = make_edge()
    face_shade, face_normal = make_face()
    shade = np.vstack([edge_shade, np.hstack([face_shade, face_shade])])
    normal = np.vstack([edge_normal, np.hstack([face_normal, face_normal])])
    Image.fromarray((shade * 255).astype(np.uint8)).convert("RGB").save("prizes/coin_shade.png")
    Image.fromarray((normal * 255).astype(np.uint8)).save("prizes/coin_normal.png")


if __name__ == "__main__":
    main()
