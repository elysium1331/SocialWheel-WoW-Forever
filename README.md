# [Elysium] SocialWheel

Part of the **Elysium** addon collection for WoW Forever by
[elysium1331](https://github.com/elysium1331).

Pick an emote from a six-slot wheel with one key, without typing a command.

**Release:** 0.2.0, tested in game on WoW Forever 1.60.1 (see
[docs/VALIDATION.md](docs/VALIDATION.md)).

SocialWheel is an unofficial community addon. Blizzard Entertainment did not
make or endorse it.

## Supported client

| Client | Version / build | Interface | Status |
|---|---|---|---|
| World of Warcraft: Forever | 1.60.1.70862 | 16001 | Built against this build's Blizzard UI source and tested in game. |

The addon claims no other client (Retail, Classic Era, Anniversary and others).
It may load elsewhere, but nobody has verified it there. Client-specific code
lives in `Compat.lua`.

## Features

- Six slots arranged around a central dead zone. Slot 1 sits at the top and the
  numbers run clockwise.
- Defaults: Hello, Thank, Wave, Point, Laugh, Cheer.
- Each slot shows an icon and a short name. The center shows the highlighted
  emote, or "Choose an emote" when nothing is highlighted.
- Empty slots stay visible and do nothing when chosen.
- The catalog lists every built-in emote this client offers (257 on 1.60.1.70862).
  Filters: **All**, **Emotes** and **Voice Emotes**. Search matches the name, any
  slash command (`/ty`, `thanks`) or the canonical token (`THANK`).
- Each slot can take a different icon from a small built-in picker.
- Options: wheel size, icon scale, label visibility, open at the cursor or at
  screen center, and interaction mode.
- Settings are saved per character and survive `/reload` and relogging.
- No dependencies, no network access, no telemetry.

## Installation

1. Download `Elysium_SocialWheel-<version>.zip` from the
   [Releases page](https://github.com/elysium1331/SocialWheel-WoW-Forever/releases). Don't use GitHub's green
   **Code > Download ZIP** button: that gives you the source code, not an
   installable addon.
2. Extract it into `World of Warcraft\_forever_\Interface\AddOns\`. The result
   should be `...\AddOns\Elysium_SocialWheel\Elysium_SocialWheel.toc`. If you have an older `SocialWheel`
   folder from 0.1.0-rc.4 or earlier, delete it.
3. Run `/reload` (or restart the game). Check that SocialWheel is enabled under
   **Esc > AddOns**.
4. Bind a key under **Options > Keybindings > AddOns > Open SocialWheel**.
   SocialWheel never assigns or changes a key binding on its own.

## Controls

| Action | Result |
|---|---|
| Press your SocialWheel key | Opens the wheel at the cursor (or screen center) |
| Move the mouse | Highlights the slot in that direction. The center is a dead zone. |
| Left-click | Performs the highlighted emote once and closes. In the dead zone it only closes. |
| Right-click, Escape, or press the key again | Closes without performing anything |
| Shift+Right-click | Closes the wheel and opens the configuration window |

**Hold-and-release (optional, off by default):** hold the key, move toward a
slot, and release to perform it. Releasing in the dead zone cancels. Enable it
under *Interaction* in the configuration window.

Emotes use your current target when the emote supports one, the same way
Blizzard's chat-menu emotes do. SocialWheel never changes your target.

## Configuration

Open the configuration window in any of these ways:

- type `/socialwheel` or `/swheel`
- Shift+Right-click the open wheel
- click SocialWheel in the minimap **AddOns** menu
- open **Options > AddOns > [Elysium] SocialWheel**

Each slash command is registered only if no other addon already uses it.

- Click a slot in the preview to edit it.
- Pick an emote in the catalog, then click **Assign** (or double-click the emote).
- **Clear Slot** empties the slot. **Icon** sets an icon override, and
  **Automatic** returns to the default icon.
- **Restore Defaults** asks for confirmation, then resets this character's slots
  and options.
- `/socialwheel version` prints the addon version, client build and catalog source.

## Known limitations

- **Tested on one setup:** WoW Forever 1.60.1 with an English client. Other
  locales and future client builds haven't been checked yet.
- **Restricted contexts:** `C_ChatInfo.PerformEmote` is marked as having
  restrictions on this client. If the game blocks an emote (for example during
  certain instance encounters or matches), SocialWheel prints one short notice
  and does nothing else. It never retries or queues the emote.
- **Voice and animation details:** Blizzard's menus mark Emote entries as
  animated and Voice Emote entries as voiced. Every other emote shows
  "Unknown". Whether you hear a voice line depends on race, body type, sound
  settings and the game.
- **Icons:** the six default emotes and the fallback icons use original
  artwork bundled with the addon. Other emotes still use built-in game icons as
  placeholders until more original art is made (see
  [docs/CODEX_ASSET_BRIEF.md](docs/CODEX_ASSET_BRIEF.md)).
- **Localization:** emote names and commands come from the client, so they follow
  your game language. Interface text is English for now.
- Account-wide profiles and custom free-text emotes (`/e ...`) are not part of
  this release.

## Troubleshooting

- **Nothing happens when I press the key:** check the binding under
  Options > Keybindings > AddOns. Bindings don't fire while you're typing in chat.
- **A slot says "Unavailable":** your saved emote doesn't exist on this client.
  Assign a different one.
- **Lua errors:** enable them with `/console scriptErrors 1`, reproduce the
  problem, and include the error text in a
  [bug report](https://github.com/elysium1331/SocialWheel-WoW-Forever/issues/new/choose) along with the output of
  `/socialwheel version`.

## Uninstall

1. Delete `World of Warcraft\_forever_\Interface\AddOns\Elysium_SocialWheel` (and `SocialWheel`, if present from an older version).
2. Optionally, delete the saved settings
   `WTF\Account\<account>\<realm>\<character>\SavedVariables\Elysium_SocialWheel.lua`
   (one file per character).
3. Any key you bound to "Open SocialWheel" becomes unused. You can rebind it in
   Options > Keybindings.

## License

The original code and the original icon artwork are under the MIT License
(see [LICENSE](LICENSE)). Blizzard
textures that the addon uses are referenced from the game client and are not
distributed. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
