gmx = gmx or { Colors = {} }
gmx.Colors = {
	Text = Color(255, 255, 255, 255),
	TextAlternative = Color(200, 200, 200, 255),
	Wallpaper = Color(0, 0, 0),
	Background = Color(10, 10, 10),
	BackgroundStrip = Color(40, 40, 40),
	Accent = Color(255, 157, 0),
	AccentAlternative = Color(255, 196, 0),
}

local HEADER_COLOR = Color(255, 157, 0)
local BODY_COLOR = Color(255, 196, 0)
local EXTRA_COLOR = Color(255, 255, 255)
local ERR_COLOR = Color(255, 0, 0)

-- this makes sure all the prints and messages in the console are printed in the custom UI
do
	local INIT_CONSOLE_BUFFER = {}
	local FUNCTION_NAMES = { "MsgC", "Msg", "MsgN", "print" }
	local NATIVE_FUNCTIONS = {}

	for _, fn_name in ipairs(FUNCTION_NAMES) do
		local native_fn = _G[fn_name]
		NATIVE_FUNCTIONS[fn_name] = native_fn

		_G[fn_name] = function(...)
			table.insert(INIT_CONSOLE_BUFFER, { fn = native_fn, args = { ... } })
		end
	end

	function gmx.FlushInitConsoleBuffer()
		for _, data in ipairs(INIT_CONSOLE_BUFFER) do
			data.fn(unpack(data.args))
		end

		for fn_name, native_fn in pairs(NATIVE_FUNCTIONS) do
			_G[fn_name] = native_fn
		end

		gmx.FlushInitConsoleBuffer = function() end
	end
end

function gmx.Print(...)
	local args = {}
	for key, arg in pairs({ ... }) do
		args[key] = tostring(arg)
	end

	MsgC(gmx.Colors.Accent or HEADER_COLOR, "[GMX] ", gmx.Colors.AccentAlternative or BODY_COLOR, args[1] .. "\t", gmx.Colors.Text or EXTRA_COLOR, table.concat(args, "\t", 2)  .. "\n")
	hook.Run("GMXUINotification", table.concat(args, " "))
end

hook.Add("GMXNotify", "gmx_logs", gmx.Print)

if jit.arch ~= "x64" then
	gmx.Print("GMX is not supported on this architecture (" .. jit.arch .. ").")
	return
else
	MsgC(gmx.Colors.Accent or HEADER_COLOR, [[

============================================================
=                     G     M     X                        =
============================================================]] .. "\n")
end

function gmx.Require(binary_name, fallback)
	if not util.IsBinaryModuleInstalled(binary_name) then
		MsgC(ERR_COLOR, "[GMX] Could not require '" .. binary_name .. "' module\n")

		if isfunction(fallback) then
			fallback()
		end

		return
	end

	require(binary_name)
end

function gmx.Module(module_name)
	local m = gmx[module_name] or {}
	gmx[module_name] = m

	return m
end

gmx.Require("rocx", function()
	RunOnClient = function() error("rocx module not loaded") end
end)

concommand.Remove("gmx")
concommand.Add("gmx", function(_, _, _, cmd)
	cmd = cmd:Trim()
	if #cmd == 0 then
		PrintTable(gmx)
		return
	end

	if cmd == "reload" then
		hook.Run("GMXReload")
		include("gmx/gmx.lua")
		return
	end

	if file.Exists(cmd, "MOD") then
		gmx.Print("Menu running:", cmd)
		local lua = file.Read(cmd, "MOD")
		RunString(lua, "gmx")

		return
	end

	gmx.Print("Menu running:", cmd)
	local err = RunString([[local ret = (]] .. cmd .. [[) local p = ((isfunction(ret) or istable(ret)) and gmx.Debug and gmx.Debug.Print or print) p(ret)]], "gmx", true)
	if err then print(err) end
end)

concommand.Remove("gmx_file")
concommand.Add("gmx_file", function(_, _, _, path)
	if file.Exists(path, "MOD") then
		local lua = file.Read(path, "MOD")
		RunOnClient(lua)
		gmx.Print("Client running:", path)
	else
		gmx.Print("No such file:", path)
	end
end)

concommand.Remove("gmx_lua")
concommand.Add("gmx_lua", function(_, _, _, lua)
	RunOnClient(lua)
	gmx.Print("Client running:", lua)
end)

local CONSTANT_PROVIDERS = {}
function gmx.RegisterConstantProvider(name, fnOrValue)
	CONSTANT_PROVIDERS[name] = isfunction(fnOrValue)
		and function() return tostring(fnOrValue()) end
		or function() return tostring(fnOrValue) end
end

function gmx.PrependDependencies(code, deps)
	if not code then code = "" end
	if not deps then deps = {} end

	local outs = {}
	for _, dep in ipairs(deps) do
		local path = ("lua/gmx/client_state/%s.lua"):format(dep)
		if file.Exists(path, "MOD") then
			local content = file.Read(path, "MOD")
			table.insert(outs, content)
		end
	end

	table.insert(outs, code)
	return table.concat(outs, "\n")
end

function gmx.BuildConstantDeclarations()
	local lines = {}
	for const_name, const_provider in pairs(CONSTANT_PROVIDERS) do
		table.insert(lines, ("local %s = \"%s\""):format(const_name, const_provider()))
	end

	return table.concat(lines, "\n")
end

function gmx.RunOnClient(code, deps, omit_constants)
	local code_with_deps = gmx.PrependDependencies(code, deps)
	local final_code = omit_constants and code_with_deps or ("%s\n%s"):format(gmx.BuildConstantDeclarations(), code_with_deps)

	RunOnClient(final_code)
end

local MENU_SCRIPTS_PATH = "gmx/gmx_scripts/menu/"
for _, file_name in pairs(file.Find("lua/" .. MENU_SCRIPTS_PATH .. "*.lua", "MOD")) do
	include(MENU_SCRIPTS_PATH .. file_name)
	gmx.Print(("Running \"%s\""):format(file_name))
end

gmx.FlushInitConsoleBuffer()

-- mount all games
local GAMES = engine.GetGames()
table.sort(GAMES, function(a, b) return a.depot < b.depot end)

for _, game_data in pairs(GAMES) do
	if not game_data.installed then continue end
	if game_data.mounted then continue end

	engine.SetMounted(game_data.depot, true)
	gmx.Print("Mounting " .. game_data.title)
end

hook.Run("GMXInitialized")