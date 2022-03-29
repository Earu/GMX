require("naughty")

local COLOR_WHITE = Color(255, 255, 255, 255)
local COLOR_BG_HOVERED = Color(255, 157, 0)

local function create_editor()
	local frame = vgui.Create("DFrame")
	frame:SetTitle("Binary Editor")
	frame:SetSize(800, 600)
	frame:Center()
	frame:MakePopup()
	frame.btnMinim:Hide()
	frame.btnMaxim:Hide()
	frame.lblTitle:SetFont("gmx_info")

	function frame.btnClose:Paint()
		surface.SetTextColor(COLOR_BG_HOVERED)
		surface.SetTextPos(10, 5)
		surface.SetFont("DermaDefaultBold")
		surface.DrawText("X")
	end

	function frame:Paint(w, h)
		surface.SetDrawColor(143, 99, 29, 201)
		surface.DrawOutlinedRect(1, 1, w - 2, h - 2)

		surface.SetDrawColor(65, 40, 0, 200)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(COLOR_BG_HOVERED)
		surface.DrawOutlinedRect(0, 0, w, 60)
		surface.DrawLine(0, 25, w, 30)
	end

	local header = frame:Add("DPanel")
	header:Dock(TOP)
	header:SetTall(30)
	header:DockPadding(5, 5, 5, 5)
	header.Paint = function() end

	local address = header:Add("DTextEntry")
	address:Dock(LEFT)
	address:SetWide(250)
	address:SetText(mem.GetBaseAddress())

	local range = header:Add("DNumberWang")
	range:Dock(LEFT)
	range:DockMargin(5, 0, 0, 0)
	range:SetWide(250)
	range:SetMin(1)
	range:SetMax(512)
	range:SetValue(255)

	local is_offset = header:Add("DCheckBoxLabel")
	is_offset:Dock(LEFT)
	is_offset:DockMargin(5, 0, 0, 0)
	is_offset:SetText("Is Offset")
	is_offset:SetWide(75)
	is_offset:SetTextColor(COLOR_WHITE)

	local read_btn = frame:Add("DButton")
	read_btn:SetPos(610, 29)
	read_btn:SetText("Read")
	read_btn:SetWide(190)
	read_btn:SetTall(31)
	read_btn:SetTextColor(COLOR_WHITE)

	function read_btn:Paint(w, h)
		surface.SetDrawColor(255, 157, 0, 200)
		surface.DrawLine(0, 0, 0, h)
	end

	local bytes_frame = frame:Add("DScrollPanel")
	bytes_frame:Dock(FILL)
	bytes_frame:DockMargin(0, 5, 0, 5)

	local function build_bytes()
		if not IsValid(bytes_frame) then return end

		bytes_frame:Clear()

		local success, bytes = mem.Read(address:GetText(), range:GetValue(), is_offset:GetChecked())
		if not success then
			gmx.Print("Binary Editor", bytes)
			return
		end

		local cell_size, cell_margin = 25, 5
		local amount_per_line = math.ceil(bytes_frame:GetWide() / cell_size) - 6

		local byte_index = 1
		local row = 1
		while #bytes - byte_index > amount_per_line do
			for col = 1, amount_per_line do
				local byte = bytes[byte_index]
				local byte_panel = bytes_frame:Add("DButton")
				local value = string.char(byte)
				local valid_ascii = byte >= 32 and byte <= 126

				byte_panel:SetSize(cell_size, cell_size)
				byte_panel:SetText(value)
				byte_panel:SetPos((col - 1) * (cell_size + cell_margin), 5 + (row - 1) * (cell_size + cell_margin))
				byte_panel:SetTextColor(valid_ascii and COLOR_WHITE or COLOR_BG_HOVERED)
				byte_panel.Offset = byte_index - 1

				local ascii_mode = true
				function byte_panel:DoClick()
					ascii_mode = not ascii_mode
					if ascii_mode then
						self:SetText(value)
					else
						self:SetText(tostring(byte))
					end
				end

				function byte_panel:DoRightClick()
					local addr = mem.ComputeAddress(address:GetText(), self.Offset)
					Derma_StringRequest("Write", "Write value to " .. addr, byte, function(new_value)
						local new_byte = tonumber(new_value) or string.byte(new_value[1])
						if not new_byte then return end

						local wrote, err = mem.Write(addr, { new_byte })
						if not wrote then
							gmx.Print("Binary Editor", err)
							return
						end

						valid_ascii = byte >= 32 and byte <= 126
						byte = new_byte
						self:SetText(ascii_mode and string.char(new_byte) or tostring(new_byte))
					end)
				end

				function byte_panel:Paint(w, h)
					if valid_ascii then
						surface.SetDrawColor(65, 65, 65, 200)
						surface.DrawRect(0, 0, w, h)

						surface.SetDrawColor(143, 143, 143, 201)
						surface.DrawOutlinedRect(0, 0, w, h)
					else
						surface.SetDrawColor(65, 40, 0, 200)
						surface.DrawRect(0, 0, w, h)

						surface.SetDrawColor(143, 99, 29, 201)
						surface.DrawOutlinedRect(0, 0, w, h)
					end
				end

				byte_index = byte_index + 1
			end

			row = row + 1
		end
	end

	timer.Simple(0, build_bytes)
	function read_btn:DoClick() build_bytes() end
end

concommand.Add("gmx_binary_editor", create_editor)