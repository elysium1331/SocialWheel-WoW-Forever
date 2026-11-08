-- Configuration window (/socialwheel) and the Options > AddOns entry.
local _, ns = ...

local L, Compat, Database, Catalog, Icons, Wheel = ns.L, ns.Compat, ns.Database, ns.Catalog, ns.Icons, ns.Wheel

local SettingsUI = {}
ns.Settings = SettingsUI

local PREVIEW_SIZE = 280
local ROW_HEIGHT = 26

local frame, preview, scrollBox, searchBox, countText, detailText, editingText
local filterButtons, iconButtons = {}, {}
local controls = {}
local state = { editing = 1, selectedToken = nil, filter = Catalog.FILTER_ALL, query = "" }
local pendingKeybindings = false

local function RefreshWheels()
	if preview then
		preview:Layout(PREVIEW_SIZE, ns.db.iconScale, ns.db.showLabels)
		preview:Refresh(ns.db)
		preview:SetHighlight(state.editing)
	end
	Wheel.RefreshIfOpen()
end

local function YesUnknown(v)
	return v == "yes" and L.YES or L.UNKNOWN
end

local function UpdateDetail()
	local slot = ns.db.slots[state.editing]
	local name = slot.token and (Catalog.GetDisplayName(slot.token) or (L.UNAVAILABLE .. " (" .. slot.token .. ")")) or L.EMPTY_SLOT
	editingText:SetText(L.CONFIG_EDITING:format(state.editing, name))

	local entry = state.selectedToken and Catalog.Get(state.selectedToken)
	if entry then
		local commands = #entry.aliases > 0 and table.concat(entry.aliases, ", ") or "-"
		detailText:SetText(("|cffffd200%s|r\n%s\n%s\n%s  -  %s"):format(
			entry.name,
			L.DETAIL_COMMANDS:format(commands),
			L.DETAIL_TOKEN:format(entry.token),
			L.DETAIL_ANIMATION:format(YesUnknown(entry.animation)),
			L.DETAIL_VOICE:format(YesUnknown(entry.voice))))
		controls.assign:Enable()
	else
		detailText:SetText("")
		controls.assign:Disable()
	end

	for key, button in pairs(iconButtons) do
		button.selected:SetShown(slot.icon == key)
	end
	controls.auto.selected:SetShown(slot.icon == nil)
end

local function UpdateOptions()
	local db = ns.db
	controls.sizeValue:SetText(tostring(db.wheelSize))
	controls.scaleValue:SetText(("%.1f"):format(db.iconScale))
	controls.labels:SetChecked(db.showLabels)
	controls.posCursor:SetChecked(db.position == "CURSOR")
	controls.posScreen:SetChecked(db.position == "SCREEN")
	controls.modeClick:SetChecked(db.mode == "CLICK")
	controls.modeHold:SetChecked(db.mode == "HOLD")
	local key = Compat.GetBindingText("SOCIALWHEEL_OPEN")
	if key then
		controls.keyText:SetText(L.CURRENT_KEY:format("|cffffffff" .. key .. "|r"))
	else
		controls.keyText:SetText(L.CURRENT_KEY:format("|cffff6060" .. L.NOT_BOUND .. "|r"))
	end
end

local function RefreshList()
	if not scrollBox or not Catalog.current then
		return
	end
	local results = Catalog.Filter(Catalog.current, state.filter, state.query, Compat.GetPlayerFaction())
	scrollBox:SetDataProvider(CreateDataProvider(results), ScrollBoxConstants and ScrollBoxConstants.RetainScrollPosition)
	countText:SetText(L.RESULTS:format(#results))
	for key, button in pairs(filterButtons) do
		if key == state.filter then
			button:LockHighlight()
		else
			button:UnlockHighlight()
		end
	end
end

local function RefreshAll()
	RefreshWheels()
	UpdateDetail()
	UpdateOptions()
	RefreshList()
end

local function AssignSelected()
	if not state.selectedToken or not Catalog.Get(state.selectedToken) then
		return
	end
	ns.db.slots[state.editing] = { token = state.selectedToken }
	RefreshWheels()
	UpdateDetail()
end

-- Widgets ------------------------------------------------------------------------------

local function Button(parent, text, width, onClick)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(width, 22)
	b:SetText(text)
	b:SetScript("OnClick", onClick)
	return b
end

local function Label(parent, text, template)
	local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
	fs:SetText(text)
	fs:SetJustifyH("LEFT")
	return fs
end

local function Check(parent, text, onClick)
	local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	c:SetSize(24, 24)
	c.label = Label(parent, text, "GameFontHighlightSmall")
	c.label:SetPoint("LEFT", c, "RIGHT", 2, 1)
	c:SetScript("OnClick", onClick)
	return c
end

local function Stepper(parent, label, x, y, onStep)
	local fs = Label(parent, label, "GameFontNormalSmall")
	fs:SetPoint("TOPLEFT", x, y)
	local minus = Button(parent, "-", 24, function() onStep(-1) end)
	minus:SetPoint("LEFT", fs, "RIGHT", 8, 0)
	local value = Label(parent, "", "GameFontHighlight")
	value:SetWidth(40)
	value:SetJustifyH("CENTER")
	value:SetPoint("LEFT", minus, "RIGHT", 2, 0)
	local plus = Button(parent, "+", 24, function() onStep(1) end)
	plus:SetPoint("LEFT", value, "RIGHT", 2, 0)
	return value
end

local function SelectedMark(button)
	local t = button:CreateTexture(nil, "OVERLAY")
	t:SetPoint("TOPLEFT", -2, 2)
	t:SetPoint("BOTTOMRIGHT", 2, -2)
	t:SetColorTexture(1, 0.82, 0.42, 0.45)
	t:SetDrawLayer("BACKGROUND")
	t:Hide()
	return t
end

local function InitRow(row, entry)
	if not row.name then
		row:SetHeight(ROW_HEIGHT)
		row.bg = row:CreateTexture(nil, "BACKGROUND")
		row.bg:SetAllPoints()
		row.icon = row:CreateTexture(nil, "ARTWORK")
		row.icon:SetSize(20, 20)
		row.icon:SetPoint("LEFT", 4, 0)
		row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		row.name = Label(row, "", "GameFontHighlight")
		row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
		row.tags = Label(row, "", "GameFontDisableSmall")
		row.tags:SetPoint("RIGHT", -6, 0)
		row.tags:SetJustifyH("RIGHT")
		local hl = row:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetColorTexture(1, 1, 1, 0.08)
		row:RegisterForClicks("LeftButtonUp")
		row:SetScript("OnClick", function(self)
			state.selectedToken = self.token
			UpdateDetail()
			scrollBox:ForEachFrame(function(other)
				if other.UpdateSelected then
					other:UpdateSelected()
				end
			end)
		end)
		row:SetScript("OnDoubleClick", function(self)
			state.selectedToken = self.token
			AssignSelected()
		end)
		function row:UpdateSelected()
			if self.token == state.selectedToken then
				self.bg:SetColorTexture(1, 0.82, 0.42, 0.18)
			else
				self.bg:SetColorTexture(0, 0, 0, 0)
			end
		end
	end
	row.token = entry.token
	row.name:SetText(entry.name)
	local tags = {}
	if entry.inEmotes then
		tags[#tags + 1] = L.TAG_EMOTE
	end
	if entry.inVoice then
		tags[#tags + 1] = L.TAG_VOICE
	end
	if #tags == 0 then
		tags[1] = L.TAG_TEXT
	end
	row.tags:SetText(table.concat(tags, " / ") .. "   " .. (entry.aliases[1] or ""))
	local path = Icons.Resolve(entry.token, entry, nil)
	if path then
		row.icon:SetTexture(path)
		Icons.ApplyTexCoord(row.icon, path)
	else
		row.icon:SetColorTexture(0.3, 0.25, 0.16, 1)
	end
	row:UpdateSelected()
end

local function Build()
	frame = CreateFrame("Frame", "SocialWheelConfigFrame", UIParent, "ButtonFrameTemplate")
	frame:SetSize(800, 640)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	if ButtonFrameTemplate_HidePortrait then
		ButtonFrameTemplate_HidePortrait(frame)
	end
	if frame.SetTitle then
		frame:SetTitle(L.CONFIG_TITLE .. "  " .. ns.version)
	end
	frame:Hide()
	Compat.RegisterEscapeClose("SocialWheelConfigFrame")

	-- Preview -------------------------------------------------------------------
	preview = Wheel.CreateView(frame, true, function(index)
		state.editing = index
		preview:SetHighlight(index)
		UpdateDetail()
	end)
	preview.idleText = L.CONFIG_PREVIEW_HINT
	preview.root:SetPoint("CENTER", frame, "TOPLEFT", 196, -236)
	preview:ShowSlotNumbers(true)

	editingText = Label(frame, "", "GameFontNormal")
	editingText:SetPoint("TOPLEFT", 20, -400)
	editingText:SetWidth(360)

	local iconLabel = Label(frame, L.ICON, "GameFontNormalSmall")
	iconLabel:SetPoint("TOPLEFT", 20, -428)
	for i, key in ipairs(Icons.CURATED_ORDER) do
		local b = CreateFrame("Button", nil, frame)
		b:SetSize(22, 22)
		local col, rowIndex = (i - 1) % 12, math.floor((i - 1) / 12)
		b:SetPoint("TOPLEFT", 60 + col * 25, -424 - rowIndex * 26)
		b.tex = b:CreateTexture(nil, "ARTWORK")
		b.tex:SetAllPoints()
		b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		local path = Icons.CuratedPath(key)
		if path then
			b.tex:SetTexture(path)
			Icons.ApplyTexCoord(b.tex, path)
		else
			b.tex:SetColorTexture(0.3, 0.25, 0.16, 1)
		end
		b.selected = SelectedMark(b)
		local hl = b:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetColorTexture(1, 1, 1, 0.2)
		b:SetScript("OnClick", function()
			local slot = ns.db.slots[state.editing]
			if slot.token then
				slot.icon = key
				RefreshWheels()
				UpdateDetail()
			end
		end)
		iconButtons[key] = b
	end
	controls.auto = Button(frame, L.ICON_AUTO, 110, function()
		ns.db.slots[state.editing].icon = nil
		RefreshWheels()
		UpdateDetail()
	end)
	controls.auto:SetPoint("TOPLEFT", 20, -488)
	controls.auto.selected = SelectedMark(controls.auto)
	controls.clear = Button(frame, L.CLEAR_SLOT, 110, function()
		ns.db.slots[state.editing] = {}
		RefreshWheels()
		UpdateDetail()
	end)
	controls.clear:SetPoint("LEFT", controls.auto, "RIGHT", 8, 0)

	-- Catalog -------------------------------------------------------------------
	local filters = {
		{ Catalog.FILTER_ALL, L.FILTER_ALL },
		{ Catalog.FILTER_EMOTES, L.FILTER_EMOTES },
		{ Catalog.FILTER_VOICE, L.FILTER_VOICE },
	}
	local prev
	for _, f in ipairs(filters) do
		local b = Button(frame, f[2], 116, function()
			state.filter = f[1]
			RefreshList()
		end)
		if prev then
			b:SetPoint("LEFT", prev, "RIGHT", 6, 0)
		else
			b:SetPoint("TOPLEFT", 400, -70)
		end
		filterButtons[f[1]] = b
		prev = b
	end

	searchBox = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
	searchBox:SetSize(360, 20)
	searchBox:SetPoint("TOPLEFT", 406, -100)
	if searchBox.Instructions then
		searchBox.Instructions:SetText(L.CONFIG_SEARCH)
	end
	searchBox:HookScript("OnTextChanged", function(self)
		state.query = self:GetText() or ""
		RefreshList()
	end)

	countText = Label(frame, "", "GameFontDisableSmall")
	countText:SetPoint("TOPLEFT", 402, -126)

	scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
	scrollBox:SetPoint("TOPLEFT", 400, -142)
	scrollBox:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 756, -404)
	local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
	scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 6, 0)
	scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 6, 0)
	local listView = CreateScrollBoxListLinearView()
	listView:SetElementExtent(ROW_HEIGHT)
	listView:SetElementInitializer("Button", InitRow)
	ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, listView)

	detailText = Label(frame, "", "GameFontHighlightSmall")
	detailText:SetPoint("TOPLEFT", 402, -412)
	detailText:SetWidth(370)
	detailText:SetSpacing(2)

	controls.assign = Button(frame, L.ASSIGN, 150, AssignSelected)
	controls.assign:SetPoint("TOPRIGHT", frame, "TOPLEFT", 774, -480)

	-- Options -------------------------------------------------------------------
	local divider = frame:CreateTexture(nil, "ARTWORK")
	divider:SetColorTexture(0.62, 0.52, 0.32, 0.5)
	divider:SetPoint("TOPLEFT", 16, -520)
	divider:SetPoint("TOPRIGHT", -16, -520)
	divider:SetHeight(1)

	local limits = Database.LIMITS
	controls.sizeValue = Stepper(frame, L.WHEEL_SIZE, 20, -536, function(dir)
		local l = limits.wheelSize
		ns.db.wheelSize = math.max(l.min, math.min(l.max, ns.db.wheelSize + dir * l.step))
		UpdateOptions()
		RefreshWheels()
	end)
	controls.scaleValue = Stepper(frame, L.ICON_SCALE, 250, -536, function(dir)
		local l = limits.iconScale
		local v = math.floor((ns.db.iconScale + dir * l.step) * 10 + 0.5) / 10
		ns.db.iconScale = math.max(l.min, math.min(l.max, v))
		UpdateOptions()
		RefreshWheels()
	end)
	controls.labels = Check(frame, L.SHOW_LABELS, function(self)
		ns.db.showLabels = self:GetChecked() and true or false
		RefreshWheels()
	end)
	controls.labels:SetPoint("TOPLEFT", 480, -530)

	local posLabel = Label(frame, L.POSITION, "GameFontNormalSmall")
	posLabel:SetPoint("TOPLEFT", 20, -570)
	controls.posCursor = Check(frame, L.POSITION_CURSOR, function()
		ns.db.position = "CURSOR"
		UpdateOptions()
	end)
	controls.posCursor:SetPoint("TOPLEFT", 90, -564)
	controls.posScreen = Check(frame, L.POSITION_SCREEN, function()
		ns.db.position = "SCREEN"
		UpdateOptions()
	end)
	controls.posScreen:SetPoint("TOPLEFT", 190, -564)

	local modeLabel = Label(frame, L.MODE, "GameFontNormalSmall")
	modeLabel:SetPoint("TOPLEFT", 330, -570)
	controls.modeClick = Check(frame, L.MODE_CLICK, function()
		ns.db.mode = "CLICK"
		UpdateOptions()
	end)
	controls.modeClick:SetPoint("TOPLEFT", 410, -564)
	controls.modeHold = Check(frame, L.MODE_HOLD, function()
		ns.db.mode = "HOLD"
		UpdateOptions()
	end)
	controls.modeHold:SetPoint("TOPLEFT", 530, -564)

	controls.keybind = Button(frame, L.KEYBINDINGS, 140, function()
		SettingsUI.OpenKeybindings()
	end)
	controls.keybind:SetPoint("BOTTOMLEFT", 12, 4)
	controls.keyText = Label(frame, "", "GameFontNormalSmall")
	controls.keyText:SetPoint("LEFT", controls.keybind, "RIGHT", 10, 0)

	controls.restore = Button(frame, L.RESTORE_DEFAULTS, 150, function()
		Compat.Confirm(L.RESTORE_CONFIRM, function()
			Database.Reset(ns.db)
			state.editing = 1
			RefreshAll()
		end)
	end)
	controls.restore:SetPoint("BOTTOMRIGHT", -10, 4)

	frame:SetScript("OnShow", function(self)
		self:RegisterEvent("UPDATE_BINDINGS")
		RefreshAll()
	end)
	frame:SetScript("OnHide", function(self)
		self:UnregisterEvent("UPDATE_BINDINGS")
		if searchBox then
			searchBox:ClearFocus()
		end
	end)
	frame:SetScript("OnEvent", function()
		UpdateOptions()
	end)
end

function SettingsUI.Toggle()
	if not ns.db then
		return
	end
	if not frame then
		Build()
	end
	frame:SetShown(not frame:IsShown())
end

function SettingsUI.Open()
	if not ns.db then
		return
	end
	if not frame then
		Build()
	end
	frame:Show()
	frame:Raise()
end

function SettingsUI.OpenKeybindings()
	if Compat.InCombat() then
		pendingKeybindings = true
		ns.Notify("combatsettings", L.MSG_COMBAT_SETTINGS)
		return
	end
	if frame then
		frame:Hide()
	end
	if not Compat.OpenKeybindings() then
		ns.Notify("nobinding", L.MSG_NO_BINDING)
	end
end

function SettingsUI.OnCombatEnded()
	if pendingKeybindings then
		pendingKeybindings = false
		SettingsUI.OpenKeybindings()
	end
end

-- Options > AddOns > SocialWheel: a short page that launches the window.
function SettingsUI.RegisterOptionsCategory()
	if SettingsUI.category then
		return
	end
	local panel = CreateFrame("Frame")
	local title = Label(panel, L.ADDON_TITLE, "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	local desc = Label(panel, L.SETTINGS_DESC, "GameFontHighlight")
	desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
	desc:SetWidth(560)
	desc:SetWordWrap(true)
	local open = Button(panel, L.SETTINGS_OPEN, 260, function()
		SettingsUI.Open()
	end)
	open:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
	local keys = Button(panel, L.KEYBINDINGS, 160, function()
		SettingsUI.OpenKeybindings()
	end)
	keys:SetPoint("LEFT", open, "RIGHT", 10, 0)
	local note = Label(panel, L.UNOFFICIAL, "GameFontDisableSmall")
	note:SetPoint("TOPLEFT", open, "BOTTOMLEFT", 0, -24)
	note:SetWidth(560)
	note:SetWordWrap(true)
	SettingsUI.category = Compat.RegisterSettingsCanvas(panel, L.ADDON_TITLE)
end
