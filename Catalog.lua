-- Emote catalog. Built at runtime the same way Blizzard's chat code does it:
-- iterate EMOTE<i>_TOKEN / EMOTE<i>_CMD<j> globals up to MAXEMOTEINDEX, and use
-- the EmoteList / TextEmoteSpeechList tables that feed Blizzard's "Emote" and
-- "Voice Emotes" chat menus. If those globals are missing, the bundled
-- CatalogData (generated from the same Blizzard source) is used instead and
-- command aliases are unavailable.
local _, ns = ...

local Catalog = {}
ns.Catalog = Catalog

local CATEGORY_EMOTES = "EMOTES"
local CATEGORY_VOICE = "VOICE"
Catalog.FILTER_ALL = "ALL"
Catalog.FILTER_EMOTES = CATEGORY_EMOTES
Catalog.FILTER_VOICE = CATEGORY_VOICE

local EXCLUDED_TOKENS = { UNUSED = true }

local function ToSet(list)
	local set = {}
	if type(list) == "table" then
		for _, v in ipairs(list) do
			if type(v) == "string" then
				set[v] = true
			end
		end
	end
	return set
end

-- "/wave" -> "Wave". Only an ASCII first letter is upper-cased so multi-byte
-- localized names are never split.
local function DisplayFromCommand(cmd)
	local name = cmd:gsub("^/", "")
	local first = name:sub(1, 1)
	if first:match("^[a-z]$") then
		name = first:upper() .. name:sub(2)
	end
	return name
end

local function TitleCaseToken(token)
	return token:sub(1, 1) .. token:sub(2):lower()
end

-- Builds the catalog.
--   env.get(name)   returns a global value (string/table/number) or nil.
--   env.data        bundled CatalogData.
--   env.L           locale table.
-- Returns { entries = {...}, byToken = {...}, source = "client"|"bundled" }.
function Catalog.Build(env)
	local get, data, L = env.get, env.data or {}, env.L or {}
	local byToken, order = {}, {}
	local source = "client"

	local maxIndex = get("MAXEMOTEINDEX")
	local clientHasTokens = type(maxIndex) == "number" and type(get("EMOTE1_TOKEN")) == "string"

	local function add(index, token)
		if type(token) ~= "string" or EXCLUDED_TOKENS[token] or not token:match("^[A-Z0-9_]+$") then
			return nil
		end
		local entry = byToken[token]
		if not entry then
			entry = { token = token, index = index, aliases = {}, aliasSet = {} }
			byToken[token] = entry
			order[#order + 1] = entry
		end
		return entry
	end

	if clientHasTokens then
		for i = 1, maxIndex do
			local entry = add(i, get("EMOTE" .. i .. "_TOKEN"))
			if entry then
				local j = 1
				local cmd = get("EMOTE" .. i .. "_CMD" .. j)
				while type(cmd) == "string" do
					local key = cmd:lower()
					if not entry.aliasSet[key] then
						entry.aliasSet[key] = true
						entry.aliases[#entry.aliases + 1] = cmd
					end
					j = j + 1
					cmd = get("EMOTE" .. i .. "_CMD" .. j)
				end
			end
		end
	else
		source = "bundled"
		for _, pair in ipairs(data.tokens or {}) do
			add(pair[1], pair[2])
		end
	end

	local emoteMenu = get("EmoteList")
	local voiceMenu = get("TextEmoteSpeechList")
	local emoteSet = ToSet(type(emoteMenu) == "table" and emoteMenu or data.emoteMenu)
	local voiceSet = ToSet(type(voiceMenu) == "table" and voiceMenu or data.voiceMenu)
	-- Blizzard appends only the player's faction token at load; keep both known.
	for _, tok in ipairs(data.voiceMenu or {}) do
		if tok == "FORTHEALLIANCE" or tok == "FORTHEHORDE" then
			voiceSet[tok] = true
		end
	end

	for _, entry in ipairs(order) do
		local t = entry.token
		entry.inEmotes = emoteSet[t] == true
		entry.inVoice = voiceSet[t] == true
		-- Blizzard's own comments: EmoteList entries "have anims",
		-- TextEmoteSpeechList entries "have sounds". Everything else is unknown.
		entry.animation = entry.inEmotes and "yes" or "unknown"
		entry.voice = entry.inVoice and "yes" or "unknown"
		if t == "FORTHEALLIANCE" then
			entry.faction = "Alliance"
		elseif t == "FORTHEHORDE" then
			entry.faction = "Horde"
		end
		if entry.aliases[1] then
			entry.name = DisplayFromCommand(entry.aliases[1])
		else
			entry.name = L["NAME_" .. t] or TitleCaseToken(t)
		end
		local parts = { entry.name:lower(), t:lower() }
		for _, a in ipairs(entry.aliases) do
			parts[#parts + 1] = a:lower()
			parts[#parts + 1] = a:lower():gsub("^/", "")
		end
		entry.searchText = table.concat(parts, "\n")
		entry.aliasSet = nil
	end

	table.sort(order, function(a, b)
		local an, bn = a.name:lower(), b.name:lower()
		if an ~= bn then
			return an < bn
		end
		return a.token < b.token
	end)

	return { entries = order, byToken = byToken, source = source }
end

-- Filters a built catalog.
--   filter        FILTER_ALL / FILTER_EMOTES / FILTER_VOICE
--   query         free text (matched plainly, case-insensitive)
--   hideFaction   faction name whose opposite-faction entry should be hidden
function Catalog.Filter(catalog, filter, query, playerFaction)
	local results = {}
	query = (query or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	for _, entry in ipairs(catalog.entries) do
		local ok = true
		if filter == CATEGORY_EMOTES then
			ok = entry.inEmotes
		elseif filter == CATEGORY_VOICE then
			ok = entry.inVoice
		end
		if ok and entry.faction and playerFaction and entry.faction ~= playerFaction then
			ok = false
		end
		if ok and query ~= "" then
			ok = entry.searchText:find(query, 1, true) ~= nil
		end
		if ok then
			results[#results + 1] = entry
		end
	end
	return results
end

-- Runtime wiring -------------------------------------------------------------

function Catalog.Initialize()
	Catalog.current = Catalog.Build({
		get = function(name) return _G[name] end,
		data = ns.CatalogData,
		L = ns.L,
	})
	return Catalog.current
end

function Catalog.Get(token)
	local c = Catalog.current
	return c and token and c.byToken[token] or nil
end

function Catalog.GetDisplayName(token)
	local entry = Catalog.Get(token)
	if entry then
		return entry.name
	end
	return nil
end
