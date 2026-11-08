# Third-party notices

## Bundled third-party code or libraries

None. SocialWheel uses no external libraries and does not require any other addon.

## Blizzard Entertainment material (not covered by the MIT License)

- **Textures:** icon and mask textures (for example `Interface\Icons\...` and
  `Interface\CharacterFrame\TempPortraitAlphaMask`) are referenced by path from
  the installed game client at runtime. The release package does not contain
  them, and the MIT License does not apply to them.
- **Game data and strings:** emote names, slash commands and menu groupings are
  read from the running client. `CatalogData.lua` holds a fallback list of emote
  token identifiers and their Emote / Voice Emote menu membership. It was
  generated from Blizzard's UI source for client 1.60.1.70862. It records
  identifiers only and contains no Blizzard code or text.

World of Warcraft and Blizzard Entertainment are trademarks or registered
trademarks of Blizzard Entertainment, Inc. SocialWheel is an unofficial
community project that Blizzard has not endorsed.

## Original artwork (Media/Icons)

`Media/Icons/*.tga` are original icons created for SocialWheel on 2026-11-08 with
OpenAI's image generation tool through Codex CLI, from the briefs in
`art/briefs/`. Claude (Anthropic) directed and reviewed them for Ryan Novak. The
per-file record of prompts, revision rounds and post-processing is in
`docs/icon-manifest.json`. No Blizzard or third-party artwork was supplied as
input. Generation alone does not establish exclusive ownership or legal
clearance.

**Art license:** MIT, the same license as the code (see `LICENSE`), as chosen by
Ryan Novak on 2026-11-08. This covers the bundled `Media/Icons/*.tga` files and
their editable sources in `art/source/`. It does not cover any Blizzard
textures, which are only referenced in the game client.
