#!/usr/bin/env python3
"""Convert approved source PNGs (art/source/*.png) to runtime TGAs (Media/Icons/*.tga).

Requires Pillow:  python -m pip install pillow

  python scripts/convert_icons.py [--size 128] key1 key2 ...   # convert listed art keys
  python scripts/convert_icons.py --all                        # every PNG in art/source

Rules enforced:
  * source must be 256x256 RGBA (transparent background)
  * output is power-of-two, 32-bit RGBA, uncompressed TGA, bottom-left origin
After converting, add the printed lines to Icons.CUSTOM in Icons.lua and set the
entry's status in docs/icon-manifest.json. scripts/package.py verifies every
referenced TGA exists.
"""
import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "art" / "source"
OUT = ROOT / "Media" / "Icons"


def convert(key: str, size: int) -> Path:
    from PIL import Image

    src = SRC / f"{key}.png"
    img = Image.open(src)
    if img.size != (256, 256):
        raise SystemExit(f"{src.name}: expected 256x256, got {img.size}")
    if img.mode != "RGBA":
        raise SystemExit(f"{src.name}: expected RGBA with transparency, got {img.mode}")
    if img.getextrema()[3][0] == 255:
        raise SystemExit(f"{src.name}: alpha channel is fully opaque; background must be transparent")
    out = OUT / f"{key}.tga"
    OUT.mkdir(parents=True, exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(out, format="TGA", rle=False)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("keys", nargs="*")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--size", type=int, default=128, choices=[64, 128, 256])
    args = ap.parse_args()
    keys = [p.stem for p in sorted(SRC.glob("*.png"))] if args.all else args.keys
    if not keys:
        ap.error("no art keys given")
    for key in keys:
        out = convert(key, args.size)
        print(f'\tTOKEN = "Interface\\\\AddOns\\\\SocialWheel\\\\Media\\\\Icons\\\\{out.name}",  -- {out.relative_to(ROOT).as_posix()}')
    return 0


if __name__ == "__main__":
    sys.exit(main())
