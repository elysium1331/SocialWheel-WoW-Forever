-- Saved-variable schema, defaults, validation and migrations. Pure Lua; unit-tested.
--
-- The schema version is independent of the addon release version: bump
-- SCHEMA_VERSION only when the stored shape changes, and add a migration step.
local _, ns = ...

local Database = {}
ns.Database = Database

Database.SCHEMA_VERSION = 1
Database.SLOT_COUNT = 6

Database.DEFAULT_TOKENS = { "HELLO", "THANK", "WAVE", "POINT", "LAUGH", "CHEER" }

Database.LIMITS = {
	wheelSize = { min = 200, max = 420, default = 280, step = 20 },
	iconScale = { min = 0.6, max = 1.6, default = 1.0, step = 0.1 },
}

Database.POSITIONS = { CURSOR = true, SCREEN = true }
Database.MODES = { CLICK = true, HOLD = true }

local function CopyDefaults()
	local slots = {}
	for i = 1, Database.SLOT_COUNT do
		slots[i] = { token = Database.DEFAULT_TOKENS[i] }
	end
	return {
		schemaVersion = Database.SCHEMA_VERSION,
		slots = slots,
		wheelSize = Database.LIMITS.wheelSize.default,
		iconScale = Database.LIMITS.iconScale.default,
		showLabels = true,
		position = "CURSOR",
		mode = "CLICK",
		tipShown = false,
	}
end
Database.CopyDefaults = CopyDefaults

local function ValidToken(token)
	return type(token) == "string" and #token > 0 and #token <= 64 and token:match("^[A-Z0-9_]+$") ~= nil
end
Database.IsWellFormedToken = ValidToken

local function ClampNumber(value, limit)
	if type(value) ~= "number" or value ~= value then
		return limit.default
	end
	if value < limit.min then
		return limit.min
	end
	if value > limit.max then
		return limit.max
	end
	return value
end

-- Migration steps: MIGRATIONS[n] upgrades a table from schema n to n+1 in place.
-- Schema 0 means "no schemaVersion field" (pre-release or hand-edited data).
local MIGRATIONS = {
	[0] = function(db)
		-- Accept a bare list of tokens: { "WAVE", "BOW", ... }.
		if type(db.slots) == "table" then
			for i = 1, Database.SLOT_COUNT do
				if type(db.slots[i]) == "string" then
					db.slots[i] = { token = db.slots[i] }
				end
			end
		end
		db.schemaVersion = 1
	end,
}
Database.MIGRATIONS = MIGRATIONS

-- Validates and repairs a stored table.
--   stored        value loaded from SavedVariables (may be nil or malformed).
--   isIconKey     optional predicate for per-slot icon override keys.
-- Returns db, report where report = { reset = bool, repaired = { ... } }.
-- Unknown-but-well-formed emote tokens are preserved; the runtime catalog marks
-- them unavailable instead of discarding the player's choice.
function Database.Load(stored, isIconKey)
	local report = { reset = false, repaired = {} }
	if type(stored) ~= "table" then
		report.reset = stored ~= nil
		return CopyDefaults(), report
	end

	local db = stored
	local version = db.schemaVersion
	if type(version) ~= "number" or version ~= version or version < 0 or version % 1 ~= 0 then
		version = 0
	end
	while version < Database.SCHEMA_VERSION do
		local step = MIGRATIONS[version]
		if not step then
			report.reset = true
			return CopyDefaults(), report
		end
		local ok = pcall(step, db)
		if not ok then
			report.reset = true
			return CopyDefaults(), report
		end
		version = version + 1
		db.schemaVersion = version
	end
	-- A newer schema (downgraded addon) is kept as-is apart from field repair, so
	-- upgrading again does not lose data.

	if type(db.slots) ~= "table" then
		db.slots = CopyDefaults().slots
		table.insert(report.repaired, "slots")
	end
	for i = 1, Database.SLOT_COUNT do
		local slot = db.slots[i]
		if type(slot) ~= "table" then
			db.slots[i] = {}
			if slot ~= nil then
				table.insert(report.repaired, "slot" .. i)
			end
		else
			if slot.token ~= nil and not ValidToken(slot.token) then
				slot.token = nil
				table.insert(report.repaired, "slot" .. i .. ".token")
			end
			if slot.icon ~= nil and (type(slot.icon) ~= "string" or (isIconKey and not isIconKey(slot.icon))) then
				slot.icon = nil
				table.insert(report.repaired, "slot" .. i .. ".icon")
			end
		end
	end
	for k in pairs(db.slots) do
		if type(k) ~= "number" or k < 1 or k > Database.SLOT_COUNT or k % 1 ~= 0 then
			db.slots[k] = nil
		end
	end

	local size = ClampNumber(db.wheelSize, Database.LIMITS.wheelSize)
	if size ~= db.wheelSize then
		table.insert(report.repaired, "wheelSize")
	end
	db.wheelSize = size

	local scale = ClampNumber(db.iconScale, Database.LIMITS.iconScale)
	if scale ~= db.iconScale then
		table.insert(report.repaired, "iconScale")
	end
	db.iconScale = scale

	if type(db.showLabels) ~= "boolean" then
		db.showLabels = true
	end
	if not Database.POSITIONS[db.position] then
		db.position = "CURSOR"
	end
	if not Database.MODES[db.mode] then
		db.mode = "CLICK"
	end
	if type(db.tipShown) ~= "boolean" then
		db.tipShown = false
	end
	return db, report
end

-- Resets everything to defaults in place (keeps the same table reference).
function Database.Reset(db)
	for k in pairs(db) do
		db[k] = nil
	end
	for k, v in pairs(CopyDefaults()) do
		db[k] = v
	end
	return db
end
