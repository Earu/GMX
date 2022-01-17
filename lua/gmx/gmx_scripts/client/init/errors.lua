require("luaerror")

luaerror.EnableCompiletimeDetour(true)
luaerror.EnableRuntimeDetour(true)

local COLOR_RED = Color(255, 0, 0, 255)
hook.Add("LuaError", GEN_NAME(), function(_, fullerror)
	MsgC(COLOR_RED, fullerror, "\n")
	return true
end)

local hook_name = GEN_NAME()
hook.Add("ShutDown", hook_name, function()
	luaerror.EnableRuntimeDetour(false)
	luaerror.EnableCompiletimeDetour(false)
	hook.Remove("Luaerror", hook_name)
end)

-- override the default errors handler
-- how do i override the original error function without breaking it?
function ErrorNoHalt(...)
	MsgC(COLOR_RED, ...)
end

function ErrorNoHaltWithStack(...)
	MsgC(COLOR_RED, ...)
end