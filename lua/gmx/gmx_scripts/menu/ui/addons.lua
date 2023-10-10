local addons_frame
local function toggle_addons()
	if IsValid(addons_frame) then
		SafeRemoveEntity(addons_frame)
	end

	local frame = vgui.Create("DFrame")
	frame:SetTitle("Addons")
	frame:SetSize(800, 600)
	frame:MakePopup()
	frame:DockPadding(0, 25, 0, 0)
	frame:Center()
	frame:SetKeyboardInputEnabled(true)
	frame:SetMouseInputEnabled(true)
	frame.lblTitle:SetFont("gmx_info")
	gmx.SetVGUIElementColor(frame.lblTitle, frame.lblTitle.SetTextColor, "Text")
	addons_frame = frame

	function frame:Paint(w, h)
		surface.SetDrawColor(gmx.Colors.Background)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(gmx.Colors.BackgroundStrip)
		surface.DrawOutlinedRect(0, 0, w, h)
		surface.SetDrawColor(gmx.Colors.BackgroundStrip)
		surface.DrawOutlinedRect(0, 0, w, 25)
	end

	local list_view = frame:Add("DListView")
	list_view:Dock(FILL)
	list_view:SetMultiSelect(true)

	function list_view:Paint()
	end

	local columns = {}
	table.insert(columns, list_view:AddColumn("ID"))
	table.insert(columns, list_view:AddColumn("Name"))
	table.insert(columns, list_view:AddColumn("Mounted"))

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

	local function update_list()
		list_view:Clear()

		for i, data in ipairs(engine.GetAddons()) do
			local line = list_view:AddLine(data.wsid, data.title, tostring(data.mounted))

			for _, column in pairs(line.Columns) do
				gmx.SetVGUIElementColor(column, column.SetTextColor, "Text")
			end

			function line:Paint(w, h)
				if not data.mounted then
					surface.SetDrawColor(35, 35, 35, 255)
					surface.DrawRect(0, 0, w, h)
				end

				if self:IsHovered() or self:IsLineSelected() then
					self:SetCursor("hand")
					surface.SetDrawColor(gmx.Colors.Accent)
					surface.DrawRect(0, 0, w, h)
				end
			end

			function line:OnRightClick()
				local menu = DermaMenu()
				menu:SetPos(gui.MouseX(), gui.MouseY())

				menu:AddOption("Copy path", function()
					SetClipboardText((data.file):GetPathFromFilename():gsub("\\", "/"))
				end)

				menu:AddOption(data.mounted and "Unmount" or "Mount", function()
					steamworks.SetShouldMountAddon(data.wsid, not data.mounted)
					steamworks.ApplyAddons()

					update_list()
				end):SetIcon("icon16/brick_edit.png")

				menu:AddSpacer()

				menu:AddOption("Unsubscribe", function()
					steamworks.Unsubscribe(data.wsid)
					steamworks.ApplyAddons()

					update_list()
				end):SetIcon("icon16/brick_delete.png")

				menu:Open()
			end

			function line:DoDoubleClick()
				steamworks.SetShouldMountAddon(data.wsid, not data.mounted)
				steamworks.ApplyAddons()

				update_list()
			end
		end
	end

	function list_view:DoDoubleClick(_, line)
		local id = line:GetColumnText(1)
		if not id then return end

		local mounted = line:GetColumnText(3) == "true"
		steamworks.SetShouldMountAddon(id, not mounted)
		steamworks.ApplyAddons()

		update_list()
	end

	update_list()
end

gmx.ShowAddonsPanel = toggle_addons