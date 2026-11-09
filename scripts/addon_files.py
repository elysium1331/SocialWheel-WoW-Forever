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
    """Runtime media paths referenced by Icons.lua (icons) and Art.lua (wheel frame)."""
    text = "".join((ROOT / f).read_text(encoding="utf-8") for f in ("Icons.lua", "Art.lua"))
    refs = re.findall(r'Interface\\\\AddOns\\\\' + re.escape(ADDON) + r'\\\\([^"]+)"', text)
    return list(dict.fromkeys(r.replace("\\\\", "/") for r in refs))


def release_files() -> list:
    files = list(dict.fromkeys(EXTRA_RUNTIME + toc_files() + LEGAL + DOCS))
    # Ship only converted runtime textures that the code references.
    for rel in custom_media_refs():
        p = ROOT / rel
        if p.is_file() and p.suffix.lower() in MEDIA_SUFFIXES and rel not in files:
            files.append(rel)
    return files
