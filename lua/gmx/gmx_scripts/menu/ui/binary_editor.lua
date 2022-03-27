require("naughty")

local COLOR_WHITE = Color(255, 255, 255, 255)
local COLOR_BG_HOVERED = Color(255, 157, 0)

local function create_editor()
	local frame = vgui.Create("DFrame")
	frame:SetTitle("Binary Editor")
	frame:SetSize(800, 600)
	frame:Center()
	frame:MakePopup()

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

	local read_btn = header:Add("DButton")
	read_btn:Dock(LEFT)
	read_btn:DockMargin(5, 0, 0, 0)
	read_btn:SetText("Read")
	read_btn:SetWide(190)
	read_btn:SetTall(25)
	read_btn:SetTextColor(COLOR_WHITE)

	function read_btn:Paint(w, h)
		surface.SetDrawColor(65, 40, 0, 200)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(255, 157, 0, 200)
		surface.DrawOutlinedRect(1, 1, w - 2, h - 2)
	end

	local bytes_frame = frame:Add("DScrollPanel")
	bytes_frame:Dock(FILL)
	bytes_frame:DockMargin(0, 5, 0, 5)

	local function build_bytes()
		if not IsValid(bytes_frame) then return end

		bytes_frame:Clear()

		local bytes = mem.Read(address:GetText(), range:GetValue())
		local cell_size, cell_margin = 25, 5
		local amount_per_line = math.ceil(bytes_frame:GetWide() / cell_size) - 6

		local byte_index = 1
		local row = 1
		while #bytes - byte_index > amount_per_line do
			for col = 1, amount_per_line do
				local byte = bytes[byte_index]
				local byte_panel = bytes_frame:Add("DButton")
				local value = byte >= 32 and byte <= 126 and string.char(byte) or tostring(byte)
				byte_panel:SetSize(cell_size, cell_size)
				byte_panel:SetText(value)
				byte_panel:SetPos((col - 1) * (cell_size + cell_margin), (row - 1) * (cell_size + cell_margin))
				byte_panel:SetTextColor(COLOR_WHITE)

				function byte_panel:Paint(w, h)
					surface.SetDrawColor(65, 40, 0, 200)
					surface.DrawRect(0, 0, w, h)

					surface.SetDrawColor(143, 99, 29, 201)
					surface.DrawOutlinedRect(0, 0, w, h)
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