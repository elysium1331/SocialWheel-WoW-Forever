-- English strings. This is also the fallback for every other locale:
-- a missing key in another locale table falls through to these values.
local _, ns = ...

local L = {
	ADDON_TITLE = "[Elysium] SocialWheel",
	BINDING_OPEN = "Open SocialWheel",

	CHOOSE_EMOTE = "Choose an emote",
	EMPTY_SLOT = "Empty",
	UNAVAILABLE = "Unavailable",

	-- Chat feedback (kept short; never repeated rapidly).
	MSG_PREFIX = "SocialWheel:",
	MSG_BLOCKED = "the game blocked that emote right now. Try again outside the current restriction (for example after the encounter or match).",
	MSG_FAILED = "that emote could not be performed.",
	MSG_UNKNOWN_EMOTE = "slot %d holds an emote this client does not offer (%s). Pick another in /socialwheel.",
	MSG_RECOVERED = "your saved settings were unreadable and have been reset to defaults.",
	MSG_NO_SLASH = "both /socialwheel and /swheel are used by another addon. Open SocialWheel from Options > AddOns.",
	MSG_SLASH_PARTIAL = "%s is used by another addon; use %s instead.",
	MSG_COMBAT_SETTINGS = "the Options window cannot be opened in combat. It will open when combat ends.",
	MSG_TIP = "type /socialwheel to choose your six emotes (or Shift+Right-click the open wheel).",
	MSG_TIP_BIND = "bind a key under Options > Keybindings > AddOns > Open SocialWheel, then type /socialwheel to choose your six emotes.",
	WHEEL_HINT = "Right-click: close    Shift+Right-click: customize",
	MSG_NO_BINDING = "no key is bound yet. Set one in Options > Keybindings > AddOns > Open SocialWheel.",

	-- Configuration window.
	CONFIG_TITLE = "[Elysium] SocialWheel",
	CONFIG_SLOT = "Slot %d",
	CONFIG_EDITING = "Editing slot %d: %s",
	CONFIG_PREVIEW_HINT = "Click a slot to edit it.",
	CONFIG_SEARCH = "Search name, /command or token",
	FILTER_ALL = "All",
	FILTER_EMOTES = "Emotes",
	FILTER_VOICE = "Voice Emotes",
	ASSIGN = "Assign",
	CLEAR_SLOT = "Clear Slot",
	RESTORE_DEFAULTS = "Restore Defaults",
	RESTORE_CONFIRM = "Restore SocialWheel's default emotes and options for this character?",
	WHEEL_SIZE = "Wheel size",
	ICON_SCALE = "Icon scale",
	SHOW_LABELS = "Show labels",
	POSITION = "Position",
	POSITION_CURSOR = "At cursor",
	POSITION_SCREEN = "Screen center",
	MODE = "Interaction",
	MODE_CLICK = "Click to choose",
	MODE_HOLD = "Hold and release",
	ICON = "Icon",
	ICON_AUTO = "Automatic",
	KEYBINDINGS = "Key Bindings...",
	CURRENT_KEY = "Key: %s",
	NOT_BOUND = "not bound",
	TAG_EMOTE = "Emote",
	TAG_VOICE = "Voice",
	TAG_TEXT = "Text",
	DETAIL_ANIMATION = "Animation: %s",
	DETAIL_VOICE = "Voice: %s",
	YES = "Yes",
	UNKNOWN = "Unknown",
	DETAIL_COMMANDS = "Commands: %s",
	DETAIL_TOKEN = "Token: %s",
	RESULTS = "%d emotes",

	SETTINGS_DESC = "Open a six-slot emote wheel with one key. Use the button below to change slots, size, position and interaction mode.",
	SETTINGS_OPEN = "Open SocialWheel configuration",
	UNOFFICIAL = "SocialWheel is an unofficial community addon and is not made or endorsed by Blizzard Entertainment.",

	-- English names used only when the client provides no command string.
	NAME_HELLO = "Hello",
	NAME_THANK = "Thank",
	NAME_WAVE = "Wave",
	NAME_POINT = "Point",
	NAME_LAUGH = "Laugh",
	NAME_CHEER = "Cheer",
}

ns.L = L
ns.L_FALLBACK = L

-- Global binding label read by the Key Bindings UI.
BINDING_NAME_SOCIALWHEEL_OPEN = L.BINDING_OPEN
