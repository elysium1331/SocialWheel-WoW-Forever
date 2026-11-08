local H = ...
local ns = H.load("WheelMath.lua", {})
local M = ns.WheelMath
local test, eq = H.test, H.eq

local function at(angleDeg, dist)
	local r = math.rad(angleDeg)
	return dist * math.sin(r), dist * math.cos(r)
end

test("slot centers map to their own slot, top first, clockwise", function()
	for i = 1, 6 do
		local dx, dy = at((i - 1) * 60, 100)
		eq(M.SelectSlot(dx, dy, 30), i, "slot " .. i)
	end
end)

test("straight up is slot 1, right side is slots 2-3, left side 5-6", function()
	eq(M.SelectSlot(0, 100, 30), 1)
	eq(M.SelectSlot(100, 10, 30), 2) -- just above horizontal right (~84 deg)
	eq(M.SelectSlot(100, -10, 30), 3)
	eq(M.SelectSlot(0, -100, 30), 4)
	eq(M.SelectSlot(-100, -10, 30), 5)
	eq(M.SelectSlot(-100, 10, 30), 6)
end)

test("wraparound near 360 degrees selects slot 1", function()
	local dx, dy = at(359, 100)
	eq(M.SelectSlot(dx, dy, 30), 1)
	dx, dy = at(331, 100)
	eq(M.SelectSlot(dx, dy, 30), 1)
	dx, dy = at(329, 100)
	eq(M.SelectSlot(dx, dy, 30), 6)
end)

test("sector boundaries are stable and belong to the clockwise-next slot", function()
	eq(M.SlotForAngle(30), 2)
	eq(M.SlotForAngle(29.999), 1)
	eq(M.SlotForAngle(330), 1)
	eq(M.SlotForAngle(329.999), 6)
	eq(M.SlotForAngle(0), 1)
end)

test("dead zone returns nil", function()
	eq(M.SelectSlot(0, 0, 30), nil)
	eq(M.SelectSlot(10, 10, 30), nil)
	eq(M.SelectSlot(0, 29.9, 30), nil)
	eq(M.SelectSlot(0, 30, 30), 1)
end)

test("NaN input selects nothing", function()
	local nan = 0 / 0
	eq(M.SelectSlot(nan, 5, 10), nil)
end)

test("hysteresis keeps the current slot just past a boundary", function()
	local dx, dy = at(33, 100) -- 3 degrees into slot 2
	eq(M.SelectSlot(dx, dy, 30, 1, 6), 1)
	dx, dy = at(37, 100) -- 7 degrees in: moves
	eq(M.SelectSlot(dx, dy, 30, 1, 6), 2)
	dx, dy = at(327, 100) -- wraps: 3 degrees into slot 6 while on slot 1
	eq(M.SelectSlot(dx, dy, 30, 1, 6), 1)
	-- no hysteresis without a current slot
	dx, dy = at(33, 100)
	eq(M.SelectSlot(dx, dy, 30, nil, 6), 2)
end)

test("slot offsets put slot 1 on top and slot 2 to the upper right", function()
	local x, y = M.SlotOffset(1, 100)
	eq(math.floor(x + 0.5), 0)
	eq(math.floor(y + 0.5), 100)
	x, y = M.SlotOffset(2, 100)
	H.truthy(x > 0 and y > 0, "slot 2 upper right")
	x, y = M.SlotOffset(4, 100)
	eq(math.floor(y + 0.5), -100)
end)

test("clamp keeps the wheel on screen and centers when too large", function()
	local x, y = M.ClampCenter(5, 5, 100, 1000, 800)
	eq(x, 100)
	eq(y, 100)
	x, y = M.ClampCenter(990, 790, 100, 1000, 800)
	eq(x, 900)
	eq(y, 700)
	x, y = M.ClampCenter(500, 400, 100, 1000, 800)
	eq(x, 500)
	eq(y, 400)
	x, y = M.ClampCenter(10, 10, 300, 500, 400)
	eq(x, 250)
	eq(y, 200)
end)
