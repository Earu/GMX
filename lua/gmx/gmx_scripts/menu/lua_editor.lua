local ERR_COLOR = Color(255, 0, 0)
local function err_print(head, msg)
	MsgC(ERR_COLOR, "[GMX:", head, "] ", msg, "\n")
end

gmx.Require("luasocket")

local function send(op, data)
	if not socket then return end
	if not socket.tcp then return end

	local json = util.TableToJSON({
		op = op,
		data = data,
	})

	local s = socket.tcp()
	s:connect("127.0.0.1", 27203)
	s:send(json)
	s:shutdown()
	s:close()
end

local function send_virtual_fs()
	local virtual_paths = {}
	for _, path_data in pairs(IsInGame() and gmx.GetServerLuaFiles() or {}) do
		table.insert(virtual_paths, path_data.VirtualPath)
	end

	send("FS_SYNC", virtual_paths)
end

local CALLBACKS = {
	["FS_REQUEST_SYNC"] = function()
		send_virtual_fs()
	end,
	["FS_REQUEST_OPEN"] = function(sock, data)
		local path = data.path
		local code = gmx.ReadFromLuaCache(path)

		send("FS_OPEN", { title = path, code = code })
	end,
	["RUN_MENU"] = function(sock, data)
		local title = data.title
		local code = data.code

		if not code then return end
		if code:len() < 1 then return end

		gmx.Print("Menu running:", title)
		RunString(code, title)
	end,
	["RUN_CLIENT"] = function(sock, data)
		local title = data.title
		local code = data.code

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

	local json = client:receive("*a")
	if json then
		local payload = util.JSONToTable(json)
		local callback = CALLBACKS[payload.op]
		if callback then
			callback(client, payload.data)
		end
	end

	client:shutdown()
end)

function gmx.OpenCodeTab(tab_name, tab_code)
	send("FS_OPEN", { title = tab_name, code = tab_code })
end