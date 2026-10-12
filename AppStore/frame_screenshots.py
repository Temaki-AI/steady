"""Frame raw simulator screenshots for the App Store (6.9" iPhone, 1320x2868).

Usage: python3 AppStore/frame_screenshots.py <raw_dir> <out_dir>
Raw captures come from `xcrun simctl io <device> screenshot` on an iPhone 17 Pro Max.
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1320, 2868
SHOTS = [  # raw file, headline, dark background
    ("1-today.png", "Build habits\nthat stick", False),
    ("2-progress.png", "See how far\nyou've come", False),
    ("3-detail.png", "Streaks that keep\nyou going", False),
    ("4-schedule.png", "Schedules that fit\nreal life", False),
    ("5-widget.png", "Check off from your\nHome Screen", False),
    ("6-dark.png", "Easy on the eyes,\nday and night", True),
]
LIGHT = ((232, 241, 234), (247, 245, 238), (36, 56, 44))   # top, bottom, text
DARK = ((30, 42, 35), (12, 16, 14), (236, 244, 238))


def font(size):
    try:
        f = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", size)
        f.set_variation_by_name("Bold")
        return f
    except Exception:
        return ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", size, index=1)


def gradient(top, bottom):
    img = Image.new("RGB", (W, H), top)
    px = ImageDraw.Draw(img)
    for y in range(H):
        t = y / (H - 1)
        px.line([(0, y), (W, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)))
    return img


def frame(raw_path, headline, dark):
    top, bottom, ink = DARK if dark else LIGHT
    canvas = gradient(top, bottom)
    draw = ImageDraw.Draw(canvas)

    title_font = font(112)
    draw.multiline_text((W // 2, 300), headline, font=title_font, fill=ink,
                        anchor="mm", align="center", spacing=18)

    shot = Image.open(raw_path).convert("RGB")
    sw = int(W * 0.80)
    sh = int(shot.height * sw / shot.width)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    x, y = (W - sw) // 2, 540

    radius = 96
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw, sh), radius, fill=255)

    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((x, y + 24, x + sw, y + sh + 24), radius,
                                             fill=(0, 0, 0, 110 if dark else 60))
    shadow = shadow.filter(ImageFilter.GaussianBlur(40))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow)

    border = Image.new("RGBA", (sw + 12, sh + 12), (0, 0, 0, 0))
    ImageDraw.Draw(border).rounded_rectangle((0, 0, sw + 11, sh + 11), radius + 6,
                                             fill=(60, 70, 64, 255) if dark else (255, 255, 255, 255))
    canvas.alpha_composite(border, (x - 6, y - 6))
    canvas.paste(shot, (x, y), mask)
    return canvas.convert("RGB")


raw_dir, out_dir = Path(sys.argv[1]), Path(sys.argv[2])
out_dir.mkdir(parents=True, exist_ok=True)
for i, (name, headline, dark) in enumerate(SHOTS, 1):
    out = out_dir / f"{i:02d}-{name.split('-', 1)[1]}"
    frame(raw_dir / name, headline, dark).save(out, optimize=True)
    print(out, Image.open(out).size)
