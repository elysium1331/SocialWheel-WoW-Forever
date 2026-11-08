-- Data-driven icon resolver, separate from execution logic.
--
-- Resolution order for a slot:
--   1. Per-slot override chosen in the curated picker.
--   2. Bundled custom art for the token (CUSTOM; empty until original art ships).
--   3. Per-emote placeholder candidates (built-in client icons).
--   4. Category fallback (Emotes / Voice Emotes / other text emotes).
--   5. Generic fallback.
-- Every built-in path is checked with GetFileIDFromPath when the client offers
-- it, so a missing file falls through instead of showing a broken texture. If
-- nothing resolves, the caller draws a plain colored disc.
--
-- Built-in textures are referenced in the client, never extracted or shipped.
local _, ns = ...

local Icons = {}
ns.Icons = Icons

local ICON = "Interface\\Icons\\"

-- Original art bundled with the addon: token -> runtime file (TGA).
-- Add entries only for files that exist in Media/Icons; scripts/validate.py
-- fails the build when a listed file is missing.
-- Provenance and license: docs/icon-manifest.json and THIRD_PARTY_NOTICES.md.
Icons.CUSTOM = {
	HELLO = "Interface\\AddOns\\SocialWheel\\Media\\Icons\\hello.tga",
	THANK = "Interface\\AddOns\\SocialWheel\\Media\\Icons\\thank.tga",
	WAVE = "Interface\\AddOns\\SocialWheel\\Media\\Icons\\wave.tga",
	POINT = "Interface\\AddOns\\SocialWheel\\Media\\Icons\\point.tga",
	LAUGH = "Interface\\AddOns\\SocialWheel\\Media\\Icons\\laugh.tga",
	CHEER = "Interface\\AddOns\\SocialWheel\\Media\\Icons\\cheer.tga",
}
Icons.CUSTOM_FALLBACKS = {
	generic = "Interface\\AddOns\\SocialWheel\\Media\\Icons\\_generic.tga",
	EMOTES = "Interface\\AddOns\\SocialWheel\\Media\\Icons\\_category_emotes.tga",
	VOICE = "Interface\\AddOns\\SocialWheel\\Media\\Icons\\_category_voice.tga",
	TEXT = "Interface\\AddOns\\SocialWheel\\Media\\Icons\\_generic.tga",
}

-- Per-emote placeholders (first existing path wins; later entries are older
-- fallbacks). Chosen by eye from the in-game icon art: Hello is a person
-- calling out, Wave an open raised hand, so the two stay distinct.
local HAPPY = { "Spell_Misc_EmotionHappy", "Spell_Shadow_PsychicScream" }
local SAD = { "Spell_Misc_EmotionSad", "Spell_Frost_FrostShock" }
local ANGRY = { "Spell_Misc_EmotionAngry", "Ability_Druid_DemoralizingRoar" }
local AFRAID = { "Spell_Misc_EmotionAfraid", "Spell_Shadow_PsychicScream" }
local GREET = { "Ability_Warrior_RallyingCry", "INV_Letter_15" }
local HEART = { "INV_ValentinesCard01", "INV_ValentinesCandy" }
local PARTY = { "INV_Misc_MissileSmall_Red", "INV_Misc_CelebrationCake_01", "Ability_Warrior_BattleShout" }

Icons.BY_TOKEN = {
	HELLO = GREET,
	THANK = { "Achievement_Reputation_01", "Spell_Holy_HolyGuidance" },
	WAVE = { "Spell_Holy_Heal", "Spell_Holy_LayOnHands", "INV_Gauntlets_04" },
	POINT = { "Ability_Hunter_MarkedForDeath", "Ability_Hunter_SniperShot" },
	LAUGH = HAPPY,
	CHEER = PARTY,
	-- Faces
	HAPPY = HAPPY, SMILE = HAPPY, GRIN = HAPPY, GIGGLE = HAPPY, CHUCKLE = HAPPY,
	GUFFAW = HAPPY, ROFL = HAPPY, CACKLE = HAPPY, SNICKER = HAPPY, JOKE = HAPPY,
	CRY = SAD, SAD = SAD, MOURN = SAD, SIGH = SAD, WHINE = SAD, POUT = SAD,
	ANGRY = ANGRY, ROAR = ANGRY, GLARE = ANGRY, SNARL = ANGRY, THREATEN = ANGRY,
	GROWL = ANGRY, SCOWL = ANGRY, SHAKEFIST = ANGRY,
	SCARED = AFRAID, COWER = AFRAID, PANIC = AFRAID, GASP = AFRAID, SURPRISED = AFRAID,
	-- Greetings and thanks
	GREET = GREET, HAIL = GREET, INTRODUCE = GREET, BYE = GREET,
	WELCOME = { "INV_Misc_GroupNeedMore", "INV_Misc_Bag_10" }, YW = { "INV_Misc_GroupNeedMore", "INV_Misc_Bag_10" },
	AGREE = { "Achievement_Reputation_01" }, TRUCE = { "Achievement_Reputation_01" },
	CONGRATULATE = { "INV_Misc_Gift_02", "INV_Misc_Gift_01" }, COMMEND = { "INV_Misc_Gift_02" },
	-- Celebration
	VICTORY = { "Achievement_BG_winWSG", "INV_Misc_Trophy_01" },
	DANCE = { "INV_Misc_FireDancer_01", "INV_Misc_Bell_01" },
	HUZZAH = PARTY, APPLAUD = PARTY, CLAP = PARTY, GOLFCLAP = PARTY,
	DRINK = { "INV_Drink_08", "INV_Drink_07" }, CHUG = { "INV_Drink_08" },
	EAT = { "INV_Misc_Food_15", "INV_Misc_Food_14" }, HUNGRY = { "INV_Misc_Food_15" },
	-- Affection
	KISS = HEART, LOVE = HEART, FLIRT = HEART, CUDDLE = HEART, HUG = HEART, SEXY = HEART,
	-- Gestures and poses
	BOW = { "Spell_Holy_PrayerOfSpirit" }, KNEEL = { "Spell_Holy_PrayerOfSpirit" },
	PRAY = { "Spell_Holy_PrayerOfSpirit" },
	SALUTE = { "INV_Sword_04", "INV_Sword_27" },
	FLEX = { "Ability_Warrior_StrengthOfArms", "Spell_Nature_Strength" },
	SLEEP = { "Spell_Nature_Sleep" }, TIRED = { "Spell_Nature_Sleep" }, YAWN = { "Spell_Nature_Sleep" },
	SHY = { "Ability_Rogue_Disguise" }, BASHFUL = { "Ability_Rogue_Disguise" },
	BEG = { "INV_Misc_Coin_02" },
	CHICKEN = { "Spell_Magic_PolymorphChicken" },
	TRAIN = { "INV_Misc_Toy_10", "INV_Misc_Toy_08" },
	SIT = { "Spell_Misc_Drink" }, LOOK = { "INV_Misc_Spyglass_02" }, PEER = { "INV_Misc_Spyglass_02" },
	CONFUSED = { "INV_Misc_QuestionMark" }, SHRUG = { "INV_Misc_QuestionMark" },
	TALKQ = { "INV_Misc_QuestionMark" },
	TALK = { "INV_Misc_Note_06", "INV_Misc_Note_01" }, TALKEX = { "INV_Misc_Note_06", "INV_Misc_Note_01" },
	-- Voice callouts
	HELPME = { "INV_Misc_GroupNeedMore" },
	HEALME = { "Spell_Holy_FlashHeal", "Spell_Holy_Heal02" },
	INCOMING = { "INV_Misc_Spyglass_02", "Ability_Hunter_EagleEye" },
	CHARGE = { "Ability_Warrior_Charge" },
	FLEE = { "Ability_Rogue_Sprint" },
	ATTACKMYTARGET = { "Ability_Hunter_MarkedForDeath", "Ability_DualWield" },
	OOM = { "INV_Potion_76", "Spell_Shadow_ManaBurn" },
	FOLLOW = { "INV_Misc_GroupLooking", "Ability_Tracking" },
	WAIT = { "INV_Misc_PocketWatch_01" },
	OPENFIRE = { "Spell_Fire_FlameBolt", "Spell_Fire_Fireball02" },
	NOD = { "Spell_Holy_SealOfRighteousness" },
	NO = { "Spell_Holy_PowerWordShield", "Ability_Warrior_ShieldWall" },
	RASP = { "Spell_Holy_Silence" },
	FORTHEALLIANCE = { "INV_BannerPVP_02" },
	FORTHEHORDE = { "INV_BannerPVP_01" },
}

-- Category fallbacks and generic fallback.
Icons.CATEGORY = {
	EMOTES = { "Ability_Rogue_Disguise", "Spell_Holy_MindVision" },
	VOICE = { "INV_Misc_Horn_01", "Ability_Warrior_BattleShout" },
	TEXT = { "INV_Misc_Note_06", "INV_Misc_Note_01" },
}
Icons.GENERIC = { "INV_Misc_QuestionMark" }

-- Small curated picker for per-slot overrides: key -> bundled file path or
-- built-in icon name (under Interface\Icons\). Bundled art comes first.
Icons.CURATED_ORDER = {
	"sw_hello", "sw_thank", "sw_wave", "sw_point", "sw_laugh", "sw_cheer", "sw_emote", "sw_voice",
	"greet", "hand", "handshake", "arrow", "happy", "sad", "angry", "afraid",
	"heart", "gift", "firework", "drink", "dance", "sleep", "letter", "question",
}
Icons.CURATED = {
	sw_hello = Icons.CUSTOM.HELLO,
	sw_thank = Icons.CUSTOM.THANK,
	sw_wave = Icons.CUSTOM.WAVE,
	sw_point = Icons.CUSTOM.POINT,
	sw_laugh = Icons.CUSTOM.LAUGH,
	sw_cheer = Icons.CUSTOM.CHEER,
	sw_emote = Icons.CUSTOM_FALLBACKS.EMOTES,
	sw_voice = Icons.CUSTOM_FALLBACKS.VOICE,
	greet = "Ability_Warrior_RallyingCry",
	hand = "Spell_Holy_Heal",
	handshake = "Achievement_Reputation_01",
	arrow = "Ability_Hunter_MarkedForDeath",
	happy = "Spell_Misc_EmotionHappy",
	sad = "Spell_Misc_EmotionSad",
	angry = "Spell_Misc_EmotionAngry",
	afraid = "Spell_Misc_EmotionAfraid",
	heart = "INV_ValentinesCard01",
	gift = "INV_Misc_Gift_02",
	firework = "INV_Misc_MissileSmall_Red",
	drink = "INV_Drink_08",
	dance = "INV_Misc_FireDancer_01",
	sleep = "Spell_Nature_Sleep",
	letter = "INV_Letter_15",
	question = "INV_Misc_QuestionMark",
}

function Icons.IsCuratedKey(key)
	return type(key) == "string" and Icons.CURATED[key] ~= nil
end

local cache = {}

-- Injectable existence check (tests replace it).
Icons.exists = function(path)
	return ns.Compat.TextureExists(path)
end

-- First path from `names` that exists. Unknown (nil) counts as usable only when
-- the client cannot check at all.
local function FirstExisting(names, prefix)
	if not names then
		return nil
	end
	for _, name in ipairs(names) do
		local path = (prefix or "") .. name
		local exists = cache[path]
		if exists == nil then
			exists = Icons.exists(path)
			if exists == nil then
				exists = "unknown"
			end
			cache[path] = exists
		end
		if exists == true or exists == "unknown" then
			return path
		end
	end
	return nil
end

local function CategoryOf(entry)
	if not entry then
		return nil
	end
	if entry.inEmotes then
		return "EMOTES"
	elseif entry.inVoice then
		return "VOICE"
	end
	return "TEXT"
end

-- Resolves an icon for a token.
--   entry      catalog entry (may be nil for unknown tokens)
--   override   curated key or nil
-- Returns a texture path, or nil if nothing resolved.
function Icons.Resolve(token, entry, override)
	if override and Icons.CURATED[override] then
		local path = Icons.CuratedPath(override, true)
		if path then
			return path
		end
	end
	-- Bundled files are verified by the packaging script, not GetFileIDFromPath
	-- (addon files are not in the client's file-ID list).
	if token and Icons.CUSTOM[token] then
		return Icons.CUSTOM[token]
	end
	local path = token and FirstExisting(Icons.BY_TOKEN[token], ICON)
	if path then
		return path
	end
	local category = CategoryOf(entry)
	if category then
		if Icons.CUSTOM_FALLBACKS[category] then
			return Icons.CUSTOM_FALLBACKS[category]
		end
		path = FirstExisting(Icons.CATEGORY[category], ICON)
		if path then
			return path
		end
	end
	if Icons.CUSTOM_FALLBACKS.generic then
		return Icons.CUSTOM_FALLBACKS.generic
	end
	return FirstExisting(Icons.GENERIC, ICON)
end

local function IsBundled(path)
	return path:sub(1, 17) == "Interface\\AddOns\\"
end

-- Path for a curated key. Bundled files are used as-is (verified at package
-- time); built-in names are checked like any other placeholder.
function Icons.CuratedPath(key, noFallback)
	local value = Icons.CURATED[key]
	local path
	if value then
		path = IsBundled(value) and value or FirstExisting({ value }, ICON)
	end
	if path or noFallback then
		return path
	end
	return Icons.CUSTOM_FALLBACKS.generic or FirstExisting(Icons.GENERIC, ICON)
end

-- Built-in icons carry a baked border that is cropped away; bundled art is
-- borderless and already fitted to the round slot, so it is shown whole.
function Icons.ApplyTexCoord(texture, path)
	if path and IsBundled(path) then
		texture:SetTexCoord(0, 1, 0, 1)
	else
		texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
end

function Icons.ClearCache()
	cache = {}
end
