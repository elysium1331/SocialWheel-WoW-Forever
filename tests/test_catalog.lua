local H = ...
local ns = H.load("CatalogData.lua", {})
H.load("Catalog.lua", ns)
local C = ns.Catalog
local test, eq, truthy = H.test, H.eq, H.truthy

-- A small client-like global table (EMOTE<n>_TOKEN / _CMD<j>) for the builder.
local function clientEnv()
	local g = {
		MAXEMOTEINDEX = 306,
		EMOTE27_TOKEN = "UNUSED",
		EMOTE56_TOKEN = "HELLO", EMOTE56_CMD1 = "/hello", EMOTE56_CMD2 = "/hi",
		EMOTE98_TOKEN = "THANK", EMOTE98_CMD1 = "/thank", EMOTE98_CMD2 = "/thanks", EMOTE98_CMD3 = "/ty",
		EMOTE102_TOKEN = "WAVE", EMOTE102_CMD1 = "/wave",
		EMOTE157_TOKEN = "INCOMING", EMOTE157_CMD1 = "/incoming", EMOTE157_CMD2 = "/inc",
		EMOTE304_TOKEN = "INCOMING", EMOTE304_CMD1 = "/INC", EMOTE304_CMD2 = "/enemyincoming",
		EMOTE1_TOKEN = "AGREE", EMOTE1_CMD1 = "/agree",
		EMOTE454_TOKEN = "FORTHEALLIANCE", EMOTE455_TOKEN = "FORTHEHORDE",
		EmoteList = { "WAVE" },
		TextEmoteSpeechList = { "HELLO", "THANK", "INCOMING", "FORTHEALLIANCE" },
	}
	-- 454/455 exceed MAXEMOTEINDEX here on purpose; raise it.
	g.MAXEMOTEINDEX = 455
	return { get = function(k) return g[k] end, data = ns.CatalogData, L = { NAME_HELLO = "Hello" } }
end

test("client build: aliases of one token are merged and deduplicated", function()
	local cat = C.Build(clientEnv())
	eq(cat.source, "client")
	local inc = cat.byToken.INCOMING
	truthy(inc, "INCOMING present")
	-- /incoming, /inc from 157; /INC duplicates /inc case-insensitively; /enemyincoming added
	eq(#inc.aliases, 3)
	eq(inc.aliases[1], "/incoming")
	eq(inc.aliases[3], "/enemyincoming")
	local count = 0
	for _, e in ipairs(cat.entries) do
		if e.token == "INCOMING" then
			count = count + 1
		end
	end
	eq(count, 1, "one entry per canonical token")
end)

test("UNUSED placeholder is excluded", function()
	local cat = C.Build(clientEnv())
	eq(cat.byToken.UNUSED, nil)
end)

test("names come from the client's first command", function()
	local cat = C.Build(clientEnv())
	eq(cat.byToken.WAVE.name, "Wave")
	eq(cat.byToken.THANK.name, "Thank")
end)

test("categories overlap and metadata stays separate", function()
	local cat = C.Build(clientEnv())
	eq(cat.byToken.WAVE.inEmotes, true)
	eq(cat.byToken.WAVE.inVoice, false)
	eq(cat.byToken.WAVE.animation, "yes")
	eq(cat.byToken.WAVE.voice, "unknown")
	eq(cat.byToken.HELLO.inVoice, true)
	eq(cat.byToken.HELLO.voice, "yes")
	eq(cat.byToken.HELLO.animation, "unknown")
	eq(cat.byToken.AGREE.inEmotes, false)
	eq(cat.byToken.AGREE.inVoice, false)
	-- both faction tokens are known voice emotes even if the client added only one
	eq(cat.byToken.FORTHEHORDE.inVoice, true)
	eq(cat.byToken.FORTHEHORDE.faction, "Horde")
end)

test("filters: all, emotes, voice", function()
	local cat = C.Build(clientEnv())
	local all = C.Filter(cat, C.FILTER_ALL, "", nil)
	eq(#all, #cat.entries)
	local emotes = C.Filter(cat, C.FILTER_EMOTES, "", nil)
	eq(#emotes, 1)
	eq(emotes[1].token, "WAVE")
	local voice = C.Filter(cat, C.FILTER_VOICE, "", nil)
	eq(#voice, 5) -- HELLO, THANK, INCOMING, FORTHEALLIANCE, FORTHEHORDE
end)

test("opposite-faction voice emote is hidden", function()
	local cat = C.Build(clientEnv())
	local voice = C.Filter(cat, C.FILTER_VOICE, "", "Alliance")
	for _, e in ipairs(voice) do
		truthy(e.token ~= "FORTHEHORDE", "Horde entry hidden for Alliance")
	end
	eq(#voice, 4)
end)

test("search matches name, alias with or without slash, and token", function()
	local cat = C.Build(clientEnv())
	eq(C.Filter(cat, C.FILTER_ALL, "wav", nil)[1].token, "WAVE")
	eq(C.Filter(cat, C.FILTER_ALL, "/ty", nil)[1].token, "THANK")
	eq(C.Filter(cat, C.FILTER_ALL, "ty", nil)[1].token, "THANK")
	eq(C.Filter(cat, C.FILTER_ALL, "ENEMYINCOMING", nil)[1].token, "INCOMING")
	eq(C.Filter(cat, C.FILTER_ALL, "fortheall", nil)[1].token, "FORTHEALLIANCE")
	eq(#C.Filter(cat, C.FILTER_ALL, "zzzz", nil), 0)
	-- pattern characters are matched literally
	eq(#C.Filter(cat, C.FILTER_ALL, "%a", nil), 0)
end)

test("bundled fallback covers the verified client catalog", function()
	local cat = C.Build({ get = function() return nil end, data = ns.CatalogData, L = { NAME_HELLO = "Hello" } })
	eq(cat.source, "bundled")
	eq(#cat.entries, 257)
	eq(cat.byToken.HELLO.name, "Hello")
	eq(cat.byToken.MOUNTSPECIAL.name, "Mountspecial")
	for _, tok in ipairs({ "HELLO", "THANK", "WAVE", "POINT", "LAUGH", "CHEER" }) do
		truthy(cat.byToken[tok], tok .. " is a verified default")
	end
	eq(#C.Filter(cat, C.FILTER_EMOTES, "", nil), 22)
	eq(#C.Filter(cat, C.FILTER_VOICE, "", nil), 24)
end)
