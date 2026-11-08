local H = ...
local ns = H.load("Icons.lua", {})
local I = ns.Icons
local test, eq, truthy = H.test, H.eq, H.truthy

local P = "Interface\\Icons\\"
local MEDIA = "Interface\\AddOns\\Elysium_SocialWheel\\Media\\Icons\\"

local function withFiles(set)
	I.ClearCache()
	I.exists = function(path)
		return set[path] == true
	end
end

test("bundled art wins for the six defaults", function()
	withFiles({ [P .. "Spell_Holy_Heal"] = true })
	for token, file in pairs({ HELLO = "hello", THANK = "thank", WAVE = "wave", POINT = "point", LAUGH = "laugh", CHEER = "cheer" }) do
		eq(I.Resolve(token, { inEmotes = true }, nil), MEDIA .. file .. ".tga", token)
	end
end)

test("built-in placeholder is used when there is no bundled art", function()
	withFiles({ [P .. "Spell_Misc_EmotionSad"] = true })
	eq(I.Resolve("CRY", { inEmotes = true }, nil), P .. "Spell_Misc_EmotionSad")
end)

test("second built-in candidate is used when the first is missing", function()
	withFiles({ [P .. "Spell_Frost_FrostShock"] = true })
	eq(I.Resolve("CRY", { inEmotes = true }, nil), P .. "Spell_Frost_FrostShock")
end)

test("category fallbacks use bundled category art", function()
	withFiles({})
	eq(I.Resolve("AGREEX", { inVoice = true }, nil), MEDIA .. "_category_voice.tga")
	eq(I.Resolve("AGREEX", { inEmotes = true }, nil), MEDIA .. "_category_emotes.tga")
	eq(I.Resolve("AGREEX", {}, nil), MEDIA .. "_generic.tga")
	eq(I.Resolve("NOTREAL", nil, nil), MEDIA .. "_generic.tga")
end)

test("with no bundled fallbacks, built-in generic is last resort, else nil", function()
	local saved = I.CUSTOM_FALLBACKS
	I.CUSTOM_FALLBACKS = {}
	withFiles({ [P .. "INV_Misc_QuestionMark"] = true })
	eq(I.Resolve("NOTREAL", nil, nil), P .. "INV_Misc_QuestionMark")
	withFiles({})
	eq(I.Resolve("NOTREAL", nil, nil), nil)
	I.CUSTOM_FALLBACKS = saved
end)

test("unknown existence (API missing) still yields a path", function()
	I.ClearCache()
	I.exists = function() return nil end
	eq(I.Resolve("CRY", { inEmotes = true }, nil), P .. "Spell_Misc_EmotionSad")
end)

test("curated overrides: built-in names are checked, bundled paths used directly", function()
	withFiles({ [P .. "INV_ValentinesCard01"] = true })
	eq(I.Resolve("WAVE", { inEmotes = true }, "heart"), P .. "INV_ValentinesCard01")
	eq(I.Resolve("CRY", { inEmotes = true }, "sw_laugh"), MEDIA .. "laugh.tga")
	withFiles({})
	-- a missing built-in override falls through to the normal chain
	eq(I.Resolve("WAVE", { inEmotes = true }, "heart"), MEDIA .. "wave.tga")
	eq(I.IsCuratedKey("heart"), true)
	eq(I.IsCuratedKey("sw_wave"), true)
	eq(I.IsCuratedKey("nope"), false)
end)

test("every curated key has a value and keys are unique", function()
	local seen = {}
	for _, key in ipairs(I.CURATED_ORDER) do
		eq(type(I.CURATED[key]), "string", key)
		truthy(not seen[key], "duplicate " .. key)
		seen[key] = true
	end
end)

test("texture crop: built-in icons cropped, bundled art shown whole", function()
	local coords
	local tex = { SetTexCoord = function(_, a, b, c, d) coords = { a, b, c, d } end }
	I.ApplyTexCoord(tex, MEDIA .. "wave.tga")
	eq(coords[1], 0)
	eq(coords[2], 1)
	I.ApplyTexCoord(tex, P .. "Spell_Holy_Heal")
	eq(coords[1], 0.08)
end)

test("Hello and Wave use different art", function()
	truthy(I.CUSTOM.HELLO ~= I.CUSTOM.WAVE)
	truthy(I.BY_TOKEN.HELLO[1] ~= I.BY_TOKEN.WAVE[1])
end)
