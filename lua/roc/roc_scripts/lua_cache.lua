require("stringtable")

local HEADER_COLOR = Color(255, 0, 0)
local BODY_COLOR = Color(197, 53, 17)
local function roc_print(...)
	local args = {}
	for key, arg in pairs({ ... }) do
		args[key] = tostring(arg)
	end

	MsgC(HEADER_COLOR, "[ROC] ", BODY_COLOR, table.concat(args, "\t") .. "\n")
end

local function tohex(str)
	return str:gsub(".", function(char)
		return ("%02X"):format(char:byte())
	end)
end

local hash_cache
local function process_cached_file(path)
	local string_tbl = StringTable("client_lua_files")

	if hash_cache == nil then
		hash_cache = {}

		local tbl = string_tbl:GetTableStrings()
		for id, str in pairs(tbl) do
			if id ~= 0 then
				local cached_path = str:gsub("^lua/",""):gsub("^gamemodes/",""):gsub("%.lua$","")
				hash_cache[cached_path] = id
			end
		end
	end

	local num = hash_cache[path]
	local data = num and string_tbl:GetData(num)
	local hash = data and data:sub(1, 32) or ""

	return hash
end

local function get_data(hash)
	local path = "cache/lua/" .. hash:sub(1,40) .. ".lua"
	if not file.Exists(path, "MOD") then
		path = "cache/lua/" .. hash .. ".lua"
		if not file.Exists(path, "MOD") then
			return nil, "nofile: " .. tostring(path)
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
local function read_lua_cache(path)
	if isfunction(path) then path = debug.getinfo(path).source end

	path = path:gsub("^lua/",""):gsub("^gamemodes/",""):gsub("%.lua$","")

	local hash = hash_cache and tostring(hash_cache[path])
	if hash then
		local data, err = get_data(hash)
		if err then
			roc_print("error trying to open", path, err)
			return ""
		else
			return data
		end
	end

	hash = tostring(process_cached_file(path))
	if hash == BAD then
		roc_print("error trying to open", path, "BAD HASH")
		return ""
	end

	hash = tohex(hash):lower()
	local data, err = get_data(hash)
	if err then
		roc_print("error trying to open", path, err)
		return ""
	end

	hash_cache[path] = hash
	return data
end

-- convenience override
local old_file_read = file.Read
function file.Read(path, env)
	if env == "LUA" then
		return read_lua_cache(path)
	else
		return old_file_read(path, env)
	end
end