require("luaerror")

local luaerror = _G.luaerror
luaerror = nil -- dont want none of that global stuff

luaerror.EnableCompiletimeDetour(true)
luaerror.EnableRuntimeDetour(true)

local COLOR_RED = Color(255, 0, 0, 255)
hook.Add("LuaError", GMX_HANDLE, function(_, fullerror)
	MsgC(COLOR_RED, fullerror, "\n")
	return true
end)

hook.Add("ShutDown", GMX_HANDLE, function()
	luaerror.EnableRuntimeDetour(false)
	luaerror.EnableCompiletimeDetour(false)
	hook.Remove("Luaerror", GMX_HANDLE)
end)

-- override the default errors handler
-- how do i override the original error function without breaking it?
function ErrorNoHalt(...)
	MsgC(COLOR_RED, ...)
end

function ErrorNoHaltWithStack(...)
	MsgC(COLOR_RED, ...)
end