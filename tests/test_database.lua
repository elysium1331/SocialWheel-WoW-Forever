local H = ...
local ns = H.load("Database.lua", {})
local D = ns.Database
local test, eq, truthy = H.test, H.eq, H.truthy

local function isIcon(key)
	return key == "hand" or key == "note"
end

test("nil saved variables give defaults without a reset warning", function()
	local db, report = D.Load(nil, isIcon)
	eq(report.reset, false)
	eq(db.schemaVersion, D.SCHEMA_VERSION)
	eq(db.slots[1].token, "HELLO")
	eq(db.slots[2].token, "THANK")
	eq(db.slots[3].token, "WAVE")
	eq(db.slots[4].token, "POINT")
	eq(db.slots[5].token, "LAUGH")
	eq(db.slots[6].token, "CHEER")
	eq(db.mode, "CLICK")
	eq(db.position, "CURSOR")
	eq(db.showLabels, true)
	eq(db.tipShown, false)
end)

test("malformed non-table data is replaced and reported", function()
	local db, report = D.Load("garbage", isIcon)
	eq(report.reset, true)
	eq(db.slots[1].token, "HELLO")
end)

test("existing choices survive validation", function()
	local stored = {
		schemaVersion = 1,
		slots = { { token = "BOW", icon = "hand" }, {}, { token = "DANCE" }, { token = "WAVE" }, { token = "CRY" }, { token = "SALUTE" } },
		wheelSize = 300, iconScale = 1.2, showLabels = false, position = "SCREEN", mode = "HOLD",
	}
	local db = D.Load(stored, isIcon)
	eq(db, stored, "same table is kept")
	eq(db.slots[1].token, "BOW")
	eq(db.slots[1].icon, "hand")
	eq(db.slots[2].token, nil, "empty slot stays empty")
	eq(db.wheelSize, 300)
	eq(db.iconScale, 1.2)
	eq(db.showLabels, false)
	eq(db.position, "SCREEN")
	eq(db.mode, "HOLD")
end)

test("invalid fields are repaired individually", function()
	local stored = {
		schemaVersion = 1,
		slots = { { token = "bad token!" }, "x", { token = "WAVE", icon = "nope" }, nil, { token = 42 }, { token = "CHEER" }, [9] = { token = "X" }, foo = 1 },
		wheelSize = 5000, iconScale = "big", showLabels = "yes", position = "LEFT", mode = 3,
	}
	local db, report = D.Load(stored, isIcon)
	eq(report.reset, false)
	eq(db.slots[1].token, nil)
	eq(type(db.slots[2]), "table")
	eq(db.slots[2].token, nil)
	eq(db.slots[3].token, "WAVE")
	eq(db.slots[3].icon, nil)
	eq(type(db.slots[4]), "table")
	eq(db.slots[5].token, nil)
	eq(db.slots[6].token, "CHEER")
	eq(db.slots[9], nil)
	eq(db.slots.foo, nil)
	eq(db.wheelSize, D.LIMITS.wheelSize.max)
	eq(db.iconScale, D.LIMITS.iconScale.default)
	eq(db.showLabels, true)
	eq(db.position, "CURSOR")
	eq(db.mode, "CLICK")
	truthy(#report.repaired > 0)
end)

test("unknown but well-formed tokens are preserved", function()
	local db = D.Load({ schemaVersion = 1, slots = { { token = "FUTUREEMOTE" } } }, isIcon)
	eq(db.slots[1].token, "FUTUREEMOTE")
end)

test("schema 0 (no version) migrates bare token lists", function()
	local db, report = D.Load({ slots = { "WAVE", "BOW" } }, isIcon)
	eq(report.reset, false)
	eq(db.schemaVersion, 1)
	eq(db.slots[1].token, "WAVE")
	eq(db.slots[2].token, "BOW")
	eq(type(db.slots[3]), "table")
end)

test("a newer schema is kept rather than wiped", function()
	local db = D.Load({ schemaVersion = 99, slots = { { token = "WAVE" } }, futureField = true }, isIcon)
	eq(db.schemaVersion, 99)
	eq(db.futureField, true)
	eq(db.slots[1].token, "WAVE")
end)

test("a failing migration falls back to defaults", function()
	local original = D.MIGRATIONS[0]
	D.MIGRATIONS[0] = function() error("boom") end
	local db, report = D.Load({ slots = {} }, isIcon)
	D.MIGRATIONS[0] = original
	eq(report.reset, true)
	eq(db.slots[1].token, "HELLO")
end)

test("reset restores defaults in place", function()
	local db = D.Load({ schemaVersion = 1, slots = { { token = "BOW" } }, mode = "HOLD" }, isIcon)
	local same = D.Reset(db)
	eq(same, db)
	eq(db.slots[1].token, "HELLO")
	eq(db.mode, "CLICK")
end)

test("tip flag is added to older saved data and kept once set", function()
	local db = D.Load({ schemaVersion = 1, slots = {} }, isIcon)
	eq(db.tipShown, false)
	db.tipShown = true
	db = D.Load(db, isIcon)
	eq(db.tipShown, true)
end)
