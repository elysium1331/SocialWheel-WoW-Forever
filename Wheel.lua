-- The radial wheel: a reusable view (also used by the configuration preview)
-- and the controller that opens, tracks selection, performs and closes.
--
-- Input model:
--   * A transparent click-catcher covering UIParent is shown only while the
--     wheel is open. It takes mouse clicks (left = perform, right = cancel) but
--     not the keyboard, so movement keys keep working. Mouse wheel is not taken.
--   * Selection is updated in an OnUpdate script that exists only while open.
--   * Escape closes through UISpecialFrames; the key binding toggles.
local _, ns = ...

local L, Compat, WheelMath, Catalog, Icons = ns.L, ns.Compat, ns.WheelMath, ns.Catalog, ns.Icons

local Wheel = {}
ns.Wheel = Wheel

local GOLD = { 0.62, 0.52, 0.32, 1 }
local GOLD_BRIGHT = { 1.0, 0.82, 0.42, 1 }
local GOLD_DIM = { 0.36, 0.31, 0.22, 1 }
local DARK = { 0.05, 0.045, 0.04, 0.82 }
local SLOT_DARK = { 0.09, 0.08, 0.07, 0.95 }
local HIGHLIGHT_HYSTERESIS = 6

-- Shared view -----------------------------------------------------------------------

local function MakeDisc(parent, layer, sublevel, color)
	local tex = parent:CreateTexture(nil, layer, nil, sublevel)
	tex:SetColorTexture(color[1], color[2], color[3], color[4])
	local mask = parent:CreateMaskTexture()
	mask:SetTexture(Compat.CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetAllPoints(tex)
	tex:AddMaskTexture(mask)
	return tex
end

local function SetDiscColor(tex, color)
	tex:SetColorTexture(color[1], color[2], color[3], color[4])
end

local View = {}
View.__index = View

-- Creates a wheel view inside `parent`.
--   interactive: slots are buttons that call onSlotClick(index).
function Wheel.CreateView(parent, interactive, onSlotClick)
	local self = setmetatable({}, View)
	local root = CreateFrame("Frame", nil, parent)
	self.root = root

	self.rim = MakeDisc(root, "BACKGROUND", 0, GOLD_DIM)
	self.rim:SetPoint("CENTER")
	self.bg = MakeDisc(root, "BACKGROUND", 1, DARK)
	self.bg:SetPoint("CENTER")

	self.hubRim = MakeDisc(root, "BORDER", 0, GOLD_DIM)
	self.hubRim:SetPoint("CENTER")
	self.hub = MakeDisc(root, "BORDER", 1, SLOT_DARK)
	self.hub:SetPoint("CENTER")

	self.centerText = root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	self.centerText:SetPoint("CENTER")
	self.centerText:SetJustifyH("CENTER")
	self.centerText:SetWordWrap(true)

	self.slots = {}
	for i = 1, WheelMath.SLOT_COUNT do
		local slot = CreateFrame(interactive and "Button" or "Frame", nil, root)
		slot.index = i
		slot.glow = MakeDisc(slot, "BACKGROUND", 0, { GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3], 0.22 })
		slot.glow:SetPoint("CENTER")
		slot.glow:Hide()
		slot.ring = MakeDisc(slot, "BORDER", 0, GOLD)
		slot.ring:SetPoint("CENTER")
		slot.base = MakeDisc(slot, "BORDER", 1, SLOT_DARK)
		slot.base:SetPoint("CENTER")
		slot.icon = slot:CreateTexture(nil, "ARTWORK")
		slot.icon:SetPoint("CENTER")
		slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		local mask = slot:CreateMaskTexture()
		mask:SetTexture(Compat.CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		mask:SetAllPoints(slot.icon)
		slot.icon:AddMaskTexture(mask)
		slot.label = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		slot.label:SetJustifyH("CENTER")
		slot.number = slot:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		slot.number:SetText(i)
		slot.number:Hide()
		if interactive then
			slot:RegisterForClicks("LeftButtonUp")
			slot:SetScript("OnClick", function(btn)
				if onSlotClick then
					onSlotClick(btn.index)
				end
			end)
			slot:SetScript("OnEnter", function(btn)
				if not btn.selected then
					SetDiscColor(btn.ring, GOLD_BRIGHT)
				end
			end)
			slot:SetScript("OnLeave", function(btn)
				if not btn.selected then
					SetDiscColor(btn.ring, btn.ringColor or GOLD)
				end
			end)
		else
			slot:EnableMouse(false)
		end
		self.slots[i] = slot
	end
	return self
end

-- Sizes everything for a wheel diameter and icon scale.
function View:Layout(size, iconScale, showLabels)
	local slotSize = math.floor(size * 0.2 * iconScale + 0.5)
	slotSize = math.max(32, math.min(slotSize, math.floor(size * 0.3)))
	local radius = size / 2 - slotSize / 2 - 10
	self.size, self.slotSize, self.radius = size, slotSize, radius
	self.deadZone = math.floor(size * 0.17)
	self.showLabels = showLabels

	self.root:SetSize(size, size)
	self.rim:SetSize(size, size)
	self.bg:SetSize(size - 4, size - 4)
	self.hubRim:SetSize(self.deadZone * 2 + 2, self.deadZone * 2 + 2)
	self.hub:SetSize(self.deadZone * 2, self.deadZone * 2)
	self.centerText:SetWidth(size * 0.42)

	for i, slot in ipairs(self.slots) do
		local x, y = WheelMath.SlotOffset(i, radius)
		slot:SetSize(slotSize, slotSize)
		slot:ClearAllPoints()
		slot:SetPoint("CENTER", self.root, "CENTER", x, y)
		slot.glow:SetSize(slotSize + 14, slotSize + 14)
		slot.ring:SetSize(slotSize + 4, slotSize + 4)
		slot.base:SetSize(slotSize, slotSize)
		slot.icon:SetSize(slotSize - 6, slotSize - 6)
		slot.label:ClearAllPoints()
		slot.label:SetWidth(slotSize + 36)
		slot.number:ClearAllPoints()
		if i == 4 then
			slot.label:SetPoint("BOTTOM", slot, "TOP", 0, 2)
		else
			slot.label:SetPoint("TOP", slot, "BOTTOM", 0, -2)
		end
		slot.number:SetPoint("TOPLEFT", slot, "TOPLEFT", -2, 2)
		slot.label:SetShown(showLabels)
	end
end

-- Pulls slot contents from saved settings.
function View:Refresh(db)
	for i, slot in ipairs(self.slots) do
		local data = db.slots[i]
		local token = data and data.token
		local entry = token and Catalog.Get(token)
		slot.token, slot.entry = token, entry
		slot.icon:SetDesaturated(false)
		slot.icon:SetVertexColor(1, 1, 1, 1)
		if not token then
			slot.icon:Hide()
			slot.ringColor = GOLD_DIM
			slot.label:SetText(L.EMPTY_SLOT)
			slot.label:SetTextColor(0.55, 0.55, 0.55)
			slot.displayName = L.EMPTY_SLOT
		else
			local path = Icons.Resolve(token, entry, data.icon)
			if path then
				slot.icon:SetTexture(path)
				Icons.ApplyTexCoord(slot.icon, path)
			else
				slot.icon:SetColorTexture(0.30, 0.25, 0.16, 1)
			end
			slot.icon:Show()
			if entry then
				slot.ringColor = GOLD
				slot.label:SetText(entry.name)
				slot.label:SetTextColor(0.95, 0.93, 0.86)
				slot.displayName = entry.name
			else
				slot.icon:SetDesaturated(true)
				slot.icon:SetVertexColor(0.6, 0.6, 0.6, 1)
				slot.ringColor = GOLD_DIM
				slot.label:SetText(L.UNAVAILABLE)
				slot.label:SetTextColor(0.85, 0.45, 0.4)
				slot.displayName = L.UNAVAILABLE .. " (" .. token .. ")"
			end
		end
		SetDiscColor(slot.ring, slot.ringColor)
		slot.glow:Hide()
		slot.selected = false
	end
	self:SetHighlight(self.highlight)
end

-- Highlights one slot (or none) and updates the center text.
function View:SetHighlight(index)
	self.highlight = index
	for i, slot in ipairs(self.slots) do
		local on = i == index
		slot.selected = on
		slot.glow:SetShown(on)
		SetDiscColor(slot.ring, on and GOLD_BRIGHT or (slot.ringColor or GOLD))
	end
	local slot = index and self.slots[index]
	if slot then
		self.centerText:SetFontObject("GameFontNormal")
		self.centerText:SetText(slot.displayName or "")
	else
		self.centerText:SetFontObject("GameFontDisableSmall")
		self.centerText:SetText(self.idleText or L.CHOOSE_EMOTE)
	end
end

function View:ShowSlotNumbers(shown)
	for _, slot in ipairs(self.slots) do
		slot.number:SetShown(shown)
	end
end

-- Controller -------------------------------------------------------------------------

local catcher, view, fadeIn
local isOpen = false
local keyDown = false
local openedByKey = false
local centerX, centerY = 0, 0

local function OnUpdate()
	if Compat.HasKeyboardFocus() then
		Wheel.Cancel() -- player started typing; never act on a stale wheel
		return
	end
	local x, y = Compat.GetCursorInFrameSpace(catcher)
	local selected = WheelMath.SelectSlot(x - centerX, y - centerY, view.deadZone, view.highlight, HIGHLIGHT_HYSTERESIS)
	if selected ~= view.highlight then
		view:SetHighlight(selected)
	end
end

local function Cleanup()
	isOpen = false
	openedByKey = false
	if catcher then
		catcher:SetScript("OnUpdate", nil)
	end
	if view then
		view.highlight = nil
	end
end

local function EnsureFrames()
	if catcher then
		return
	end
	catcher = CreateFrame("Frame", "SocialWheelCatcher", UIParent)
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata("DIALOG")
	catcher:EnableMouse(true)
	catcher:Hide()
	catcher:SetScript("OnMouseDown", function(_, button)
		if button == "LeftButton" then
			Wheel.Commit()
		elseif button == "RightButton" then
			Wheel.Cancel()
			if IsShiftKeyDown and IsShiftKeyDown() then
				ns.Settings.Open()
			end
		end
	end)
	-- Any hide (Escape, UI hidden, loading screen) cleans up without performing.
	catcher:SetScript("OnHide", Cleanup)
	Compat.RegisterEscapeClose("SocialWheelCatcher")

	view = Wheel.CreateView(catcher, false)
	view.root:SetFrameLevel(catcher:GetFrameLevel() + 5)
	view.hint = view.root:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	view.hint:SetPoint("TOP", view.root, "BOTTOM", 0, -4)
	view.hint:SetText(L.WHEEL_HINT)
	fadeIn = view.root:CreateAnimationGroup()
	local alpha = fadeIn:CreateAnimation("Alpha")
	alpha:SetFromAlpha(0)
	alpha:SetToAlpha(1)
	alpha:SetDuration(0.08)
end

local function PlaceWheel(db)
	local w, h = catcher:GetWidth(), catcher:GetHeight()
	local cx, cy
	if db.position == "SCREEN" or Compat.IsMouselooking() then
		cx, cy = w / 2, h / 2
	else
		cx, cy = Compat.GetCursorInFrameSpace(catcher)
	end
	-- Extra margin keeps outer labels on screen.
	cx, cy = WheelMath.ClampCenter(cx, cy, db.wheelSize / 2 + 24, w, h)
	centerX, centerY = cx, cy
	view.root:ClearAllPoints()
	view.root:SetPoint("CENTER", catcher, "BOTTOMLEFT", cx, cy)
end

function Wheel.IsOpen()
	return isOpen
end

function Wheel.Open(fromKey)
	local db = ns.db
	if isOpen or not db or Compat.HasKeyboardFocus() then
		return
	end
	EnsureFrames()
	view:Layout(db.wheelSize, db.iconScale, db.showLabels)
	view.highlight = nil
	view:Refresh(db)
	PlaceWheel(db)
	isOpen = true
	openedByKey = fromKey and true or false
	catcher:Show()
	catcher:SetScript("OnUpdate", OnUpdate)
	fadeIn:Stop()
	fadeIn:Play()
end

-- Closes without performing anything.
function Wheel.Cancel()
	if catcher and catcher:IsShown() then
		catcher:Hide() -- OnHide -> Cleanup
	else
		Cleanup()
	end
end

-- Performs the highlighted slot once (if any) and closes. The wheel is closed
-- before the emote is attempted so no second click can reach it.
function Wheel.Commit()
	if not isOpen then
		return
	end
	local index = view and view.highlight
	Wheel.Cancel()
	if index then
		ns.PerformSlot(index)
	end
end

function Wheel.Toggle()
	if isOpen then
		Wheel.Cancel()
	else
		Wheel.Open(false)
	end
end

function Wheel.ResetKeyState()
	keyDown = false
end

-- Binding handler. Bindings.xml uses runOnUp, so both states arrive here.
function Wheel.OnBinding(keystate)
	local db = ns.db
	if not db then
		return
	end
	if keystate == "down" then
		if keyDown then
			return -- auto-repeat or a duplicate handler: ignore
		end
		keyDown = true
		if isOpen then
			Wheel.Cancel() -- pressing the key again cancels
		else
			Wheel.Open(true)
		end
	else
		local wasDown = keyDown
		keyDown = false
		if wasDown and isOpen and openedByKey and db.mode == "HOLD" then
			Wheel.Commit() -- release: perform highlight, or cancel in the dead zone
		end
	end
end

-- Re-render an open wheel after settings change.
function Wheel.RefreshIfOpen()
	if isOpen and ns.db then
		view:Layout(ns.db.wheelSize, ns.db.iconScale, ns.db.showLabels)
		view:Refresh(ns.db)
		PlaceWheel(ns.db)
	end
end
