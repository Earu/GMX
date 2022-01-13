hook.Add("PostClientLuaInit", "no_errors", function(custom_init_scripts)
	table.insert(custom_init_scripts, [[
		require("luaerror")

		luaerror.EnableCompiletimeDetour(true)
		luaerror.EnableRuntimeDetour(true)

		local COLOR_RED = Color(255, 0, 0, 255)
		hook.Add("LuaError", "no_errors", function(_, fullerror)
			MsgC(COLOR_RED, fullerror, "\n")
			return false
		end)
	]])
end)