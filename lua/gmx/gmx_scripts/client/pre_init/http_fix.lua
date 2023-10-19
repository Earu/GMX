local rand = _G.math.random
local timer_create = _G.timer.Create
local timer_remove = _G.timer.Remove
local string_upper = _G.string.upper
local unpack = _G.unpack
local type = _G.type
local FindMetaTable = _G.FindMetaTable
local PANEL = FindMetaTable("Panel")
local PANEL_is_valid = PANEL.IsValid

local function http_detour(native_fn, args, url, method, content_type, body)
	local reply_index = rand(-2e9, 2e9)
	MENU("gmx.HTTPReplyCode = " .. reply_index)
	MENU_HOOK("OnHTTPRequest", url, string_upper(method or "GET"), "", content_type or "text/plain", body or "", true)

	local time = 0
	local timer_name = "__" .. reply_index .. "__"
	timer_create(timer_name, 0.2, 0, function()
		if _G[reply_index] ~= nil then
			if _G[reply_index] ~= true then
				local skip = false
				if type(args[1]) == "Panel" and not PANEL_is_valid(args[1]) then
					skip = true
				end

				if not skip then
					native_fn(unpack(args))
				end
			end

			_G[reply_index] = nil
			timer_remove(timer_name)
			return
		end

		time = time + 0.2
		if time >= 60 then
			_G[reply_index] = nil
			timer_remove(timer_name)
		end
	end)
end

local old_http = _G.HTTP
DETOUR(nil, "HTTP", old_http, function(req, ...)
	if not req.url then return old_http(req, ...) end

	http_detour(old_http, { req, ... }, req.url, req.method, req.type, req.body)

	return true
end)

local old_gui_openurl = _G.gui.OpenURL
DETOUR(_G.gui, "OpenURL", old_gui_openurl, function(url, ...)
	if type(url) ~= "string" then return old_gui_openurl(url, ...) end

	http_detour(old_gui_openurl, { url, ... }, url, "GET", "text/html", nil)
end)

local old_sound_playurl = _G.sound.PlayURL
DETOUR(_G.sound, "PlayURL", old_sound_playurl, function(url, ...)
	if type(url) ~= "string" then return old_sound_playurl(url, ...) end

	http_detour(old_sound_playurl, { url, ... }, url, "GET", "application/octet-stream", nil)
end)

local old_panel_openurl = PANEL.OpenURL
DETOUR(PANEL, "OpenURL", old_panel_openurl, function(self, url, ...)
	if type(url) ~= "string" then return old_panel_openurl(self, url, ...) end

	http_detour(old_panel_openurl, { self, url, ... }, url, "GET", "text/html", nil)
end)

local old_panel_seturl = PANEL.SetURL
DETOUR(PANEL, "SetURL", old_panel_seturl, function(self, url, ...)
	if type(url) ~= "string" then return old_panel_seturl(self, url, ...) end

	http_detour(old_panel_seturl, { self, url, ... }, url, "GET", "text/html", nil)
end)