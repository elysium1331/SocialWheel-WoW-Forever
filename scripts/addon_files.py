"""Single source of truth for the addon's version and release contents."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADDON = "Elysium_SocialWheel"
TOC = ROOT / f"{ADDON}.toc"

# Explicit inclusion rules for the installable zip (in addition to TOC-listed files).
EXTRA_RUNTIME = ["Bindings.xml", f"{ADDON}.toc"]
LEGAL = ["LICENSE", "THIRD_PARTY_NOTICES.md"]
DOCS = ["README.md", "CHANGELOG.md"]
MEDIA_DIR = "Media/Icons"
MEDIA_SUFFIXES = {".tga", ".blp"}


def toc_text() -> str:
    return TOC.read_text(encoding="utf-8")


def toc_field(name: str) -> str:
    m = re.search(rf"^## {re.escape(name)}:\s*(.+?)\s*$", toc_text(), re.M)
    if not m:
        raise SystemExit(f"TOC is missing ## {name}")
    return m.group(1)


def version() -> str:
    return toc_field("Version")


def toc_files() -> list:
    files = []
    for line in toc_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        files.append(line.replace("\\", "/"))
    return files


def custom_media_refs() -> list:
    """Runtime media paths referenced by Icons.CUSTOM / CUSTOM_FALLBACKS."""
    text = (ROOT / "Icons.lua").read_text(encoding="utf-8")
    refs = re.findall(r'Interface\\\\AddOns\\\\' + re.escape(ADDON) + r'\\\\([^"]+)"', text)
    return [r.replace("\\\\", "/") for r in refs]


def release_files() -> list:
    files = list(dict.fromkeys(EXTRA_RUNTIME + toc_files() + LEGAL + DOCS))
    media = ROOT / MEDIA_DIR
    if media.is_dir():
        refs = set(custom_media_refs())
        for p in sorted(media.iterdir()):
            rel = p.relative_to(ROOT).as_posix()
            # Ship only converted runtime textures that the code references.
            if p.suffix.lower() in MEDIA_SUFFIXES and rel in refs:
                files.append(rel)
    return files
