# Distribution notes (prepared, not published)

None of this has been uploaded anywhere. No accounts have been created, no
platform terms accepted, and no project IDs exist. Fill in the placeholders
below only once they are real.

## Name

- **Proposed public name:** SocialWheel
- **Folder / TOC name:** `SocialWheel`
- **Name check (2026-11-08, not legal clearance):**
  - Wago Addons: `addons.wago.io/addons/socialwheel` returned 404 (no listing found).
  - GitHub: the only repository match was an unrelated website project (`socialwheels`).
  - Web search found no WoW addon named "SocialWheel" or "Social Wheel".
  - CurseForge: automated checks were blocked (HTTP 403). **Check
    `curseforge.com/wow/addons/socialwheel` by hand before you claim the slug.**
  - Addons with a similar idea exist: *Interactive Emote Wheel* (CurseForge) and
    *comm-wheel* (GitHub). Their names don't conflict, but mention the difference
    in the description.
  - If you need an alternative name: *EmoteRing*, *GestureWheel*, *Emote Compass*
    (run the same checks first).

## Short summary (≤ 80 chars)

> One key opens a six-slot wheel of emotes. Point, click, emote. No typing.

## Description

SocialWheel puts six emotes of your choice on a radial wheel. Press your key,
move the mouse toward an emote, and click. Right-click, Escape or a second
key press cancels, and nothing is performed.

- Six slots with a central dead zone. Defaults: Hello, Thank, Wave, Point, Laugh, Cheer.
- Choose from every built-in emote the client offers, with filters for Emotes
  and Voice Emotes and search by name, `/command` or token.
- Open at the cursor or at screen center, adjust wheel and icon size, and show
  or hide labels.
- Per-character settings. No dependencies. Does no automation: every emote
  comes from your own click.

Icons: original artwork made with AI image generation (OpenAI, via Codex), then
reviewed and edited by hand. Licensed MIT, the same as the code.

Unofficial community addon, not affiliated with or endorsed by Blizzard Entertainment.

## Installation and basic use

Extract the zip into `World of Warcraft\_forever_\Interface\AddOns\`, bind
**Options > Keybindings > AddOns > Open SocialWheel**, then press the key. Use
`/socialwheel` to configure.

## Supported game version

- **WoW Forever 1.60.1 (build 70862), interface 16001**, release **0.1.0-rc.3**.
- Do not tag Retail, Classic Era, Anniversary or any other flavor until it has
  been tested there.

## Platform notes (verify on each site at upload time)

| Platform | Forever support (as of 2026-11-08) | Action |
|---|---|---|
| CurseForge | Community guides report a "Forever" game flavor with game version 1.60.1. Not verified first-hand. | Choose the Forever flavor and version 1.60.1 only. Suggested category: *Chat & Communication* (alternative: *Roleplay*). |
| Wago Addons | Guides report a Forever flavor. Not verified first-hand. | Choose the Forever flavor only. Suggested category: *Chat & Communication* / *Social*. |
| WoWInterface | No Forever support found. | If there is no Forever category, don't label the addon as another flavor. Wait, or link to GitHub Releases. |
| GitHub Releases ([repo](https://github.com/elysium1331/SocialWheel-WoW-Forever)) | Not flavor-specific. | Attach `dist/SocialWheel-<version>.zip` by hand and paste the CHANGELOG section. |

Packaging: the zip is built locally by `scripts/package.py` and contains
`SocialWheel/SocialWheel.toc` exactly one folder deep. No `.pkgmeta` or
`release.sh` automation is included. Add one only after checking that platform's
current packager documentation.

## Optional dependencies

None. No libraries are embedded.

## Screenshot checklist (capture in game; none exist yet)

1. Wheel open at the cursor with defaults and one slot highlighted (center label visible).
2. Wheel with labels hidden at the smallest size.
3. Configuration window: preview, catalog with the *Voice Emotes* filter, a search term entered.
4. Options > Keybindings showing "Open SocialWheel" under AddOns.
5. An empty slot and its "Empty" label.
Use a neutral UI scale and crop personal names or chat if needed.

## CurseForge upload (manual, done by Ryan)

The zip from `python scripts/package.py` (`dist/SocialWheel-<version>.zip`) is
already in the shape CurseForge expects: one `SocialWheel/` folder with the TOC
inside, no extra wrapper folder, and no executables or development files.

1. Check that the `socialwheel` project name is free on CurseForge (still unchecked).
2. Create the project: name **SocialWheel**, the summary and description above,
   license **MIT**, category as in the platform table.
3. Upload the zip:
   - **Game version:** Forever 1.60.1 only.
   - **Release type:** **Beta** while the version ends in `-rc.N`. Use **Release**
     only after the remaining items in `docs/VALIDATION.md` pass and the version
     is bumped to a plain number (for example `0.1.0`).
   - **Changelog:** paste the matching `CHANGELOG.md` section.
4. Keep the AI-art disclosure line in the description. CurseForge had no
   published AI-content rule as of 2026-11-08, but several other platforms
   require disclosure, so stating it up front is the safe default.
5. After CurseForge approves the project, add its URL to `README.md` and
   `## X-Curse-Project-ID:` to the TOC (see "Adding real URLs later").

## Release checklist

1. All of docs/VALIDATION.md "In-game checks" passed on the target build. Record
   the build number.
2. Set the version in `SocialWheel.toc` (`## Version:`) and update `CHANGELOG.md`,
   `README.md` and this file.
3. `python scripts/check.py` and `python scripts/package.py` both pass.
4. Install the built zip into a clean AddOns folder and do a smoke test.
5. Take the screenshots above.
6. Upload by hand on each platform, choosing the Forever flavor only.

## Known limitations (copy into listings)

See the README "Known limitations" section. The main points: this is a release
candidate that has not been tested in game; Hold-and-release is experimental;
icons are placeholders; voice and animation details are "Unknown" for emotes
outside Blizzard's two menus; the game may block emotes in restricted contexts.

## Adding real URLs later

When projects exist, add them to `README.md` (a "Downloads" section) and to the
TOC as `## X-Curse-Project-ID:`, `## X-Wago-ID:` and `## X-Website:`. Use only
real values copied from the platform pages. Put the issue tracker URL in the
README "Troubleshooting" section.
