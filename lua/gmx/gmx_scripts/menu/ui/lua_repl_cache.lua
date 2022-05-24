local repl_panel
local function toggle_repl_cache_panel()
	if IsValid(repl_panel) then
		repl_panel:SetVisible(not repl_panel:IsVisible())
		if repl_panel:IsVisible() then
			repl_panel:MakePopup()
		end

		return
	end

	local frame = vgui.Create("DFrame")
	frame:SetSize(600, 300)
	frame:SetTitle("Lua Repl Cache")
	frame:MakePopup()
	frame:DockPadding(0, 25, 0, 0)
	frame:Center()
	frame:SetKeyboardInputEnabled(true)
	frame:SetMouseInputEnabled(true)
	frame.btnMinim:Hide()
	frame.lblTitle:SetFont("gmx_info")
	gmx.SetVGUIElementColor(frame.lblTitle, frame.lblTitle.SetTextColor, "Text")

	function frame.btnMaxim.Paint()
		surface.SetTextColor(gmx.Colors.Text)
		surface.SetTextPos(10, 5)
		surface.SetFont("DermaDefaultBold")
		surface.DrawText("↻")
	end

	frame.btnMaxim:SetEnabled(true)
	function frame.btnMaxim:DoClick()
		gmx.ReplFilterCache = {}
		hook.Run("GMXReplFilterCacheChanged")
		gmx.Print("Cleared repl lua cache")
	end

	function frame.btnClose:Paint()
		surface.SetTextColor(gmx.Colors.Text)
		surface.SetTextPos(10, 5)
		surface.SetFont("DermaDefaultBold")
		surface.DrawText("X")
	end

	function frame:Paint(w, h)
		surface.SetDrawColor(gmx.Colors.Background)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(gmx.Colors.BackgroundStrip)
		surface.DrawOutlinedRect(0, 0, w, h)

		surface.SetDrawColor(gmx.Colors.BackgroundStrip)
		surface.DrawOutlinedRect(0, 0, w, 41)
	end

	local list_view = frame:Add("DListView")
	list_view:Dock(FILL)
	list_view:SetMultiSelect(true)
	function list_view:Paint() end

	local columns = {}
	table.insert(columns, list_view:AddColumn("ID"))
	table.insert(columns, list_view:AddColumn("Name"))
	table.insert(columns, list_view:AddColumn("Method"))
	table.insert(columns, list_view:AddColumn("Date"))
	for i, column in ipairs(columns) do
		gmx.SetVGUIElementColor(column.Header, column.Header.SetTextColor, "Text")
		column.Header:SetFont("gmx_info")
		column.Header:SetTall(30)
		function column.Header:Paint(w, h)
			surface.SetDrawColor(gmx.Colors.BackgroundStrip)
			if i == 1 then
				surface.DrawLine(w, 0, w, h)
			elseif i == #columns then
				surface.DrawLine(0, 0, 0, h)
			else
				surface.DrawLine(w, 0, w, h)
				surface.DrawLine(0, 0, 0, h)
			end

			surface.DrawLine(0, 0, w, 0)
			surface.DrawLine(0, h - 1, w, h - 1)
		end
	end

	local btn_open = frame:Add("DButton")
	btn_open:Dock(BOTTOM)
	btn_open:SetText("Open")
	btn_open:SetSize(frame:GetWide(), 30)
	btn_open:SetFont("gmx_info")
	gmx.SetVGUIElementColor(btn_open, btn_open.SetTextColor, "Text")

	local function update_list()
		list_view:Clear()

		for i, data in ipairs(gmx.ReplFilterCache) do
			local line = list_view:AddLine(tostring(i), data.Path, data.Method, data.Date)
			for _, column in pairs(line.Columns) do
				gmx.SetVGUIElementColor(column, column.SetTextColor, "Text")
			end

			function line:Paint(w, h)
				if self:IsHovered() or self:IsLineSelected() then
					self:SetCursor("hand")
					surface.SetDrawColor(gmx.Colors.Accent)
					surface.DrawRect(0, 0, w, h)
				end
			end
		end
	end

	update_list()
	hook.Add("GMXReplFilterCacheChanged", list_view, update_list)

	function btn_open:Paint(w, h)
		surface.SetDrawColor(gmx.Colors.Background)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(gmx.Colors.BackgroundStrip)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	function btn_open:DoClick()
		local selected = list_view:GetSelected()
		if not selected or #selected == 0 then return end

		for _, line in pairs(selected) do
			local id = tonumber(line:GetColumnText(1)) or -1
			if id == -1 then continue end

			local data = gmx.ReplFilterCache[id]
			if not data then continue end

			gmx.OpenCodeTab(data.Path, data.Lua)
		end
	end

	function list_view:DoDoubleClick(_, line)
		local id = tonumber(line:GetColumnText(1)) or -1
		if id == -1 then return end

		local data = gmx.ReplFilterCache[id]
		if not data then return end

		gmx.OpenCodeTab(data.Path, data.Lua)
	end

	repl_panel = frame
end

concommand.Remove("gmx_repl_cache")
concommand.Add("gmx_repl_cache", function()
	toggle_repl_cache_panel()
end)