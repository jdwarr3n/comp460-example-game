# Draws the marquee text: cabinet/marquee_logo.png.
# Run from the repo root: python tools/make_marquee_art.py
# Bright letters on black. It's used only as a glow map, so black stays dark. The picture
# repeats sideways as it scrolls, so nothing may touch its edges.
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

WIDTH, HEIGHT = 4096, 300
FONT = "C:/Windows/Fonts/impact.ttf"
TEXT = "CLAW 460"
FONT_SIZE = 240
TRACKING = 60  # Extra pixels between letters.
LETTER_COLOR = np.array((255.0, 214.0, 70.0))
HALO_COLOR = np.array((255.0, 60.0, 30.0))


def letters() -> Image.Image:
    font = ImageFont.truetype(FONT, FONT_SIZE)
    advances = [font.getlength(c) for c in TEXT]
    x = (WIDTH - sum(advances) - TRACKING * (len(TEXT) - 1)) / 2
    image = Image.new("L", (WIDTH, HEIGHT), 0)
    draw = ImageDraw.Draw(image)
    for char, advance in zip(TEXT, advances):
        draw.text((x, HEIGHT / 2), char, font=font, fill=255, anchor="lm")
        x += advance + TRACKING
    return image


def main() -> None:
    mask = letters()
    as_array = lambda image: np.asarray(image, dtype=np.float32)[..., None] / 255.0
    halo = as_array(mask.filter(ImageFilter.GaussianBlur(10)))
    solid = as_array(mask)
    picture = HALO_COLOR * halo * 0.35
    picture = picture * (1.0 - solid) + LETTER_COLOR * solid
    Image.fromarray(picture.astype(np.uint8)).save("cabinet/marquee_logo.png")


if __name__ == "__main__":
    main()
