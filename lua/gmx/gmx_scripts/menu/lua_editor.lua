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

	end,
	["client"] = function(sock)

	end,
}

local function prepare_socket()
	if not socket then return end
	if not socket.tcp then return end

	local sock = socket.tcp()
	local socket_bound = sock and sock:bind("127.0.0.1", 27199)
	if not socket_bound then
		return
	end

	sock:settimeout(0)
	sock:setoption("reuseaddr", true)
	if not sock:listen(0) then
		return
	end

	return sock
end

local sock = prepare_socket()
hook.Add("Think", "gmx_socket", function()
	if not sock then return end

	local client = sock:accept()
	if not client then return end

	if client:getpeername() ~= "127.0.0.1" then
		gmx.Print("Refused " .. client:getpeername())
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
	--if not sock then

	MsgC(gmx.Colors.TextAlternative, ("-- %s\n"):format(tab_name))
	gmx.Debug.PrintCode(tab_code)

		--return
	--end
end

hook.Add("OpenServerFile", "gmx_explore_srv_files", function(original_path)
	local code = gmx.ReadFromLuaCache(original_path)
	gmx.Print("Received server file " .. original_path)
	gmx.OpenCodeTab(original_path, code)
end)