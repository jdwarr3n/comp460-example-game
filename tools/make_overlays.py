# Draws the start and end overlays: overlay/start_overlay.png and overlay/end_overlay.png.
# Run from the repo root: python tools/make_overlays.py
# The final score and the difficulty line aren't drawn here: the game adds them, because they
# change.
from PIL import Image, ImageDraw, ImageFont

WIDTH, HEIGHT = 1600, 1400
CORNER = 60
TITLE_FONT = "C:/Windows/Fonts/impact.ttf"
BOLD_FONT = "C:/Windows/Fonts/segoeuib.ttf"
TEXT_FONT = "C:/Windows/Fonts/segoeui.ttf"
PANEL = (12, 10, 20, 205)
GOLD = (255, 205, 70, 255)
WHITE = (240, 240, 245, 255)
GOAL = "Grab as many prizes as you can in 60 seconds."
CONTROLS = [
    ("Mouse", "Aim the claw"),
    ("Hold left button", "Lower the claw"),
    ("Release", "Close and lift"),
    ("Arrows or WASD", "Orbit the camera"),
    ("Scroll wheel", "Zoom in and out"),
    ("Q", "Auto-aim, once per round"),
]


def spaced_text(draw, y, text, font, fill, tracking):
    advances = [font.getlength(c) for c in text]
    x = (WIDTH - sum(advances) - tracking * (len(text) - 1)) / 2
    for char, advance in zip(text, advances):
        draw.text((x, y), char, font=font, fill=fill, anchor="lm")
        x += advance + tracking


def panel(bottom_line):
    image = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    box = (8, 8, WIDTH - 9, HEIGHT - 9)
    draw.rounded_rectangle(box, CORNER, fill=PANEL, outline=GOLD, width=8)
    spaced_text(draw, 190, "CLAW 460", ImageFont.truetype(TITLE_FONT, 230), GOLD, 26)
    font = ImageFont.truetype(BOLD_FONT, 110)
    draw.text((WIDTH / 2, 1240), bottom_line, font=font, fill=WHITE, anchor="mm")
    return image, draw


def start_overlay():
    image, draw = panel("Click to start")
    goal_font = ImageFont.truetype(TEXT_FONT, 60)
    draw.text((WIDTH / 2, 355), GOAL, font=goal_font, fill=WHITE, anchor="mm")
    key_font = ImageFont.truetype(BOLD_FONT, 62)
    text_font = ImageFont.truetype(TEXT_FONT, 62)
    for row, (key, action) in enumerate(CONTROLS):
        y = 480 + 93 * row
        draw.text((740, y), key, font=key_font, fill=GOLD, anchor="rm")
        draw.text((800, y), action, font=text_font, fill=WHITE, anchor="lm")
    image.save("overlay/start_overlay.png")


def end_overlay():
    image, _ = panel("Click to play again")
    image.save("overlay/end_overlay.png")


if __name__ == "__main__":
    start_overlay()
    end_overlay()
