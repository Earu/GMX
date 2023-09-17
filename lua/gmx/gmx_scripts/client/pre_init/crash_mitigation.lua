local cache = {}

local old_util_GetModelMeshes = _G.util.GetModelMeshes
DETOUR(_G.util, "GetModelMeshes", old_util_GetModelMeshes, function(model, lod, body_grp_mask)
	local key = string.gsub(string.format("%s_%d_%d", model, lod or 0, body_grp_mask or 0), "[/\\]+", "_")
	if cache[key] then return cache[key] end

	local path = string.format("getmodelmeshes_cache/%s.json", key)
	if file.Exists(path, "DATA") then
		local contents = file.Read(path, "DATA")
		if contents and #contents > 0 then
			cache[key] = util.JSONToTable(contents)
			return cache[key]
		end
	end

	local data = old_util_GetModelMeshes(model, lod, body_grp_mask)
	cache[key] = data

	if not file.Exists("getmodelmeshes_cache", "DATA") then
		file.CreateDir("getmodelmeshes_cache")
	end

	file.Write(path, util.TableToJSON(data))

	return data
end)