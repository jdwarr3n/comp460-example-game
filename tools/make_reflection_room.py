# Draws cabinet/reflection_room.png, the room that shiny things reflect. Players never see it
# directly. Run from the repo root: python tools/make_reflection_room.py
#
# Chrome and gold are only as interesting as what they mirror, so this is neutral white with
# contrast: a bright ceiling with light strips, a dark band at eye level, and a gray floor.
import numpy as np
from PIL import Image

WIDTH, HEIGHT = 2048, 1024
CEILING = 0.8
HORIZON = 0.18
FLOOR = 0.6


def main() -> None:
    v = np.linspace(0.0, 1.0, HEIGHT)[:, None]
    u = np.linspace(0.0, 1.0, WIDTH)[None, :]
    room = np.where(v < 0.5, CEILING, FLOOR) * np.ones((HEIGHT, WIDTH))
    band = np.exp(-(((v - 0.5) / 0.06) ** 2))
    room = room * (1.0 - band) + HORIZON * band
    for row, half_width in ((0.1, 0.012), (0.2, 0.014), (0.32, 0.012)):
        strip = (np.abs(v - row) < half_width) & (np.sin(2.0 * np.pi * 6.0 * u) > -0.35)
        room = np.where(strip, 1.0, room)
    Image.fromarray((room * 255).astype(np.uint8)).convert("RGB").save("cabinet/reflection_room.png")


if __name__ == "__main__":
    main()
