
local BLUE_COLOR = Color(255, 157, 0) --Color(0, 122, 204)
local GREEN_COLOR = Color(141, 210, 138)
local GRAY_COLOR = Color(75, 75, 75)
local WHITE_COLOR = Color(255, 255, 255)

local TAB_COLOR = Color(45, 45, 45)
local TAB_OUTLINE_COLOR = Color(0, 0, 0, 0)

surface.CreateFont("gmx_lua_editor", {
	font = "Tahoma",
	extended = true,
	size = 15,
	weight = 600,
})

-- LuaFileBrowserDividerBar
do
	local PANEL = {}
	function PANEL:Init()
		self:SetCursor("sizewe")
		self:SetPaintBackground(false)
	end

	function PANEL:OnMousePressed(mcode)
		if mcode == MOUSE_LEFT then
			self:GetParent():StartGrab()
		end
	end

	vgui.Register("LuaFileBrowserDividerBar", PANEL, "DPanel")
end

-- LuaFileBrowserDivider
do
	local PANEL = {}

	AccessorFunc(PANEL, "m_pLeft", "Left")
	AccessorFunc(PANEL, "m_pRight", "Right")
	AccessorFunc(PANEL, "m_pMiddle", "Middle")
	AccessorFunc(PANEL, "m_iDividerWidth", "DividerWidth")
	AccessorFunc(PANEL, "m_iLeftWidth", "LeftWidth")
	AccessorFunc(PANEL, "m_bDragging", "Dragging", FORCE_BOOL)
	AccessorFunc(PANEL, "m_iLeftWidthMin", "LeftMin")
	AccessorFunc(PANEL, "m_iRightWidthMin", "RightMin")
	AccessorFunc(PANEL, "m_iHoldPos", "HoldPos")

	function PANEL:Init()
		self:SetDividerWidth(8)
		self:SetLeftWidth(100)

		self:SetLeftMin(50)
		self:SetRightMin(50)

		self:SetPaintBackground(false)

		self.m_DragBar = vgui.Create("LuaFileBrowserDividerBar", self)
		self._OldCookieW = 0
	end

	function PANEL:LoadCookies()
		self:SetLeftWidth(self:GetCookieNumber("LeftWidth", self:GetLeftWidth()))
		self._OldCookieW = self:GetCookieNumber("LeftWidth", self:GetLeftWidth())
	end

	function PANEL:SetLeft(pnl)
		self.m_pLeft = pnl

		if IsValid(self.m_pLeft) then
			self.m_pLeft:SetParent(self)
		end
	end

	function PANEL:SetMiddle(Middle)
		self.m_pMiddle = Middle

		if IsValid(self.m_pMiddle) then
			self.m_pMiddle:SetParent(self.m_DragBar)
		end
	end

	function PANEL:SetRight(pnl)
		self.m_pRight = pnl

		if IsValid(self.m_pRight) then
			self.m_pRight:SetParent(self)
		end
	end

	function PANEL:PerformLayout()
		self:SetLeftWidth(math.Clamp(self:GetLeftWidth(), self:GetLeftMin(), math.max(self:GetWide() - self:GetRightMin() - self:GetDividerWidth(), self:GetLeftMin())))

		if IsValid(self.m_pLeft) then
			self.m_pLeft:StretchToParent(0, 0, nil, 0)
			self.m_pLeft:SetWide(self:GetLeftWidth())
			self.m_pLeft:InvalidateLayout()
		end

		self.m_DragBar:SetPos(self:GetLeftWidth(), 0)
		self.m_DragBar:SetSize(self:GetDividerWidth(), self:GetTall())
		self.m_DragBar:SetZPos(-1)

		if IsValid(self.m_pRight) then
			self.m_pRight:StretchToParent(self:GetLeftWidth() + self.m_DragBar:GetWide(), 0, 0, 0)
			self.m_pRight:InvalidateLayout()
		end

		if IsValid(self.m_pMiddle) then
			self.m_pMiddle:StretchToParent(0, 0, 0, 0)
			self.m_pMiddle:InvalidateLayout()
		end
	end

	function PANEL:OnCursorMoved(x, y)
		if not self:GetDragging() then return end

		local oldLeftWidth = self:GetLeftWidth()
		x = math.Clamp(x - self:GetHoldPos(), self:GetLeftMin(), self:GetWide() - self:GetRightMin() - self:GetDividerWidth())

		self:SetLeftWidth(x)
		if oldLeftWidth ~= x then
			self:InvalidateLayout()
		end
	end

	function PANEL:Think()
		-- If 2 or more panels use the same cookie name, make every panel resize automatically to the same size
		if self._OldCookieW ~= self:GetCookieNumber("LeftWidth", self:GetLeftWidth()) and not self:GetDragging() then
			self:LoadCookies()
			self:InvalidateLayout()
		end
	end

	function PANEL:StartGrab()
		self:SetCursor( "sizewe" )

		local x, _ = self.m_DragBar:CursorPos()
		self:SetHoldPos(x)

		self:SetDragging(true)
		self:MouseCapture(true)
	end

	function PANEL:OnMouseReleased(mcode)
		if mcode == MOUSE_LEFT then
			self:SetCursor("none")
			self:SetDragging(false)
			self:MouseCapture(false)
			self:SetCookie("LeftWidth", self:GetLeftWidth())
		end
	end

	vgui.Register("LuaFileBrowserDivider", PANEL, "DPanel")
end

-- LuaFileBrowser
do
	local LUA_FILE_BROWSER = {}
	AccessorFunc(LUA_FILE_BROWSER, "m_strName", "Name")
	AccessorFunc(LUA_FILE_BROWSER, "m_strPath", "Path")
	AccessorFunc(LUA_FILE_BROWSER, "m_strFilter", "FileTypes")
	AccessorFunc(LUA_FILE_BROWSER, "m_strBaseFolder", "BaseFolder")
	AccessorFunc(LUA_FILE_BROWSER, "m_strCurrentFolder", "CurrentFolder")
	AccessorFunc(LUA_FILE_BROWSER, "m_strSearch", "Search")
	AccessorFunc(LUA_FILE_BROWSER, "m_bModels", "Models")
	AccessorFunc(LUA_FILE_BROWSER, "m_bOpen", "Open")

	function LUA_FILE_BROWSER:Init()
		self:SetPath("MOD")

		self.Divider = self:Add("LuaFileBrowserDivider")
		self.Divider:Dock(FILL)
		self.Divider:SetLeftWidth(160)
		self.Divider:SetDividerWidth(4)
		self.Divider:SetLeftMin(100)
		self.Divider:SetRightMin(100)

		self.Tree = self.Divider:Add("DTree")
		self.Divider:SetLeft(self.Tree)

		self.Tree.DoClick = function( _, node )
			local folder = node:GetFolder()
			if not folder then return end

			self:SetCurrentFolder(folder)
		end
	end

	function LUA_FILE_BROWSER:SetName(strName)
		if strName then
			self.m_strName = tostring(strName)
		else
			self.m_strName = nil
		end

		if not self.bSetup then return end

		self:SetupTree()
	end

	function LUA_FILE_BROWSER:SetBaseFolder(strBase)
		self.m_strBaseFolder = tostring(strBase)
		if not self.bSetup then return end

		self:SetupTree()
	end

	function LUA_FILE_BROWSER:SetPath(strPath)
		self.m_strPath = tostring(strPath)
		if not self.bSetup then return end

		self:SetupTree()
	end

	function LUA_FILE_BROWSER:SetSearch(strSearch)
		if not strSearch or strSearch == "" then
			strSearch = "*"
		end

		self.m_strSearch = tostring( strSearch )
		if not self.bSetup then return end

		self:SetupTree()
	end

	function LUA_FILE_BROWSER:SetFileTypes(strTypes)
		self.m_strFilter = tostring(strTypes or "*.*")
		if not self.bSetup then return end

		if self.m_strCurrentFolder then
			self:ShowFolder(self.m_strCurrentFolder)
		end
	end

	function LUA_FILE_BROWSER:SetCurrentFolder(strDir)
		strDir = tostring(strDir)
		strDir = string.Trim(strDir, "/")

		if self.m_strBaseFolder and not string.StartWith(strDir, self.m_strBaseFolder) then
			strDir = string.Trim(self.m_strBaseFolder, "/") .. "/" .. string.Trim(strDir, "/")
		end

		self.m_strCurrentFolder = strDir
		if not self.bSetup then return end

		self:ShowFolder(strDir)
	end

	function LUA_FILE_BROWSER:SetOpen(bOpen, bAnim)
		bOpen = tobool(bOpen)
		self.m_bOpen = bOpen

		if not self.bSetup then return end

		self.FolderNode:SetExpanded(bOpen, not bAnim)
		self.m_bOpen = bOpen
		self:SetCookie("Open", bOpen and "1" or "0")
	end

	function LUA_FILE_BROWSER:Paint(w, h)
		surface.SetDrawColor(TAB_COLOR)
		surface.DrawRect(0, 0, w, h)

		if not self.bSetup then
			self.bSetup = self:Setup()
		end
	end

	function LUA_FILE_BROWSER:PaintOver( w, h)
		surface.SetDrawColor(TAB_OUTLINE_COLOR)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	function LUA_FILE_BROWSER:SetupTree()
		local name = self.m_strName
		if not name then
			name = string.Trim(string.match(self.m_strBaseFolder, "/.+$") or self.m_strBaseFolder, "/")
		end

		local children = self.Tree.RootNode.ChildNodes
		if IsValid(children) then
			children:Clear()
		end

		self.FolderNode = self.Tree.RootNode:AddFolder(name, self.m_strBaseFolder, self.m_strPath, false, self.m_strSearch)
		self.Tree.RootNode.ChildExpanded = function(node, bExpand)
			DTree_Node.ChildExpanded(node, bExpand)
			self.m_bOpen = tobool(self.FolderNode.m_bExpanded)
			self:SetCookie("Open", self.m_bOpen and "1" or "0")
		end

		self.FolderNode:SetExpanded(self.m_bOpen, true)
		self:SetCookie("Open", self.m_bOpen and "1" or "0")

		self:ShowFolder()

		return true
	end

	function LUA_FILE_BROWSER:SetupFiles()
		if IsValid(self.Files) then self.Files:Remove() end

		self.Files = self.Divider:Add("DListView")
		self.Files:SetMultiSelect(false)
		self.FileHeader = self.Files:AddColumn("Files").Header

		self.Files.DoDoubleClick = function(pnl, _, line)
			self:OnDoubleClick(string.Trim(self:GetCurrentFolder() .. "/" .. line:GetColumnText(1), "/"), line)
		end

		self.Files.OnRowSelected = function(pnl, _, line)
			self:OnSelect(string.Trim(self:GetCurrentFolder() .. "/" .. line:GetColumnText(1), "/"), line)
		end

		self.Files.OnRowRightClick = function(pnl, _, line)
			self:OnRightClick(string.Trim(self:GetCurrentFolder() .. "/" .. line:GetColumnText(1), "/"), line)
		end

		self.Divider:SetRight(self.Files)

		if self.m_strCurrentFolder and self.m_strCurrentFolder ~= "" then
			self:ShowFolder(self.m_strCurrentFolder)
		end

		return true
	end

	function LUA_FILE_BROWSER:Setup()
		if not self.m_strBaseFolder then return false end
		return self:SetupTree() and self:SetupFiles()
	end

	function LUA_FILE_BROWSER:ShowFolder( path )
		if not IsValid(self.Files) then return end

		self.Files:Clear()

		if IsValid(self.FileHeader) then
			self.FileHeader:SetText( path or "Files" )
		end

		if not path then return end

		local filters = self.m_strFilter
		if not filters or filters == "" then
			filters = "*.*"
		end

		for _, filter in pairs(string.Explode(" ", filters)) do
			local files = file.Find(string.Trim(path .. "/" .. ( filter or "*.*" ), "/" ), self.m_strPath)
			if not istable(files) then continue end

			for _, v in pairs(files) do
				self.Files:AddLine(v)
			end
		end
	end

	function LUA_FILE_BROWSER:SortFiles( desc )
		if not self:GetModels() then
			self.Files:SortByColumn(1, tobool(desc))
		end
	end

	function LUA_FILE_BROWSER:GetFolderNode()
		return self.FolderNode
	end

	function LUA_FILE_BROWSER:Clear()
		DPanel.Clear(self)

		self.m_strBaseFolder, self.m_strCurrentFolder, self.m_strFilter, self.m_strName, self.m_strSearch, self.Divider.m_pRight = nil
		self.m_bOpen, self.m_bModels, self.m_strPath = false, false, "MOD"
		self.bSetup = nil

		self:Init()
	end

	function LUA_FILE_BROWSER:LoadCookies()
		self:SetOpen(self:GetCookieNumber("Open"), true)
	end

	function LUA_FILE_BROWSER:OnSelect(path, pnl) end
	function LUA_FILE_BROWSER:OnDoubleClick(path, pnl) end
	function LUA_FILE_BROWSER:OnRightClick(path, pnl) end

	vgui.Register("LuaFileBrowser", LUA_FILE_BROWSER, "DPanel")
end


local LUA_EDITOR = {
	LastAction = {
		Script = "",
		Type = "",
		Time = ""
	},
	Env = "self",
	Init = function(self)
		self.MenuBar = self:Add("DMenuBar")
		self.MenuBar:Dock(NODOCK)
		self.MenuBar:DockPadding(5, 0, 0, 0)
		self.MenuBar.Paint = function(_, w, h)
			surface.SetDrawColor(TAB_COLOR)
			surface.DrawRect(0, 0, w, h)
		end

		local options = {}

		self.MenuFile = self.MenuBar:AddMenu("File")
		table.insert(options, self.MenuFile:AddOption("New (Ctrl + N)", function() self:NewTab("", "new script") end))
		table.insert(options, self.MenuFile:AddOption("Close Current (Ctrl + W)", function() self:CloseCurrentTab() end))
		table.insert(options, self.MenuFile:AddOption("Open File (Ctrl + O)", function() self:OpenFile() end))

		self.RunButton = self:Add("DButton")
		self.RunButton:SetText("")
		self.RunButton:SetTextColor(WHITE_COLOR)
		self.RunButton:SetFont("gmx_lua_editor")
		self.RunButton:SetSize(200, 25)
		self.RunButton:SetPos(150, 5)
		self.RunButton.DoClick = function() self:RunCode() end

		local function menu_paint(_, w, h)
			surface.SetDrawColor(GRAY_COLOR)
			surface.DrawRect(0, 0, w, h)
		end

		local function option_paint(s, w, h)
			if s:IsHovered() then
				surface.SetDrawColor(WHITE_COLOR)
				surface.DrawOutlinedRect(0, 0, w, h)
			end
		end

		local function menu_button_paint(s, w, h)
			if s:IsHovered() then
				surface.SetDrawColor(GRAY_COLOR)
				surface.DrawRect(0, 0, w, h)
			end
		end

		local function combo_box_paint(_, w, h)
			surface.SetDrawColor(WHITE_COLOR)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		local drop_triangle = {
			{ x = 10, y = 3 },
			{ x = 5, y = 12 },
			{ x = 0, y = 3 },
		}
		local function drop_button_paint()
			surface.SetDrawColor(WHITE_COLOR)
			draw.NoTexture()
			surface.DrawPoly(drop_triangle)
		end

		self.MenuFile.Paint = menu_paint
		for _, option in ipairs(options) do
			option:SetTextColor(WHITE_COLOR)
			option:SetFont("gmx_lua_editor")
			option.Paint = option_paint
		end

		-- menu bar buttons changes
		for _, panel in pairs(self.MenuBar:GetChildren()) do
			if panel.ClassName == "DButton" then
				panel:SetTextColor(WHITE_COLOR)
				panel:SetFont("gmx_lua_editor")
				panel:SetSize(50, 25)
				panel.Paint = menu_button_paint
			end
		end

		local run_triangle = {
			{ x = 10, y = 15 },
			{ x = 10, y = 5 },
			{ x = 20, y = 10 }
		}
		self.RunButton.Paint = function(s, w, h)
			surface.DisableClipping(true)

			surface.SetDrawColor(GRAY_COLOR)
			if s:IsHovered() then
				surface.DrawRect(0, 0, w, h - 5)
			else
				surface.DrawOutlinedRect(0, 0, w, h - 5)
			end

			surface.SetDrawColor(GREEN_COLOR)
			draw.NoTexture()
			surface.DrawPoly(run_triangle)

			surface.SetFont("gmx_lua_editor")
			surface.SetTextColor(WHITE_COLOR)
			surface.SetTextPos(75, 3)
			surface.DrawText("Run Code")

			surface.DisableClipping(false)
		end

		self.CodeTabs = self:Add("DPropertySheet")
		self.CodeTabs:SetPos(0, 35)
		self.CodeTabs:SetPadding(0)
		self.CodeTabs:SetFadeTime(0)
		self.CodeTabs.Paint = function(_, w, h)
			surface.DisableClipping(true)
			surface.SetDrawColor(TAB_COLOR)
			surface.DrawRect(0, -10, w, h + 20)
			surface.DisableClipping(false)
		end
		self.CodeTabs.tabScroller.Paint = function() end
		self.CodeTabs.OnActiveTabChanged = function(_, _, new_tab)
			new_tab.m_pPanel:RequestFocus()
		end

		self.LblRunStatus = self:Add("DLabel")
		self.LblRunStatus:SetTextColor(WHITE_COLOR)
		self.LblRunStatus:Dock(BOTTOM)
		self.LblRunStatus:SetSize(self:GetWide(), 25)
		self.LblRunStatus:SetFont("gmx_lua_editor")
		self.LblRunStatus:SetText(("%sReady"):format((" "):rep(3)))
		self.LblRunStatus.Paint = function(_, w, h)
			surface.SetDrawColor(BLUE_COLOR)
			surface.DrawRect(0, 0, w, h)
		end

		self.ThemeSelector = self:Add("DComboBox")
		self.ThemeSelector:AddChoice("vs-dark", nil, true)
		self.ThemeSelector:SetTextColor(WHITE_COLOR)
		self.ThemeSelector:SetFont("gmx_lua_editor")
		self.ThemeSelector:SetWide(100)
		self.ThemeSelector.DropButton.Paint = drop_button_paint
		self.ThemeSelector.Paint = combo_box_paint

		self.ThemeSelector.OnSelect = function(_, _, theme_name)
			local tabs = self.CodeTabs:GetItems()
			for _, tab in pairs(tabs) do
				tab.Panel:QueueJavascript([[gmodinterface.SetTheme("]] .. theme_name .. [[");]])
			end

			cookie.Set("ECLuaTabTheme", theme_name)
		end

		self.LangSelector = self:Add("DComboBox")
		self.LangSelector:SetTextColor(WHITE_COLOR)
		self.LangSelector:SetFont("gmx_lua_editor")
		self.LangSelector:SetWide(100)
		self.LangSelector.DropButton.Paint = drop_button_paint
		self.LangSelector.Paint = combo_box_paint

		self.LangSelector.OnSelect = function(_, _, lang)
			local active_tab = self.CodeTabs:GetActiveTab()
			if not IsValid(active_tab) then return end

			local editor = active_tab.m_pPanel
			editor:QueueJavascript([[gmodinterface.SubmitLuaReport({ events: []});]])
			editor:QueueJavascript([[gmodinterface.SetLanguage("]] .. lang .. [[");]])
			active_tab.Lang = lang
		end
	end,
	Shortcuts = {
		{
			Trigger = { KEY_LCONTROL, KEY_N },
			Callback = function(self) self:NewTab("", "new script") end,
		},
		{
			Trigger = { KEY_LCONTROL, KEY_W },
			Callback = function(self) self:CloseCurrentTab() end,
		},
		{
			Trigger = { KEY_LCONTROL, KEY_R },
			Callback = function(self) self:RunCode() end,
		},
		{
			Trigger = { KEY_LCONTROL, KEY_O },
			Callback = function(self) self:OpenFile() end,
		}
	},
	Think = function(self)
		for _, shortcut in ipairs(self.Shortcuts) do
			if CurTime() >= (shortcut.Next or 0) then
				local should_trigger = true
				for _, key in ipairs(shortcut.Trigger) do
					if not input.IsKeyDown(key) then
						should_trigger = false
						break
					end
				end

				if should_trigger then
					shortcut.Callback(self)
					shortcut.Next = CurTime() + (shortcut.Cooldown or 0.1)
				end
			end
		end
	end,
	PerformLayout = function(self, w, h)
		self.MenuBar:SetSize(w, 25)
		self.CodeTabs:SetSize(w, h - 60)

		local x, y, bound_w, _ = self.LblRunStatus:GetBounds()
		self.ThemeSelector:SetPos(x + bound_w - self.ThemeSelector:GetWide() - 5, y + 1)
		self.LangSelector:SetPos(x + bound_w - self.ThemeSelector:GetWide() - 10 - self.LangSelector:GetWide(), y + 1)
	end,
	RunCode = function(self)
		local code = self:GetCode():Trim()
		if #code == 0 then return end

		RunOnClient(code)
		self:RegisterAction(self.Env)
	end,
	CloseCurrentTab = function(self)
		if #self.CodeTabs:GetItems() > 1 then
			local tab = self.CodeTabs:GetActiveTab()
			self.CodeTabs:CloseTab(tab, true)

			-- get new tab
			tab = self.CodeTabs:GetActiveTab()
			tab.m_pPanel:RequestFocus()
		end
	end,
	OpenFile = function(self, location)
		if self.OpenedFileBrowser then return end
		self.OpenedFileBrowser = true

		local editor = self
		if not location then location = "MOD" end

		local frame = vgui.Create("DFrame")
		frame:SetSize(self:GetWide(), self:GetTall())
		frame:SetSizable(true)
		frame:Center()
		frame:MakePopup()
		frame:SetTitle("Lua Editor File Browser")

		frame.Paint = function(_, w, h)
			surface.SetDrawColor(TAB_COLOR)
			surface.DrawRect(0, 0, w, h)
		end

		frame.PaintOver = function(_, w, h)
			surface.SetDrawColor(TAB_OUTLINE_COLOR)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		frame.OnRemove = function()
			editor.OpenedFileBrowser = false
		end

		local browser = vgui.Create("LuaFileBrowser", frame)
		browser:Dock(FILL)
		browser:SetPath(location)
		browser:SetBaseFolder("")
		browser:SetOpen(true)
		browser:SetCurrentFolder("persist")

		function browser:OnSelect(path, pnl)
			if file.Exists(path, location) then
				local code = file.Read(path, location)
				editor:NewTab(code, path:GetFileFromFilename())
				editor.OpenedFileBrowser = false
			end

			frame:Remove()
		end
	end,
	NewTab = function(self, code, name)
		code = code or ""

		local editor = vgui.Create("DHTML")
		local tab_name = ("%s%s"):format(name, (" "):rep(20))
		local sheet = self.CodeTabs:AddSheet(tab_name, editor)
		local tab = sheet.Tab
		tab.Code = code
		tab.Name = tab_name:Trim()
		tab.Lang = "glua"
		self.LblRunStatus:SetText(("%sLoading..."):format((" "):rep(3)))

		editor:AddFunction("gmodinterface", "OnCode", function(new_code)
			tab.Code = new_code
		end)

		editor:AddFunction("gmodinterface", "OnThemesLoaded", function(themes)
			self.ThemeSelector:Clear()
			for _, theme_name in pairs(themes) do
				if cookie.GetString("ECLuaTabTheme") == theme_name then
					self.ThemeSelector:AddChoice(theme_name, nil, true)
					editor:QueueJavascript([[gmodinterface.SetCode("]] .. theme_name .. [[");]])
				else
					self.ThemeSelector:AddChoice(theme_name)
				end
			end
		end)

		editor:AddFunction("gmodinterface", "OnLanguages", function(languages)
			self.LangSelector:Clear()
			self.LangSelector:AddChoice("glua", nil, true)

			for _, lang in pairs(languages) do
				self.LangSelector:AddChoice(lang)
			end
		end)

		editor:AddFunction("gmodinterface", "OnReady", function()
			self.LblRunStatus:SetText(("%sReady"):format((" "):rep(3)))
			local safe_code = code:JavascriptSafe()
			editor:QueueJavascript([[gmodinterface.SetCode(`]] .. safe_code .. [[`);]])
			editor:QueueJavascript([[gmodinterface.LoadAutocompleteState(`Shared`);]])

			if tab == self.CodeTabs:GetActiveTab() then
				editor:RequestFocus()
			end
		end)

		local url = "metastruct.github.io/gmod-monaco"
		editor:OpenURL(url)

		self.CodeTabs:SetActiveTab(tab)
		local tab_w = tab:GetWide()
		tab:SetTextColor(WHITE_COLOR)
		tab:SetFont("gmx_lua_editor")

		local close_btn = tab:Add("DButton")
		close_btn:SetPos(tab_w - 20, 0)
		close_btn:SetSize(20, 20)
		close_btn:SetText("x")
		close_btn:SetTextColor(WHITE_COLOR)
		close_btn:SetFont("gmx_lua_editor")
		close_btn.Paint = function() end
		close_btn.DoClick = function()
			if #self.CodeTabs:GetItems() > 1 then
				self.CodeTabs:CloseTab(tab, true)
			end
		end

		tab.Paint = function(_, w, h)
			if tab == self.CodeTabs:GetActiveTab() then
				surface.SetDrawColor(BLUE_COLOR)
				surface.DrawRect(0, 0, w, 20)
			end
		end
		local old_editor_paint = editor.Paint
		editor.Paint = function(_, w, h)
			if tab ~= self.CodeTabs:GetActiveTab() then return end

			surface.DisableClipping(true)
			surface.SetDrawColor(BLUE_COLOR)
			surface.DrawRect(0, -2, w, 2)
			surface.DisableClipping(false)

			old_editor_paint(editor, w, h)
		end

		tab.Panel:RequestFocus()
	end,
	RegisterAction = function(self, type)
		local tab = self.CodeTabs:GetActiveTab()
		if not IsValid(tab) then return end

		self.LastAction = {
			Script = ("%s..."):format(tab.Name),
			Type = type,
			Time = os.date("%H:%M:%S")
		}

		local spacing = (" "):rep(3)
		local text = ("%s[%s] Ran %s on %s"):format(spacing, self.LastAction.Time, tab.Name, self.LastAction.Type)
		if #text == 0 then text = ("%sReady"):format(spacing) end
		self.LblRunStatus:SetText(text)
		gmx.Print(text)
	end,
	GetCode = function(self)
		local tab = self.CodeTabs:GetActiveTab()
		if IsValid(tab) and tab.Code then
			return tab.Code
		end

		return ""
	end,
	Paint = function(self, w, h)
		surface.SetDrawColor(TAB_COLOR)
		surface.DrawRect(0, 0, w, h)
	end,
	PaintOver = function(self, w, h)
		surface.SetDrawColor(TAB_OUTLINE_COLOR)
		surface.DrawOutlinedRect(0, 0, w, h)
	end
}

vgui.Register("LuaEditor", LUA_EDITOR, "DPanel")


local EDITOR
local function init_editor()
	if IsValid(EDITOR) then return end

	local p = vgui.Create("DFrame")
	p:SetTitle("Lua Editor")
	p.lblTitle:SetFont("gmx_lua_editor")
	p:SetSize(1200, 1000)
	p:SetSizable(true)
	p:Center()
	p:MakePopup()
	p:DockPadding(2, 25, 2, 2)

	function p:Paint(w, h)
		surface.SetDrawColor(30, 30, 30, 255)
		surface.DrawRect(2, 0, w - 4, h -2)

		surface.SetDrawColor(GRAY_COLOR)
		surface.DrawLine(2, 25, w - 4, 25)
	end

	local editor = p:Add("LuaEditor")
	editor:Dock(FILL)
	editor:NewTab("", "new script")
	EDITOR = editor
end

concommand.Add("gmx_editor", init_editor)

concommand.Add("gmx_explore_server_files", function()
	gmx.RunOnClient([[
		local frame = vgui.Create("DFrame")
		frame:SetSize(800, 400)
		frame:SetSizable(true)
		frame:Center()
		frame:MakePopup()
		frame:SetTitle("Server File Browser")

		local browser = vgui.Create("DFileBrowser", frame)
		browser:Dock(FILL)
		browser:SetPath("LUA")
		browser:SetBaseFolder("")
		browser:SetOpen(true)
		browser:SetCurrentFolder("persist")

		function browser:OnSelect(path, pnl)
			if file.Exists(path, "LUA") then
				MENU_HOOK("OpenServerFile", path)
			end
		end
	]], { "util", "interop" })
end)

hook.Add("OpenServerFile", "gmx_explore_srv_files", function(original_path)
	init_editor()

	local code = gmx.ReadFromLuaCache(original_path)
	gmx.Print("Received server file " .. original_path)
	EDITOR:NewTab(code, original_path)
end)