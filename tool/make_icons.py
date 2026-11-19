#!/usr/bin/env python3
"""Generates the launcher icons and Play Store graphics (original design).

  python3 tool/make_icons.py            # needs Pillow and a Japanese font

Design: white "あ" with a check-mark badge on brand blue (#2E6DB4).
Outputs:
  android/app/src/main/res/mipmap-*/ic_launcher.png          (legacy icon)
  android/app/src/main/res/mipmap-*/ic_launcher_foreground.png (adaptive)
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
  android/app/src/main/res/values/ic_launcher_background.xml
  store/icon-512.png, store/feature-graphic.png
"""
import os

from PIL import Image, ImageDraw, ImageFont

JP_FONT = os.environ.get("JP_FONT", "/usr/share/fonts/opentype/ipafont-gothic/ipag.ttf")
LATIN_FONT = os.environ.get("LATIN_FONT", "/usr/share/fonts/opentype/inter/InterDisplay-Bold.otf")
BLUE = (46, 109, 180)
DARK = (28, 72, 125)
GOLD = (247, 185, 40)
WHITE = (255, 255, 255)
RES = "android/app/src/main/res"
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def glyph(size, transparent):
    """Square artwork of `size` px. The motif fits in the central 60%
    (adaptive icon safe zone is 66/108)."""
    s = size * 4  # supersample
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0) if transparent else BLUE + (255,))
    d = ImageDraw.Draw(img)
    # "あ"
    font = ImageFont.truetype(JP_FONT, int(s * 0.46))
    cx, cy = s * 0.47, s * 0.50
    d.text((cx, cy), "あ", font=font, fill=WHITE, anchor="mm",
           stroke_width=int(s * 0.012), stroke_fill=WHITE)
    # check-mark badge
    r = s * 0.105
    bx, by = s * 0.665, s * 0.665
    d.ellipse([bx - r, by - r, bx + r, by + r], fill=GOLD, outline=BLUE + (255,),
              width=int(s * 0.018))
    w = int(s * 0.026)
    d.line([(bx - r * 0.45, by + r * 0.02), (bx - r * 0.1, by + r * 0.38),
            (bx + r * 0.5, by - r * 0.38)], fill=WHITE, width=w, joint="curve")
    return img.resize((size, size), Image.LANCZOS)


def rounded(img, radius_ratio=0.22):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, img.size[0] - 1, img.size[1] - 1],
        radius=int(img.size[0] * radius_ratio), fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def legacy_icon(size):
    # Legacy icons: zoom the motif a little since there is no adaptive mask.
    big = glyph(int(size * 1.35), transparent=False)
    off = (big.size[0] - size) // 2
    return rounded(big.crop((off, off, off + size, off + size)))


def main():
    for name, k in DENSITIES.items():
        d = f"{RES}/mipmap-{name}"
        os.makedirs(d, exist_ok=True)
        legacy_icon(int(48 * k)).save(f"{d}/ic_launcher.png")
        glyph(int(108 * k), transparent=True).save(f"{d}/ic_launcher_foreground.png")
    os.makedirs(f"{RES}/mipmap-anydpi-v26", exist_ok=True)
    with open(f"{RES}/mipmap-anydpi-v26/ic_launcher.xml", "w") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n'
                '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@color/ic_launcher_background"/>\n'
                '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
                '    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>\n'
                '</adaptive-icon>\n')
    with open(f"{RES}/values/ic_launcher_background.xml", "w") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
                '    <color name="ic_launcher_background">#2E6DB4</color>\n</resources>\n')

    os.makedirs("store", exist_ok=True)
    # Play Store icon: full-bleed square (Play applies its own rounding).
    big = glyph(int(512 * 1.35), transparent=False)
    off = (big.size[0] - 512) // 2
    big.crop((off, off, off + 512, off + 512)).convert("RGB").save("store/icon-512.png")

    # Feature graphic 1024x500.
    fg = Image.new("RGB", (1024, 500), BLUE)
    d = ImageDraw.Draw(fg)
    d.rectangle([0, 420, 1024, 500], fill=DARK)
    icon = glyph(300, transparent=True)
    fg.paste(icon, (30, 70), icon)
    title = ImageFont.truetype(LATIN_FONT, 68)
    sub = ImageFont.truetype(LATIN_FONT, 32)
    small = ImageFont.truetype(LATIN_FONT, 26)
    d.text((340, 120), "JFT-Basic Prep", font=title, fill=WHITE)
    d.text((342, 215), "Practice questions written by", font=sub, fill=WHITE)
    d.text((342, 255), "native Japanese speakers", font=sub, fill=WHITE)
    d.text((342, 320), "Vocabulary · Conversation · Listening · Reading",
           font=small, fill=(220, 232, 247))
    d.text((40, 445), "For Specified Skilled Worker (Tokutei Ginou) applicants",
           font=small, fill=(220, 232, 247))
    fg.save("store/feature-graphic.png")
    print("icons written")


if __name__ == "__main__":
    main()
