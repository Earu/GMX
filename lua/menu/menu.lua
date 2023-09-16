if jit.arch ~= "x64" then
	include("_menu.lua")
end

include("menu/loading.lua")
include("menu_save.lua")
include("menu_demo.lua")
include("menu_addon.lua")
include("openurl.lua") -- called by the engine for permissions and gui.OpenURL
include("menu_dupe.lua") -- called by the engine, cant remove

include("gmx/gmx.lua")