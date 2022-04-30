if jit.arch ~= "x64" then
	include("_menu.lua")
end

include("menu/loading.lua")
include("menu_save.lua")
include("menu_demo.lua")
include("menu_addon.lua")
include("menu_dupe.lua") -- called by the engine, cant remove
include("errors.lua") -- "something is creating script errors pop up"

include("gmx/gmx.lua")
require("xconsole")
