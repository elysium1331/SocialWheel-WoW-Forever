#!/usr/bin/env python3
"""Normalize generated art: art/source/raw/<key>.png -> art/source/<key>.png (256x256 RGBA).

Requires Pillow. If a raw image has no transparency (flat black background),
the background is removed by flood-filling near-black pixels from the edges,
with a soft alpha ramp so the edges don't look jagged.

  python scripts/normalize_art.py hello wave ...    # selected keys
  python scripts/normalize_art.py --all
"""
import argparse
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "art" / "source" / "raw"
OUT = ROOT / "art" / "source"


def key_out_black(img, hard=18, soft=48):
    """Make edge-connected near-black pixels transparent."""
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        q.append((x, 0)); q.append((x, h - 1))
    for y in range(h):
        q.append((0, y)); q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        i = y * w + x
        if seen[i]:
            continue
        seen[i] = 1
        r, g, b, a = px[x, y]
        m = max(r, g, b)
        if m > soft:
            continue
        alpha = 0 if m <= hard else int(255 * (m - hard) / (soft - hard))
        px[x, y] = (r, g, b, min(a, alpha))
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx]:
                q.append((nx, ny))
    return img


def fit_in_circle(img, radius_frac=0.47, alpha_min=40):
    """Recenter and shrink so every visible pixel lies inside the slot's circle mask."""
    from PIL import Image

    size = img.size[0]
    alpha = img.getchannel("A")
    bbox = alpha.point(lambda a: 255 if a >= alpha_min else 0).getbbox()
    if not bbox:
        return img
    cx, cy = (bbox[0] + bbox[2]) / 2, (bbox[1] + bbox[3]) / 2
    px = alpha.load()
    far = 0.0
    for y in range(bbox[1], bbox[3]):
        for x in range(bbox[0], bbox[2]):
            if px[x, y] >= alpha_min:
                d = ((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2) ** 0.5
                if d > far:
                    far = d
    scale = min(1.0, radius_frac * size / far) if far else 1.0
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    small = img.resize((max(1, round(size * scale)), max(1, round(size * scale))), Image.LANCZOS)
    # place so the content's center lands on the canvas center
    ox = round(size / 2 - cx * scale)
    oy = round(size / 2 - cy * scale)
    out.alpha_composite(small, (ox, oy)) if ox >= 0 and oy >= 0 else out.paste(small, (ox, oy), small)
    return out


def normalize(key):
    from PIL import Image

    img = Image.open(RAW / f"{key}.png")
    if img.mode != "RGBA" or img.getextrema()[3][0] == 255:
        img = key_out_black(img)
    w, h = img.size
    side = min(w, h)
    img = img.crop(((w - side) // 2, (h - side) // 2, (w + side) // 2, (h + side) // 2))
    img = fit_in_circle(img.resize((256, 256), Image.LANCZOS))
    out = OUT / f"{key}.png"
    img.save(out)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("keys", nargs="*")
    ap.add_argument("--all", action="store_true")
    args = ap.parse_args()
    keys = [p.stem for p in sorted(RAW.glob("*.png"))] if args.all else args.keys
    for k in keys:
        print("normalized", normalize(k).relative_to(ROOT).as_posix())


if __name__ == "__main__":
    main()
