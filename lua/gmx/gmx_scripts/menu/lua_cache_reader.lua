require("stringtable")

local function normalize_path(path)
	if path:match("^addons/.+/lua/") then
		path = path:gsub("^addons/.+/lua/", "")
	elseif path:match("^lua/") then
		path = path:gsub("^lua/", "")
	elseif path:match("^gamemodes/") then
		path = path:gsub("^gamemodes/", "")
	end

	return path
end

local function get_server_lua_files()
	if not IsInGame() then return {} end

	local success, string_tbl = pcall(StringTable, "client_lua_files")
	if not success then
		gmx.Print("Unable to load string table for client_lua_files")
		return {}
	end

	local server_file_paths = {}
	local tbl = string_tbl:GetTableStrings()
	for _, file_path in pairs(tbl) do
		if file_path == "paths" then continue end
		table.insert(server_file_paths, {
			VirtualPath = normalize_path(file_path),
			Path = file_path
		})
	end

	return server_file_paths
end

local function tohex(str)
	return str:gsub(".", function(char)
		return ("%02X"):format(char:byte())
	end)
end

local path_cache
local function process_cached_file(path)
	if not IsInGame() then return "" end

	local success, string_tbl = pcall(StringTable, "client_lua_files")
	if not success then
		gmx.Print("Unable to load string table for client_lua_files")
		return ""
	end

	if path_cache == nil then
		path_cache = {}

		local tbl = string_tbl:GetTableStrings()
		for id, str in pairs(tbl) do
			if id ~= 0 then
				local cached_path = str:gsub("^lua/",""):gsub("^gamemodes/",""):gsub("%.lua$","")
				path_cache[cached_path] = id
			end
		end
	end

	local num = path_cache[path]
	local data = num and string_tbl:GetData(num)
	local hash = data and data:sub(1, 32) or ""

	return hash
end

local function get_data(hash)
	local path = "cache/lua/" .. hash:sub(1,40) .. ".lua"
	if not file.Exists(path, "MOD") then
		path = "cache/lua/" .. hash .. ".lua"
		if not file.Exists(path, "MOD") then
			return nil, "No such file: " .. tostring(path)
		end
	end

	local contents = file.Read(path, "MOD")
	local left, right = contents:sub(1, hash:len() / 2), contents:sub(hash:len() / 2 + 1, -1)
	if tohex(left):lower() ~= hash then return nil, "badhash?\n " .. tohex(left) .. "\n " .. hash end

	local data = right
	if not data then return nil, "Invalid data" end

	data = util.Decompress(data)
	if not data then return nil, "Invalid after util.Decompress" end

	if data:sub(-1) == "\0" then
		data = data:sub(1,-2)
	end

	return data
end

local BAD = ("\0"):rep(32)
local cache = {}
local function read_lua_cache(path, print_errors)
	if isfunction(path) then path = debug.getinfo(path).source end
	if print_errors == nil then print_errors = true end

	path = path:gsub("^lua/",""):gsub("^gamemodes/",""):gsub("%.lua$","")

	local hash = cache[path]
	if hash then
		local data, err = get_data(hash)
		if err then
			if print_errors then
				gmx.Print("Error trying to open", path, err)
			end
			return ""
		else
			return data
		end
	end

	hash = process_cached_file(path)
	if hash == BAD then
		if print_errors then
			gmx.Print("Error trying to open", path, "BAD HASH")
		end

		return ""
	end

	hash = tohex(hash):lower()
	local data, err = get_data(hash)
	if err then
		if print_errors then
			gmx.Print("Error trying to open", path, err)
		end

		return ""
	end

	cache[path] = hash
	return data
end

gmx.GetServerLuaFiles = get_server_lua_files

local path_lookup_cache = {}
local path_lookup_cached = false
function gmx.ReadFromLuaCache(path, print_errors)
	local code = read_lua_cache(path, print_errors)
	if code and #code > 0 then return code end

	if not IsInGame() then return "" end

	if not path_lookup_cached then
		local file_paths = get_server_lua_files()
		for _, path_info in pairs(file_paths) do
			path_lookup_cache[path_info.VirtualPath] = path_info.Path
		end

		path_lookup_cached = true
	end

	local real_path = path_lookup_cache[path]
	code = read_lua_cache(real_path, print_errors)
	if code and #code > 0 then return code end

	return file.Read(real_path, "MOD")
end

hook.Add("ClientStateDestroyed", "gmx_clear_path_lookup_cache", function()
	path_lookup_cache = {}
	path_lookup_cached = false
end)