require("fshook")

hook.Add("ShouldHideFile", GEN_NAME(), function(path)
	if path:StartsWith("garrysmod/lua/gmx") then return true end -- hide gmx files
	if path:StartsWith("garrysmod/lua/bin") then return true end -- hide modules

	return false
end)