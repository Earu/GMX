gmx.AddClientInitScript([[
	require("luaerror")

	luaerror.EnableCompiletimeDetour(true)
	luaerror.EnableRuntimeDetour(true)

	local COLOR_RED = Color(255, 0, 0, 255)
	hook.Add("LuaError", "no_errors", function(_, fullerror)
		MsgC(COLOR_RED, fullerror, "\n")
		return true
	end)

	hook.Add("ShutDown", "no_errors", function()
		luaerror.EnableRuntimeDetour(false)
		luaerror.EnableCompiletimeDetour(false)
		hook.Remove("Luaerror", "no_errors")
	end)

	-- override the default errors handler
	-- how do i override the original error function without breaking it?
	function ErrorNoHalt(...)
		MsgC(COLOR_RED, ...)
	end

	function ErrorNoHaltWithStack(...)
		MsgC(COLOR_RED, ...)
	end
]])