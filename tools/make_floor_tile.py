# Draws one slate floor tile: cabinet/floor_tile.png and cabinet/floor_tile_normal.png.
# Run from the repo root: python tools/make_floor_tile.py
# The room floor repeats this tile, so the grout sits on all four edges.
import numpy as np
from PIL import Image, ImageFilter

SIZE = 512
GROUT = 7  # Grout width on each edge, in pixels.
RELIEF = 5.0  # How deep the grout looks.
TILE_COLOR = np.array((62, 72, 88))  # Dark slate, so the pale claw cable shows against it.
GROUT_COLOR = np.array((140, 146, 156))


def main() -> None:
    tile = np.zeros((SIZE, SIZE), dtype=np.uint8)
    tile[GROUT:-GROUT, GROUT:-GROUT] = 255
    color = np.where(tile[..., None] > 0, TILE_COLOR, GROUT_COLOR).astype(np.uint8)
    Image.fromarray(color).save("cabinet/floor_tile.png")
    soft = Image.fromarray(tile).filter(ImageFilter.GaussianBlur(3))
    height = np.asarray(soft, dtype=np.float32) / 255.0
    dy, dx = np.gradient(height)
    # Godot wants green pointing up the image, and rows run down it.
    normal = np.stack([-dx * RELIEF, dy * RELIEF, np.ones_like(height)], axis=-1)
    normal /= np.linalg.norm(normal, axis=-1, keepdims=True)
    Image.fromarray(((normal * 0.5 + 0.5) * 255).astype(np.uint8)).save("cabinet/floor_tile_normal.png")


if __name__ == "__main__":
    main()
