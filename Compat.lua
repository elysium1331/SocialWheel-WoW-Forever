-- Client compatibility layer. Every call into a client API whose presence or
-- shape could differ between WoW client flavors goes through this file.
--
-- Verified against Blizzard UI source for WoW Forever 1.60.1.70862 (interface 16001):
--   C_ChatInfo.PerformEmote(emoteName [, targetName [, suppressMoveError]])
--     HasRestrictions = true, SecretArguments = "AllowedWhenUntainted".
--     Blizzard's own Emote / Voice Emote menus call it with only the token, which
--     lets the client apply the current target itself.
--   DoEmote exists only as a deprecation shim (when loadDeprecationFallbacks is on).
--   GetFileIDFromPath, GetCursorPosition, GetCurrentKeyBoardFocus, InCombatLockdown,
--   Settings.RegisterCanvasLayoutCategory / RegisterAddOnCategory / OpenToCategory,
--   Settings.KEYBINDINGS_CATEGORY_ID, StaticPopup_ShowGenericConfirmation.
local _, ns = ...

local Compat = {}
ns.Compat = Compat

Compat.VERIFIED_INTERFACE = 16001
Compat.VERIFIED_BUILD = "1.60.1.70862"

local FACTION_ALLIANCE_TOKEN = "FORTHEALLIANCE"
local FACTION_HORDE_TOKEN = "FORTHEHORDE"

function Compat.GetBuildInfo()
	if type(GetBuildInfo) ~= "function" then
		return nil, nil
	end
	local version, build, _, interface = GetBuildInfo()
	return (version or "?") .. "." .. (build or "?"), interface
end

function Compat.GetAddOnVersion(addonName)
	local getter = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
	if getter then
		local ok, value = pcall(getter, addonName, "Version")
		if ok and type(value) == "string" then
			return value
		end
	end
	return "?"
end

-- Returns the function used to perform a built-in emote, or nil.
local function GetEmoteFunction()
	if C_ChatInfo and type(C_ChatInfo.PerformEmote) == "function" then
		return C_ChatInfo.PerformEmote
	end
	if type(DoEmote) == "function" then
		return DoEmote
	end
	return nil
end

function Compat.CanPerformEmotes()
	return GetEmoteFunction() ~= nil
end

-- Player faction ("Alliance", "Horde", or nil). Not a restricted value.
function Compat.GetPlayerFaction()
	if type(UnitFactionGroup) ~= "function" then
		return nil
	end
	local ok, faction = pcall(UnitFactionGroup, "player")
	if ok and (faction == "Alliance" or faction == "Horde") then
		return faction
	end
	return nil
end

-- Mirrors Blizzard's Voice Emote menu: the "For the <faction>" entry always
-- performs the player's own faction token.
function Compat.ResolveFactionToken(token)
	if token == FACTION_ALLIANCE_TOKEN or token == FACTION_HORDE_TOKEN then
		local faction = Compat.GetPlayerFaction()
		if faction == "Alliance" then
			return FACTION_ALLIANCE_TOKEN
		elseif faction == "Horde" then
			return FACTION_HORDE_TOKEN
		end
	end
	return token
end

function Compat.IsFactionToken(token)
	return token == FACTION_ALLIANCE_TOKEN or token == FACTION_HORDE_TOKEN
end

-- Performs one built-in emote by canonical token.
-- No target name is passed: like Blizzard's own emote menus, the client uses the
-- current target (if the emote supports one) at the moment of the call. This avoids
-- reading target names, which may be secret values on this client.
-- Returns true when the call was made without a Lua error, false otherwise.
-- The API's boolean return is deliberately not interpreted: its generated docs name
-- it "success" while Blizzard's chat code treats it as "restricted".
function Compat.PerformEmote(token)
	local fn = GetEmoteFunction()
	if not fn or type(token) ~= "string" or token == "" then
		return false
	end
	local ok = pcall(fn, token)
	return ok
end

-- Optional restriction query used only to explain a failure.
function Compat.IsAnyAddOnRestrictionActive()
	if not (C_RestrictedActions and C_RestrictedActions.IsAddOnRestrictionActive and Enum and Enum.AddOnRestrictionType) then
		return false
	end
	for _, value in pairs(Enum.AddOnRestrictionType) do
		local ok, active = pcall(C_RestrictedActions.IsAddOnRestrictionActive, value)
		if ok and active == true then
			return true
		end
	end
	return false
end

function Compat.InCombat()
	return type(InCombatLockdown) == "function" and InCombatLockdown() or false
end

function Compat.HasKeyboardFocus()
	if type(GetCurrentKeyBoardFocus) ~= "function" then
		return false
	end
	return GetCurrentKeyBoardFocus() ~= nil
end

function Compat.IsMouselooking()
	return type(IsMouselooking) == "function" and IsMouselooking() or false
end

-- Cursor position in the coordinate space of `frame` (accounts for UI scale).
function Compat.GetCursorInFrameSpace(frame)
	local x, y = GetCursorPosition()
	local scale = frame:GetEffectiveScale()
	if not scale or scale == 0 then
		scale = 1
	end
	return x / scale, y / scale
end

-- true / false when the client can answer, nil when it cannot be checked.
function Compat.TextureExists(path)
	if type(path) ~= "string" or path == "" then
		return false
	end
	if type(GetFileIDFromPath) ~= "function" then
		return nil
	end
	local ok, fileID = pcall(GetFileIDFromPath, path)
	if not ok then
		return nil
	end
	return fileID ~= nil and fileID ~= 0
end

function Compat.GetBindingText(action)
	if type(GetBindingKey) ~= "function" then
		return nil
	end
	local key = GetBindingKey(action)
	if not key then
		return nil
	end
	if type(GetBindingText) == "function" then
		return GetBindingText(key)
	end
	return key
end

-- Settings panel registration. Returns the category or nil.
function Compat.RegisterSettingsCanvas(frame, name)
	if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
		return nil
	end
	local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, frame, name)
	if not ok or not category then
		return nil
	end
	Settings.RegisterAddOnCategory(category)
	return category
end

-- Opens Options > Keybindings scrolled to the AddOns section.
-- Returns false when it cannot be done now (combat or missing API).
function Compat.OpenKeybindings()
	if Compat.InCombat() then
		return false
	end
	if Settings and Settings.OpenToCategory and Settings.KEYBINDINGS_CATEGORY_ID then
		local ok = pcall(Settings.OpenToCategory, Settings.KEYBINDINGS_CATEGORY_ID, ADDONS)
		return ok
	end
	return false
end

-- Confirmation dialog. Falls back to a private StaticPopup definition.
function Compat.Confirm(text, onAccept)
	if type(StaticPopup_ShowGenericConfirmation) == "function" then
		StaticPopup_ShowGenericConfirmation(text, onAccept)
		return
	end
	if type(StaticPopup_Show) == "function" and StaticPopupDialogs then
		StaticPopupDialogs.SOCIALWHEEL_CONFIRM = {
			text = text,
			button1 = YES or "Yes",
			button2 = NO or "No",
			OnAccept = onAccept,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
		StaticPopup_Show("SOCIALWHEEL_CONFIRM")
	end
end

-- Lets Escape close a named frame through the standard UI mechanism.
function Compat.RegisterEscapeClose(frameName)
	if type(UISpecialFrames) == "table" and type(frameName) == "string" then
		for _, name in ipairs(UISpecialFrames) do
			if name == frameName then
				return
			end
		end
		table.insert(UISpecialFrames, frameName)
	end
end

-- The circular alpha mask used for round slots (referenced by Blizzard UI in this build).
Compat.CIRCLE_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
