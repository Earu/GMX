local string_gsub = _G.string.gsub
local string_format = _G.string.format
local file_exists = _G.file.Exists
local file_create_dir = _G.file.CreateDir
local file_open = _G.file.Open
local util_json_to_table = _G.util.JSONToTable
local util_table_to_json = _G.util.TableToJSON

local function file_read(file_name)
	local f = file_open(file_name, "rb", "DATA")
	if not f then return end

	local str = f:Read(f:Size())
	f:Close()

	return str or ""
end

function file_write(file_name, contents)
	local f = file_open(file_name, "wb", "DATA")
	if not f then return end

	f:Write(contents)
	f:Close()
end

local cache = {}
local old_util_GetModelMeshes = _G.util.GetModelMeshes
DETOUR(_G.util, "GetModelMeshes", old_util_GetModelMeshes, function(model, lod, body_grp_mask)
	local key = string_gsub(string_format ("%s_%d_%d", model, lod or 0, body_grp_mask or 0), "[/\\]+", "_")
	if cache[key] then return cache[key] end

	local path = string_format("getmodelmeshes_cache/%s.json", key)
	if file_exists(path, "DATA") then
		local contents = file_read(path)
		if contents and #contents > 0 then
			cache[key] = util_json_to_table(contents)
			return cache[key]
		end
	end

	local data = old_util_GetModelMeshes(model, lod, body_grp_mask)
	cache[key] = data

	if not file_exists("getmodelmeshes_cache", "DATA") then
		file_create_dir("getmodelmeshes_cache")
	end

	file_write(path, util_table_to_json(data))

	return data
end)