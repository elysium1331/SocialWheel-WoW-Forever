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

local L, Compat, WheelMath, Catalog, Icons, Art = ns.L, ns.Compat, ns.WheelMath, ns.Catalog, ns.Icons, ns.Art

local Wheel = {}
ns.Wheel = Wheel

-- Vertex tints for the gold slot frame (multiplied with the texture). The frame
-- art is shared with [Elysium] ProfessionWheel.
local FRAME_NORMAL = { 0.88, 0.88, 0.88 }
local FRAME_SELECTED = { 1, 1, 1 }
local FRAME_DIM = { 0.5, 0.5, 0.5 }
local SLOT_DARK = { 0.07, 0.06, 0.05, 1 }
local HIGHLIGHT_HYSTERESIS = 6

-- Shared view -----------------------------------------------------------------------

local function Tint(tex, c)
	tex:SetVertexColor(c[1], c[2], c[3], 1)
end

local function CircleMask(owner, tex)
	local mask = owner:CreateMaskTexture()
	mask:SetTexture(Compat.CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetAllPoints(tex)
	tex:AddMaskTexture(mask)
end

local View = {}
View.__index = View

-- Creates a wheel view inside `parent`.
--   interactive: slots are buttons that call onSlotClick(index).
--   showInfo:    show the highlighted emote's name on a plate under the wheel.
function Wheel.CreateView(parent, interactive, onSlotClick, showInfo)
	local self = setmetatable({ showInfo = showInfo }, View)
	local root = CreateFrame("Frame", nil, parent)
	self.root = root

	self.disc = root:CreateTexture(nil, "BACKGROUND", nil, 0)
	self.disc:SetTexture(Art.DISC)
	self.disc:SetAllPoints(root)

	self.spokes, self.stars = {}, {}
	for i = 1, WheelMath.SLOT_COUNT do
		local spoke = root:CreateTexture(nil, "BORDER", nil, 0)
		spoke:SetTexture(Art.SPOKE)
		self.spokes[i] = spoke
		local star = root:CreateTexture(nil, "BORDER", nil, 1)
		star:SetTexture(Art.STAR)
		self.stars[i] = star
	end

	self.hubGlow = root:CreateTexture(nil, "ARTWORK", nil, 0)
	self.hubGlow:SetTexture(Art.HUB_GLOW)
	self.hubGlow:SetBlendMode("ADD")
	self.hubGlow:SetPoint("CENTER")
	self.hub = root:CreateTexture(nil, "ARTWORK", nil, 1)
	self.hub:SetTexture(Art.HUB)
	self.hub:SetPoint("CENTER")
	self.hub:SetVertexColor(0.8, 0.8, 0.8, 1)

	self.slots = {}
	for i = 1, WheelMath.SLOT_COUNT do
		local slot = CreateFrame(interactive and "Button" or "Frame", nil, root)
		slot.index = i
		slot.glow = slot:CreateTexture(nil, "BACKGROUND", nil, 0)
		slot.glow:SetTexture(Art.SLOT_GLOW)
		slot.glow:SetBlendMode("ADD")
		slot.glow:SetPoint("CENTER")
		slot.glow:Hide()
		slot.base = slot:CreateTexture(nil, "BORDER", nil, 0)
		slot.base:SetColorTexture(SLOT_DARK[1], SLOT_DARK[2], SLOT_DARK[3], SLOT_DARK[4])
		slot.base:SetPoint("CENTER")
		CircleMask(slot, slot.base)
		slot.icon = slot:CreateTexture(nil, "ARTWORK")
		slot.icon:SetPoint("CENTER")
		CircleMask(slot, slot.icon)
		slot.frame = slot:CreateTexture(nil, "OVERLAY", nil, 0)
		slot.frame:SetTexture(Art.SLOT)
		slot.frame:SetAllPoints(slot)
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
					Tint(btn.frame, FRAME_SELECTED)
				end
			end)
			slot:SetScript("OnLeave", function(btn)
				if not btn.selected then
					Tint(btn.frame, btn.frameTint or FRAME_NORMAL)
				end
			end)
		else
			slot:EnableMouse(false)
		end
		self.slots[i] = slot
	end

	if showInfo then
		self.infoText = root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.infoText:SetPoint("TOP", root, "BOTTOM", 0, -10)
		self.infoText:SetJustifyH("CENTER")
		self.infoBg = root:CreateTexture(nil, "BACKGROUND", nil, -1)
		self.infoBg:SetColorTexture(0, 0, 0, 0.6)
		self.infoBg:SetPoint("TOPLEFT", self.infoText, "TOPLEFT", -10, 5)
		self.infoBg:SetPoint("BOTTOMRIGHT", self.infoText, "BOTTOMRIGHT", 10, -5)
	end
	return self
end

-- Sizes everything for a wheel diameter and icon scale (same proportions as
-- ProfessionWheel).
function View:Layout(size, iconScale, showLabels)
	local slotSize = math.floor(size * 0.24 * iconScale + 0.5)
	slotSize = math.max(32, math.min(slotSize, math.floor(size * 0.29)))
	local radius = size / 2 - slotSize / 2 - size * 0.06
	self.size, self.slotSize, self.radius = size, slotSize, radius
	self.deadZone = math.floor(size * 0.17)
	self.showLabels = showLabels

	self.root:SetSize(size, size)
	local hub = math.floor(size * 0.18)
	self.hub:SetSize(hub, hub)
	self.hubGlow:SetSize(hub * 1.8, hub * 1.8)

	local sector = WheelMath.SECTOR
	for i = 1, WheelMath.SLOT_COUNT do
		-- The spoke art is a horizontal bar spanning 90% of a square texture; it
		-- runs from the center to the slot, under both.
		local spoke = self.spokes[i]
		local len = radius / 0.9
		local x, y = WheelMath.SlotOffset(i, radius / 2)
		spoke:SetSize(len, len)
		spoke:ClearAllPoints()
		spoke:SetPoint("CENTER", self.root, "CENTER", x, y)
		spoke:SetRotation(math.rad(90 - (i - 1) * sector))
		local star = self.stars[i]
		local starAngle = math.rad((i - 0.5) * sector)
		local starRadius = radius + slotSize * 0.05
		star:SetSize(slotSize * 0.3, slotSize * 0.3)
		star:ClearAllPoints()
		star:SetPoint("CENTER", self.root, "CENTER", starRadius * math.sin(starAngle), starRadius * math.cos(starAngle))
	end

	for i, slot in ipairs(self.slots) do
		local x, y = WheelMath.SlotOffset(i, radius)
		slot:SetSize(slotSize, slotSize)
		slot:ClearAllPoints()
		slot:SetPoint("CENTER", self.root, "CENTER", x, y)
		slot.glow:SetSize(slotSize * 1.5, slotSize * 1.5)
		slot.base:SetSize(slotSize * 0.88, slotSize * 0.88)
		slot.label:ClearAllPoints()
		slot.label:SetWidth(slotSize + 36)
		slot.number:ClearAllPoints()
		if i == 4 then
			slot.label:SetPoint("BOTTOM", slot, "TOP", 0, 1)
		else
			slot.label:SetPoint("TOP", slot, "BOTTOM", 0, -1)
		end
		slot.number:SetPoint("TOPLEFT", slot, "TOPLEFT", -2, 2)
		slot.label:SetShown(showLabels)
	end
end

-- Pulls slot contents from saved settings.
function View:Refresh(db)
	local slotSize = self.slotSize or 56
	for i, slot in ipairs(self.slots) do
		local data = db.slots[i]
		local token = data and data.token
		local entry = token and Catalog.Get(token)
		slot.token, slot.entry = token, entry
		slot.icon:SetDesaturated(false)
		slot.icon:SetVertexColor(1, 1, 1, 1)
		if not token then
			slot.icon:Hide()
			slot.frameTint = FRAME_DIM
			slot.label:SetText(L.EMPTY_SLOT)
			slot.label:SetTextColor(0.55, 0.55, 0.55)
			slot.displayName = L.EMPTY_SLOT
		else
			local path = Icons.Resolve(token, entry, data.icon)
			if path then
				slot.icon:SetTexture(path)
				Icons.ApplyTexCoord(slot.icon, path)
				-- Painted icons carry their own margin; square game icons are
				-- cropped a little tighter.
				local scale = Icons.IsBundled(path) and 0.84 or 0.8
				slot.icon:SetSize(slotSize * scale, slotSize * scale)
			else
				slot.icon:SetColorTexture(0.30, 0.25, 0.16, 1)
				slot.icon:SetSize(slotSize * 0.8, slotSize * 0.8)
			end
			slot.icon:Show()
			if entry then
				slot.frameTint = FRAME_NORMAL
				slot.label:SetText(entry.name)
				slot.label:SetTextColor(0.95, 0.9, 0.78)
				slot.displayName = entry.name
			else
				slot.icon:SetDesaturated(true)
				slot.icon:SetVertexColor(0.6, 0.6, 0.6, 1)
				slot.frameTint = FRAME_DIM
				slot.label:SetText(L.UNAVAILABLE)
				slot.label:SetTextColor(0.85, 0.45, 0.4)
				slot.displayName = L.UNAVAILABLE .. " (" .. token .. ")"
			end
		end
		Tint(slot.frame, slot.frameTint)
		slot.glow:Hide()
		slot.selected = false
	end
	self:SetHighlight(self.highlight)
end

-- Highlights one slot (or none) and updates the name under the wheel.
function View:SetHighlight(index)
	self.highlight = index
	for i, slot in ipairs(self.slots) do
		local on = i == index
		slot.selected = on
		slot.glow:SetShown(on)
		Tint(slot.frame, on and FRAME_SELECTED or (slot.frameTint or FRAME_NORMAL))
	end
	self.hubGlow:SetAlpha(index and 0.75 or 0.45)
	if not self.infoText then
		return
	end
	local slot = index and self.slots[index]
	if slot then
		self.infoText:SetFontObject("GameFontNormal")
		self.infoText:SetText(slot.displayName or "")
	else
		self.infoText:SetFontObject("GameFontDisable")
		self.infoText:SetText(self.idleText or L.CHOOSE_EMOTE)
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

	view = Wheel.CreateView(catcher, false, nil, true)
	view.root:SetFrameLevel(catcher:GetFrameLevel() + 5)
	view.hint = view.root:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	view.hint:SetPoint("TOP", view.infoText, "BOTTOM", 0, -10)
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
	cx, cy = WheelMath.ClampCenter(cx, cy, db.wheelSize / 2 + 56, w, h)
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
