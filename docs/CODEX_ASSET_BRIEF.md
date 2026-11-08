# SocialWheel custom icon brief (for Codex or any artist)

**Status:** batch 1 shipped in 0.1.0-rc.3 (hello, thank, wave, point, laugh,
cheer, _generic, _category_emotes, _category_voice). The briefs Codex received
are in `art/briefs/` (`batch-1.md`, then the `batch-1b.md` revision), and its
replies, including exact prompts, are in `art/briefs/logs/`. The art is licensed
MIT, the same as the code. Batch 2 has not started.

**Lessons from batch 1 (put these in future briefs):** ask for no background
disc or plate; keep subjects large; avoid an emoji look; replace full-body
figures with a gesture close-up; and attach approved icons as style references.
`scripts/normalize_art.py` fits each image inside the slot circle
automatically.

This brief can be handed to Codex (or a human artist) once Ryan has set up an
authorized integration. SocialWheel does not contact any service itself.

## Goal

A coherent set of **original** fantasy emote icons for a six-slot radial wheel.
Each icon sits in a dark circular slot with a muted gold ring and is displayed at
about **40–64 px**.

## Hard requirements

| Item | Requirement |
|---|---|
| Source format | PNG, **256 × 256**, RGBA, **transparent background** |
| Content | One centered symbol, roughly 80% of the canvas, safe inside a circle (the slot masks the corners) |
| Text | **None.** No letters, labels, numbers, wheel borders, frames or branding |
| Readability | Must read clearly at 40 px. Test by downscaling. |
| Consistency | Same light direction (top-left), same line weight, same palette family, similar visual weight across the set |
| Originality | Original work. Do not copy or trace World of Warcraft icons, faction crests, Blizzard logos, or any third-party art. |
| Similar actions | Silhouettes must differ clearly (see pairs below) |

### Style

Restrained fantasy. Painterly but simple shapes. Warm parchment, bronze and
muted-gold accents on a few saturated focal colors. Soft rim light. No photo
realism and no heavy texture noise.

### Distinctness rules

- **Hello vs Wave:** Hello uses greeting/speech symbolism (for example a speech
  bubble with a raised open palm *inside* it, or a herald's horn with a sound
  arc). Wave is a single hand in motion with motion arcs and no speech element.
- **Thank:** clearly reads as gratitude, for example two hands pressed together
  with a small heart or warm glow. It must not look like prayer alone.
- **Point** is an extended index finger with a directional arc. **Laugh** is a
  laughing face or mask with crinkled eyes. **Cheer** is raised arms or a raised
  goblet with confetti sparks.

## Batches

1. **Batch 1 (now):** `hello`, `thank`, `wave`, `point`, `laugh`, `cheer`, plus
   `_generic` (fallback), `_category_emotes` (animated emotes) and
   `_category_voice` (voice emotes).
2. **Batch 2:** the remaining Emote and Voice Emote menu entries (46 tokens in
   total across both menus; see the manifest's `categories`).
3. **Batch 3:** all other text emotes, grouped where one image honestly fits
   several tokens.

## Manifest and naming

[`docs/icon-manifest.json`](icon-manifest.json) lists **every emote in the
verified catalog** (257 tokens, client 1.60.1.70862). Each entry has:

- `token`: canonical emote token, stable across locales (for example `WAVE`)
- `art_key`: file stem. Tokens share an `art_key` only when they are truly the
  same gesture (`TALKEX`/`TALKQ` → `talk`, `YW` → `welcome`, the two faction
  cheers → `for_the_faction`)
- `source_png`: `art/source/<art_key>.png`
- `runtime_file`: `Media/Icons/<art_key>.tga`
- `batch`, `status` (`pending` → `delivered` → `approved` → `shipped`)

Add these fields when art is delivered: `author`, `tool` (for example "Codex
image generation" with model/version if known), `date`, `license`, `notes`.

## Provenance and license

- Asset license: **MIT**, the same as the code (decided 2026-11-08). Record it in
  each manifest entry. A different license for a future batch needs Ryan's
  explicit decision and a note in `THIRD_PARTY_NOTICES.md`.
- For every file, record who or what produced it, when, the prompt or brief
  version, and any human edits.
- Generating artwork does not by itself establish exclusive ownership or legal
  clearance. Review each image for resemblance to existing art before approving it.
- Do not ship art with unknown redistribution rights.

## Repeatable workflow

1. Copy the batch's entries from the manifest into the request, along with this
   brief and the distinctness rules.
2. Receive PNGs and save them to `art/source/<art_key>.png`. This folder is
   outside the addon package and never ships.
3. Review each image at 256 px and at 48 px against the dark slot background.
   Mark it `approved` in the manifest with provenance fields filled in.
4. Normalize, then convert: `python scripts/normalize_art.py <art_key> ...`, then
   `python scripts/convert_icons.py <art_key> ...` (Pillow required).
   This produces 128 × 128 32-bit RGBA uncompressed TGA in `Media/Icons/`.
5. Add the printed lines to `Icons.CUSTOM` (or `Icons.CUSTOM_FALLBACKS` for
   `generic` / `EMOTES` / `VOICE`) in `Icons.lua`.
6. Run `python scripts/package.py`. It fails if a referenced TGA is missing or a
   PNG is referenced at runtime. Only referenced TGAs go into the zip.
7. Check in game that the icon renders (see docs/VALIDATION.md). If it doesn't,
   the resolver falls back to the built-in placeholder.

## Runtime format notes

- The client loads **TGA** and **BLP** for addon textures. Warcraft Wiki
  documents PNG support on Retail since 10.0.7, but nobody has verified it on
  Forever, so SocialWheel ships TGA only.
- Use power-of-two dimensions (64, 128 or 256). 128 keeps the zip small and
  stays sharp at 64 px.
- TGA must be 32-bit with straight (non-premultiplied) alpha. Keep fully
  transparent pixels black or neutral to avoid fringes. Test against the dark
  slot.
- File paths in Lua use `Interface\\AddOns\\Elysium_SocialWheel\\Media\\Icons\\<file>.tga`.
