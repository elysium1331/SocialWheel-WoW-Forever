# Validation report: [Elysium] SocialWheel 0.1.0

Target client: **WoW Forever 1.60.1.70862, interface 16001** (read from the local
install's `.build.info`; the interface number matches community sources and the
Blizzard UI source at the same build).

**Status: released as 0.1.0.** Ryan ran the full in-game checklist below on
WoW Forever 1.60.1.70862 (Night Elf priest, English client), and all items
passed (confirmed 2026-11-08). The automated checks and source-level
verification passed as well.

## 1. Verified from Blizzard UI source (build 1.60.1.70862)

Source: the `forever` branch of the Gethe/wow-ui-source mirror, commit
`9dc84f0`, `version.txt` = `1.60.1.70862`. It was used only as reference
and is not redistributed.

| Topic | Finding | Where it is used |
|---|---|---|
| Emote API | `C_ChatInfo.PerformEmote(emoteName, targetName?, suppressMoveError?)` has `HasRestrictions = true` and `SecretArguments = "AllowedWhenUntainted"`. `DoEmote` exists only as a deprecation shim. | `Compat.PerformEmote` |
| Blizzard menus | The Emote submenu iterates `EmoteList` and the Voice Emotes submenu iterates `TextEmoteSpeechList`. Both call `C_ChatInfo.PerformEmote(token)` with no target. "For the Alliance/Horde" is resolved to the player's faction. | Catalog categories, faction handling |
| Token enumeration | `EMOTE<i>_TOKEN` and `EMOTE<i>_CMD<j>` up to `MAXEMOTEINDEX` (628), the same as `ChatFrameUtil.ImportEmoteTokensToHash`. 260 indices give 257 unique tokens (excluding `UNUSED`; `INCOMING` and `FLEE` appear twice). | `Catalog.Build`, `CatalogData.lua` |
| Labels | Blizzard's menu label is `_G["EMOTE"..i.."_CMD1"]`, which is localized. | Display names |
| Return value | Docs call it `success`, but the chat edit box treats it as `restricted`. SocialWheel does not interpret it. | `Compat.PerformEmote` |
| Restrictions | `C_RestrictedActions.IsAddOnRestrictionActive` exists, along with `Enum.AddOnRestrictionType` (Combat, Encounter, ChallengeMode, PvPMatch, Map, Chat) and the `ADDON_ACTION_BLOCKED` / `ADDON_ACTION_FORBIDDEN` events. | Blocked-emote notice |
| Bindings | `Bindings.xml` `<Binding runOnUp="true">` delivers `keystate` "down"/"up" (Blizzard movement bindings use the same mechanism). | Hold-and-release |
| Settings | `Settings.RegisterCanvasLayoutCategory`, `RegisterAddOnCategory`, `OpenToCategory(id, scrollTo)`, `Settings.KEYBINDINGS_CATEGORY_ID`. | Options page, Key Bindings button |
| Templates / UI | `ButtonFrameTemplate`, `UIPanelButtonTemplate`, `UICheckButtonTemplate`, `SearchBoxTemplate`, `WowScrollBoxList`, `MinimalScrollBar`, `CreateScrollBoxListLinearView`, `ScrollUtil.InitScrollBoxListWithScrollBar`, `CreateDataProvider`, `StaticPopup_ShowGenericConfirmation`, `UISpecialFrames` | Config window |
| Textures | `GetFileIDFromPath` exists. `Interface\CharacterFrame\TempPortraitAlphaMask` and `Interface\Icons\INV_Misc_QuestionMark` are referenced by Blizzard UI in this build. | Icon resolver, round slots |
| Events | ADDON_LOADED, PLAYER_LOGIN, PLAYER_LEAVING_WORLD, LOADING_SCREEN_ENABLED, CINEMATIC_START, PLAY_MOVIE, PLAYER_REGEN_ENABLED, UPDATE_BINDINGS are all documented. | Core |

**Assumptions not verified in game:**
- Insecure addon code may call `PerformEmote` outside restricted states, as
  Blizzard's own menus do.
- A key-up from a binding counts as a valid context for emotes (this matters
  only for Hold-and-release).
- Addon textures in TGA load as they do on Retail.
- The placeholder icon paths exist in this client. The resolver checks each one
  with `GetFileIDFromPath` at runtime and falls back otherwise.

## 2. Automated checks (run 2026-11-08)

| Check | Command | Result |
|---|---|---|
| Lua 5.1 syntax for all 10 TOC Lua files (real Lua 5.1 VM via `lupa`) | `python scripts/check.py` | Pass |
| No global writes outside the allowlist (bytecode SETGLOBAL scan) | `python scripts/check.py` | Pass. The scanner was tested to catch a planted global and to reject `//` and `goto`. |
| Unit tests: angle selection, wraparound, sector boundaries, dead zone, hysteresis, clamping | `tests/test_wheelmath.lua` | 9/9 pass |
| Unit tests: defaults, validation, repair, unknown-token preservation, schema-0 migration, newer-schema retention, failed-migration recovery, reset | `tests/test_database.lua` | 9/9 pass |
| Unit tests: alias deduplication, `UNUSED` exclusion, category overlap, faction hiding, search (name / alias / token / literal), bundled catalog = 257 | `tests/test_catalog.lua` | 8/8 pass |
| Unit tests: icon fallback chain, override, custom art, nothing-resolves path, Hello ≠ Wave | `tests/test_icons.lua` | 9/9 pass |
| Source validation: TOC paths, Interface, SavedVariables, version consistency, texture refs, no PNG at runtime | `python scripts/package.py --check` | Pass |
| Archive validation: one top folder, TOC one level deep, required files, exclusions, no local paths | `python scripts/package.py` | Pass |

A dev-only stub smoke run (kept in the author's scratch space and not part of
this repository) also loaded all files in TOC order. It exercised
open/cancel/repeat-guard/dead-zone/empty-slot/hold-release/slash-conflict paths
and the configuration window build. This catches nil calls and typos only. **It
is not evidence of in-game behavior.**

## 3. In-game checks

Reported by Ryan for 0.1.0-rc.1 on 1.60.1.70862:
- [x] Loaded after a plain `/reload`. It was already enabled in Esc > AddOns.
- [x] "Open SocialWheel" appeared in Key Bindings. After binding a key, the wheel opened and worked as intended.
- [x] The six defaults displayed with icons and labels, and the highlight and center label worked (screenshot).
- Finding: the configuration window was hard to discover. rc.2 adds a minimap AddOns-menu
  entry, Shift+Right-click, an on-wheel hint and a one-time chat tip.
- Finding: the placeholder icons were unclear. rc.2 uses new picks reviewed visually.

Reported by Ryan for 0.1.0-rc.2 (screenshot):
- [x] Loaded after `/reload`. The six rc.2 placeholder icons all render; none fell back to the generic icon.
- [x] The control hint shows under the wheel, and the highlight and center label work over a busy scene.

Reported by Ryan for 0.1.0-rc.3:
- [x] Everything works in game after a plain `/reload`, including the new original icons.

Reported by Ryan for 0.1.0-rc.4 and 0.1.0-rc.5:
- [x] Everything checks out in game after `/reload`: Elysium branding, the renamed folder, icons and key binding.

Full checklist, run on 0.1.0-rc.5 and confirmed by Ryan on 2026-11-08 (all passed):

Do these on 1.60.1.70862 with `/console scriptErrors 1` enabled. Record pass or
fail and the build number.

1. [x] Addon appears in the AddOns list (not marked out of date) and loads with no Lua errors after login and `/reload`.
2. [x] "Open SocialWheel" appears under Options > Keybindings > AddOns, with no key assigned by default.
3. [x] After binding a key, pressing it opens the wheel at the cursor. Six defaults show icon and name; the center says "Choose an emote".
4. [x] Each default (Hello, Thank, Wave, Point, Laugh, Cheer) performs **exactly once** per click. Check chat and animation.
5. [x] Cancelling performs nothing: right-click, Escape, the key again, left-click in the dead zone, Alt+Z, and a zone change or loading screen.
6. [x] With a target selected, `/wave`-style text names the target. With no target, the untargeted text appears. The target never changes.
7. [x] Holding the key does not toggle the wheel repeatedly (auto-repeat guard).
8. [x] Pressing Enter to type in chat while the wheel is open closes it. Movement keys work while it is open and never get stuck.
9. [x] Catalog shows about 257 entries under All. The Emotes (22) and Voice Emotes (23 for your faction) filters work. Search finds `ty`, `/thanks`, `THANK`.
10. [x] Reassign and clear all six slots. Icon override and Automatic work. Restore Defaults asks first.
11. [x] Settings persist across `/reload` and a full relog. Another character keeps separate settings.
12. [x] Change UI scale (Options > Graphics) and resolution: the wheel stays under the cursor and is clamped at all four screen edges and corners. Screen-center mode works.
13. [x] Combat: open the wheel and emote in combat (open world). Observe any block notice inside a dungeon encounter or battleground. The notice prints once and does not repeat.
14. [x] Missing textures: temporarily add a bogus path to `Icons.BY_TOKEN.WAVE` and confirm the fallback icon shows, with no broken texture.
15. [x] Night Elf priest: Voice Emotes (Hello, Thank, Cheer, ...) play voice lines with sound on. Note any that are silent. Don't generalize to other races or body types.
16. [x] English client works. If another locale is available, emote names follow it and the UI falls back to English.
17. [x] Clean install from `dist/Elysium_SocialWheel-0.1.0-rc.5.zip` into an empty AddOns folder.
18. [x] Upgrade: put an old-shape `SocialWheel.lua` SavedVariables file in place (for example `SocialWheelCharDB = { slots = { "WAVE", "BOW" } }`) and confirm it migrates.
19. [x] Hold-and-release (experimental): releasing over a slot performs once; releasing in the dead zone cancels. If emotes fail on release, keep Click mode as the default and document it.
20. [x] `/swheel` and `/socialwheel` work, and `/socialwheel version` prints the build.
21. [x] The minimap AddOns menu lists SocialWheel with an icon, and clicking it opens or closes the configuration window.
22. [x] Shift+Right-click on the open wheel closes it (no emote) and opens the configuration window.
23. [x] The one-time chat tip appears once per character and not after the next `/reload`.
25. [x] rc.3 original icons render sharp and uncropped in the wheel, picker and catalog, with the round slot showing each whole symbol, and the AddOns list shows the speech-bubble icon.
27. [x] rc.5 folder rename: only `Elysium_SocialWheel` exists in AddOns, it loads with the key binding intact, it sits alone (not nested) under the Elysium heading, and icons render from the new path.
26. [x] rc.4 branding: Esc > AddOns shows an "Elysium" heading containing "[Elysium] SocialWheel", and Options > AddOns and the config window use the same title.
24. [x] New icons (Hello greeting figure, Thank handshake, Wave raised hand, Point arrow, Laugh grin, Cheer firework) render with no question marks.

## 4. Local installation performed

- 2026-11-08: `python scripts/package.py --install` extracted
  `SocialWheel-0.1.0-rc.1.zip` into `World of Warcraft\_forever_\Interface\AddOns\SocialWheel`.
- No SocialWheel folder existed before (the AddOns folder was empty), so no backup was needed.
- No other addons, game files or settings were changed.
- The game client was running at install time. A plain `/reload` loaded the new addon (confirmed in game).
- rc.3 (with original art) was installed the same way.
- rc.2 was installed with `Install-SocialWheel.cmd`. It detected the game folder from
  Battle.net's records and backed up the previous copy to `./backups/`.

## 5. Version 0.2.0 (shared painted look): in-game checklist

Ryan installed 0.2.0 on 2026-11-09 and reported that it looks good. [x] marks what
that covers; items 4-5 were not reported separately (the controller, catalog and
settings code is unchanged from 0.1.0).

Automated: `scripts/check.py` 37/37 tests pass; a stub smoke run (open, highlight,
perform, close, configuration window) passes; `scripts/package.py` passes.

1. [x] The wheel shows the painted disc, gold rim, six slot rings, spokes, stars and hub; no green/black squares.
2. [x] The six emote icons sit centered in their rings; the hovered slot glows and its name shows under the wheel, readable over bright scenery.
3. [x] Empty and unavailable slots look dimmed; game-icon emotes (non-default picks) are cropped round.
4. [ ] The configuration window's preview uses the new look; clicking a slot selects it and the slot numbers show.
5. [ ] Everything from 0.1.0 still works (click and hold-and-release modes, closing, search, settings).
