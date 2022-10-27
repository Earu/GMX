local cache = {}

local old_util_GetModelMeshes = _G.util.GetModelMeshes
DETOUR(nil, "GetModelMeshes", old_util_GetModelMeshes, function(model, lod, body_grp_mask)
	local key = string.format("%s_%d_%d", model, lod or 0, body_grp_mask or 0)
	if cache[key] then return cache[key] end

	local data = old_util_GetModelMeshes(model, lod, body_grp_mask)
	cache[key] = data

	return data
end)