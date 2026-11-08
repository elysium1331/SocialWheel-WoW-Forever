# Changelog

All notable user-facing changes. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/). The saved-settings schema
version is tracked separately (currently schema 1).

## [0.1.0-rc.4] - 2026-11-08

### Changed
- Branded as part of the Elysium addon collection. The addon list, Options and
  the configuration window show "[Elysium] SocialWheel", and the game's AddOns
  list files it under an "Elysium" heading. The folder name, settings, key
  binding and slash commands are unchanged, so existing installs upgrade in place.

## [0.1.0-rc.3] - 2026-11-08

### Added
- Original icons for Hello, Thank, Wave, Point, Laugh and Cheer, plus original
  generic, Emotes and Voice Emotes fallback icons. They are offered first in the
  per-slot icon picker. Emotes without their own art fall back to the matching
  category icon. The artwork is MIT-licensed, the same as the code.

### Changed
- Built-in game icons stay as placeholders for other emotes until more original
  art is made.

## [0.1.0-rc.2] - 2026-11-08

### Added
- SocialWheel entry in the minimap AddOns menu (opens the configuration window).
- Shift+Right-click on the open wheel closes it and opens the configuration window.
- A small control hint under the wheel, and a one-time chat tip per character
  explaining how to customize.

### Changed
- Clearer placeholder icons: a greeting figure for Hello, a handshake for Thank,
  a raised hand for Wave, an arrow for Point, a grinning face for Laugh and a
  firework for Cheer. Face icons are also used for other emotion emotes. The
  icon picker offers the new set. Older icon overrides revert to Automatic.

## [0.1.0-rc.1] - 2026-11-08

Release candidate. Not yet tested in game.

### Added
- Six-slot radial emote wheel opened by the "Open SocialWheel" key binding (no default key).
- Click mode: highlight with the mouse, left-click to perform once; right-click, Escape or the key cancels.
- Experimental hold-and-release mode (off by default).
- Configuration window (`/socialwheel`, `/swheel`, Options > AddOns) with live preview,
  searchable catalog (All / Emotes / Voice Emotes), assign, clear, icon override and
  restore-defaults with confirmation.
- Options for wheel size, icon scale, labels, cursor- or screen-centered position.
- Complete built-in emote catalog read from the client, with a bundled fallback generated
  from WoW Forever 1.60.1.70862 UI source.
- Per-character saved settings with validation, migration and recovery.
