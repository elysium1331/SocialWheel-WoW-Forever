-- Startup, saved variables, emote execution, slash commands and quiet messaging.
local ADDON_NAME, ns = ...

local L, Compat, Database, Catalog = ns.L, ns.Compat, ns.Database, ns.Catalog

-- The single global: the Bindings.xml handler and a tiny public surface.
SocialWheel = SocialWheel or {}
local API = SocialWheel

ns.version = "?"
ns.db = nil

-- Messaging --------------------------------------------------------------------

local lastMessage = {}
local MESSAGE_COOLDOWN = 15

-- Prints at most once per `key` every MESSAGE_COOLDOWN seconds.
function ns.Notify(key, text)
	local now = GetTime and GetTime() or 0
	if lastMessage[key] and now - lastMessage[key] < MESSAGE_COOLDOWN then
		return
	end
	lastMessage[key] = now
	local frame = DEFAULT_CHAT_FRAME
	if frame and frame.AddMessage then
		frame:AddMessage("|cffd4b56a" .. L.MSG_PREFIX .. "|r " .. text)
	end
end

-- Execution ------------------------------------------------------------------------

local pendingBlockCheck = false

-- Performs the emote in `slotIndex` once. Called only from a deliberate user
-- action (click or key release). Returns true if an emote was attempted.
function ns.PerformSlot(slotIndex)
	local db = ns.db
	if not db then
		return false
	end
	local slot = db.slots[slotIndex]
	local token = slot and slot.token
	if not token then
		return false -- empty slot: nothing happens
	end
	local entry = Catalog.Get(token)
	if not entry then
		ns.Notify("unknown" .. slotIndex, L.MSG_UNKNOWN_EMOTE:format(slotIndex, token))
		return false
	end
	local resolved = Compat.ResolveFactionToken(token)
	pendingBlockCheck = true
	local ok = Compat.PerformEmote(resolved)
	pendingBlockCheck = false
	if not ok then
		ns.Notify("failed", L.MSG_FAILED)
	end
	return ok
end

-- Events -------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
ns.eventFrame = eventFrame

local function OnAddonLoaded()
	ns.version = Compat.GetAddOnVersion(ADDON_NAME)
	local db, report = Database.Load(SocialWheelCharDB, ns.Icons.IsCuratedKey)
	SocialWheelCharDB = db
	ns.db = db
	if report.reset then
		ns.Notify("recovered", L.MSG_RECOVERED)
	end
end

local function RegisterSlash()
	-- Never replace another addon's command: collect every slash string already
	-- registered through SLASH_<NAME><n> globals before claiming ours.
	local taken = {}
	pcall(function()
		for key, value in pairs(_G) do
			if type(key) == "string" and type(value) == "string" and key:sub(1, 6) == "SLASH_" then
				taken[value:lower()] = true
			end
		end
	end)
	-- Commands Blizzard has already imported (includes other addons' commands).
	if type(hash_SlashCmdList) == "table" then
		for cmd in pairs(hash_SlashCmdList) do
			if type(cmd) == "string" then
				taken[cmd:lower()] = true
			end
		end
	end
	-- Emote commands (e.g. a future /swheel emote) are also unavailable.
	if type(hash_EmoteTokenList) == "table" then
		for cmd in pairs(hash_EmoteTokenList) do
			if type(cmd) == "string" then
				taken[cmd:lower()] = true
			end
		end
	end
	local wanted = { "/socialwheel", "/swheel" }
	local free = {}
	for _, cmd in ipairs(wanted) do
		if not taken[cmd] then
			free[#free + 1] = cmd
		end
	end
	if #free == 0 or (SlashCmdList and SlashCmdList.SOCIALWHEEL) then
		ns.Notify("slash", L.MSG_NO_SLASH)
		return
	end
	for i, cmd in ipairs(free) do
		_G["SLASH_SOCIALWHEEL" .. i] = cmd
	end
	SlashCmdList.SOCIALWHEEL = function(msg)
		msg = (msg or ""):lower():match("^%s*(.-)%s*$")
		if msg == "version" then
			local build, interface = Compat.GetBuildInfo()
			ns.Notify("version", ("%s, client %s (interface %s), catalog: %s"):format(
				ns.version, tostring(build), tostring(interface), Catalog.current and Catalog.current.source or "?"))
		elseif msg == "open" then
			API.Toggle()
		else
			ns.Settings.Toggle()
		end
	end
	if #free < #wanted then
		local missing = free[1] == wanted[1] and wanted[2] or wanted[1]
		ns.Notify("slashpartial", L.MSG_SLASH_PARTIAL:format(missing, free[1]))
	end
end

local function OnPlayerLogin()
	if not ns.db then
		-- Our ADDON_LOADED was not seen (should not happen); load settings now.
		eventFrame:UnregisterEvent("ADDON_LOADED")
		OnAddonLoaded()
	end
	Catalog.Initialize()
	-- Report slots whose saved emote this client does not provide (kept, not deleted).
	for i = 1, Database.SLOT_COUNT do
		local token = ns.db.slots[i].token
		if token and not Catalog.Get(token) then
			ns.Notify("unknown" .. i, L.MSG_UNKNOWN_EMOTE:format(i, token))
		end
	end
	RegisterSlash()
	ns.Settings.RegisterOptionsCategory()
	-- One short tip per character so the configuration can be found.
	if not ns.db.tipShown then
		ns.db.tipShown = true
		ns.Notify("tip", Compat.GetBindingText("SOCIALWHEEL_OPEN") and L.MSG_TIP or L.MSG_TIP_BIND)
	end
end

eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
	if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
		eventFrame:UnregisterEvent("ADDON_LOADED")
		OnAddonLoaded()
	elseif event == "PLAYER_LOGIN" then
		OnPlayerLogin()
	elseif event == "PLAYER_LEAVING_WORLD" or event == "LOADING_SCREEN_ENABLED"
		or event == "CINEMATIC_START" or event == "PLAY_MOVIE" then
		ns.Wheel.Cancel()
		ns.Wheel.ResetKeyState()
	elseif event == "PLAYER_REGEN_ENABLED" then
		ns.Settings.OnCombatEnded()
	elseif (event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN") and arg1 == ADDON_NAME then
		-- Fired synchronously when the client refuses a call from this addon.
		if pendingBlockCheck or (type(arg2) == "string" and arg2:find("Emote", 1, true)) then
			ns.Notify("blocked", L.MSG_BLOCKED)
		end
	end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
eventFrame:RegisterEvent("LOADING_SCREEN_ENABLED")
eventFrame:RegisterEvent("CINEMATIC_START")
eventFrame:RegisterEvent("PLAY_MOVIE")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("ADDON_ACTION_BLOCKED")
eventFrame:RegisterEvent("ADDON_ACTION_FORBIDDEN")

-- Public surface -----------------------------------------------------------------

-- Bindings.xml handler; keystate is "down" or "up".
function API.OnBinding(keystate)
	ns.Wheel.OnBinding(keystate)
end

function API.Toggle()
	ns.Wheel.Toggle()
end

-- Minimap AddOns menu entry (TOC: AddonCompartmentFunc). The client looks the
-- function up by global name, so this is one of the few required globals.
function SocialWheel_OnAddonCompartmentClick()
	ns.Settings.Toggle()
end
