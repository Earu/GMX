require("luaerror")

local luaerror = _G.luaerror

-- dont want none of that global stuff
local function remove_global_stuff()
	_G.luaerror = nil

	if _G._MODULES and _G._MODULES.luaerror then
		_G._MODULES.luaerror = nil
		timer.Simple(0.5, remove_global_stuff)
	end
end

remove_global_stuff()

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
DETOUR(nil, "ErrorNoHalt", ErrorNoHalt, function(...)
	MsgC(COLOR_RED, ...)
end)

DETOUR(nil, "ErrorNoHaltWithStack", ErrorNoHaltWithStack, function(...)
	MsgC(COLOR_RED, ...)
end)