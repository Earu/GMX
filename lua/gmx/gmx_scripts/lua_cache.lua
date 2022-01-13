require("stringtable")

local HEADER_COLOR = Color(255, 157, 0)
local BODY_COLOR = Color(255, 196, 0)
local function gmx_print(...)
	local args = {}
	for key, arg in pairs({ ... }) do
		args[key] = tostring(arg)
	end

	MsgC(HEADER_COLOR, "[GMX] ", BODY_COLOR, table.concat(args, "\t") .. "\n")
end

local function tohex(str)
	return str:gsub(".", function(char)
		return ("%02X"):format(char:byte())
	end)
end

local path_cache
local function process_cached_file(path)
	local string_tbl = StringTable("client_lua_files")

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
local cache = {}
local function read_lua_cache(path)
	if isfunction(path) then path = debug.getinfo(path).source end

	path = path:gsub("^lua/",""):gsub("^gamemodes/",""):gsub("%.lua$","")

	local hash = cache[path]
	if hash then
		local data, err = get_data(hash)
		if err then
			gmx_print("error trying to open", path, err)
			return ""
		else
			return data
		end
	end

	hash = process_cached_file(path)
	if hash == BAD then
		gmx_print("error trying to open", path, "BAD HASH")
		return ""
	end

	hash = tohex(hash):lower()
	local data, err = get_data(hash)
	if err then
		gmx_print("error trying to open", path, err)
		return ""
	end

	cache[path] = hash
	return data
end

-- convenience override
local old_file_read = file.Read
function file.Read(path, env)
	if env == "LUA" then
		local ret = read_lua_cache(path)
		if not ret or #ret == 0 then
			ret = old_file_read(path, env)
		end

		return ret
	else
		return old_file_read(path, env)
	end
end

require("zip")

local srv_ip = game.GetIPAddress()
local archives_path = ("Archives/%s"):format(srv_ip:gsub("%.","_"):gsub("%:", "_"))
file.CreateDir(archives_path)

local function create_tmp_package(res, dir)
	res = res or {}

	local files, dirs = file.Find(dir and dir .. "/*" or "*", "LUA")
	for _, f in pairs(files or {}) do
		if not f:EndsWith(".lua") then continue end

		local virtual_file_path = dir and dir .. "/" .. f or f
		local code = read_lua_cache(virtual_file_path)
		if not code or #code == 0 then continue end -- if we cant read content then dont dump, its useless

		local real_path = ("%s/tmp/%s.txt"):format(archives_path, virtual_file_path)
		local parent_dir = real_path:GetPathFromFilename()

		file.CreateDir(parent_dir)
		file.Write(real_path, code)

		table.insert(res, {
			Path = real_path,
			ArchivePath = virtual_file_path,
		})
	end

	for _, d in pairs(dirs or {}) do
		create_tmp_package(res, dir and dir .. "/" .. d or d)
	end

	return res
end

local zip_path = ("data/%s/%s.zip"):format(archives_path, os.date("%x"):gsub("/", "_"))
local package_path = ("data/%s/tmp/"):format(archives_path)

create_tmp_package()
Zip(zip_path, package_path, true)