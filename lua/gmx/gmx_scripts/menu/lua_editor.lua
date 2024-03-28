local ERR_COLOR = Color(255, 0, 0)
local function err_print(head, msg)
	MsgC(ERR_COLOR, "[GMX:", head, "] ", msg, "\n")
end

concommand.Remove("gmx_explore_server_files")
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

if util.IsBinaryModuleInstalled("luasocket") then
	require("luasocket")
end

local methods = {
	["menu"] = function(sock)
		local title = sock:receive("*l")
		local code = sock:receive("*a")
		if not code then return end
		if code:len() < 1 then return end

		gmx.Print("Menu running:", title)
		RunString(code, title)
	end,
	["client"] = function(sock)
		local title = sock:receive("*l")
		local code = sock:receive("*a")
		if not code then return end
		if code:len() < 1 then return end

		gmx.Print("Client running:", title)
		gmx.RunOnClient(code, {
			"util",
			"detouring",
			"interop",
			"hooking"
		})
	end,
}

local function listen_socket(port)
	if not socket then return end
	if not socket.tcp then return end

	local sock = socket.tcp()
	local socket_bound = sock and sock:bind("127.0.0.1", port)
	if not socket_bound then
		err_print("Lua Editor", "Could not bind socket")
		return
	end

	sock:settimeout(0)
	sock:setoption("reuseaddr", true)
	if not sock:listen(0) then
		err_print("Lua Editor", "Could not start listening")
		return
	end

	return sock
end

local sock = listen_socket(27202)
hook.Add("Think", "gmx_socket", function()
	if not sock then return end

	local client = sock:accept()
	if not client then return end

	if client:getpeername() ~= "127.0.0.1" then
		err_print("Lua Editor", "Refused " .. client:getpeername())
		client:shutdown()
		return
	end

	client:settimeout(0)

	local protocol = client:receive("*l")
	local method = protocol == "extension" and client:receive("*l") or protocol
	if method and methods[method] then
		methods[method](client)
	end

	client:shutdown()
end)

function gmx.OpenCodeTab(tab_name, tab_code)
	--MsgC(gmx.Colors.TextAlternative, ("-- %s\n"):format(tab_name))
	--gmx.Debug.PrintCode(tab_code)

	local s = socket.tcp()
	s:connect("127.0.0.1", 27203)
	s:send(tab_name .. "\n" .. tab_code)
	s:shutdown()
	s:close()
end

hook.Add("OpenServerFile", "gmx_explore_srv_files", function(original_path)
	local code = gmx.ReadFromLuaCache(original_path)
	gmx.Print("Lua Editor", "Opening server file " .. original_path)
	gmx.OpenCodeTab(original_path, code)
end)