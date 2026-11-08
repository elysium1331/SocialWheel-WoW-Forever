# Contributing

Thanks for helping. Keep changes small and focused.

## Local setup

1. Clone the repository anywhere outside the game folder.
2. Install Python 3.10+ and the Lua 5.1 runtime used for checks:
   `python -m pip install lupa`
3. To try a build in game on Windows, double-click `Install-SocialWheel.cmd`. It
   finds the WoW install from Battle.net's records, the registry or common
   folders. Pass `-WowPath "<folder containing _forever_>"` if detection fails.
   Alternatively: `python scripts/package.py --install "<WoW>\_forever_\Interface\AddOns"`.
   Either way, an existing `SocialWheel` folder is backed up to `./backups/` first.
   Rebuild with `python scripts/package.py` before reinstalling after code changes.

## Validation (run before every pull request)

```
python scripts/check.py          # Lua 5.1 syntax, global-write check, unit tests
python scripts/package.py        # source validation + build + archive validation
```

Then run the relevant items in [docs/VALIDATION.md](docs/VALIDATION.md) in game
and state in the PR which ones you ran. Do not describe untested behavior as tested.

## Coding conventions

- Lua 5.1 as used by WoW: no `goto`, `//`, bitwise operators or `_ENV`.
- Each file starts with `local ADDON_NAME, ns = ...` and stores its module on `ns`.
  The only allowed globals are `SocialWheel`, `SocialWheelCharDB`,
  `BINDING_NAME_SOCIALWHEEL_OPEN`, the two frame names used for Escape handling
  and the `SLASH_SOCIALWHEEL<n>` strings.
- Client API differences go in `Compat.lua`. Pure logic (`WheelMath.lua`,
  `Database.lua`, `Catalog.Build`) must stay free of WoW API calls so it can be tested.
- No permanent `OnUpdate`, no global input hooks, no timers that act on their own.
  Every emote must come from a deliberate user action.
- Chat output goes through `ns.Notify`, which limits how often each message can print.
- Changing the saved-settings shape: bump `Database.SCHEMA_VERSION` and add a
  migration plus a test.
- Releasing: change the version only in the TOC (`Elysium_SocialWheel.toc`, `## Version:`), then update
  `CHANGELOG.md`, `README.md` and `docs/DISTRIBUTION.md`. `package.py` fails if
  these files disagree.

## Updating the emote catalog for a new client build

```
python scripts/extract_catalog.py <path>/Blizzard_ChatFrameBase/Mainline/ChatEmoteConstants.lua <client-version>
```

This regenerates `CatalogData.lua` (the fallback) and `docs/icon-manifest.json`. At
runtime the addon still reads the catalog from the client itself.

## Localization

`Locales/enUS.lua` defines every string and also serves as the fallback. To add a
locale, create `Locales/<locale>.lua` that returns early unless
`GetLocale() == "<locale>"` and then overwrites keys in `ns.L`. List the file in
the TOC after `enUS.lua`. Emote names and commands already come from the
client's own localized strings, and canonical tokens stay in English.

## Art

Read [docs/CODEX_ASSET_BRIEF.md](docs/CODEX_ASSET_BRIEF.md). Contribute only
original artwork you have the right to license, and record its provenance.
