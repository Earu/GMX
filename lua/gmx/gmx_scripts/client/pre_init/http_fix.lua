local rand = _G.math.random
local timer_create = _G.timer.Create
local timer_remove = _G.timer.Remove
local unpack = _G.unpack

local old_http = _G.HTTP
DETOUR(nil, "HTTP", old_http, function(req, ...)
	if not req.url then return old_http(req, ...) end

	local reply_index = rand(100, 2e4)
	MENU("gmx.HTTPReplyCode = " .. reply_index)
	MENU_HOOK("OnHTTPRequest", req.url, string.upper(req.method) or "GET", "", req.type or "text/plain", req.body)

	local time = 0
	local timer_name = "__" .. reply_index .. "__"
	local args = { req, ... }
	timer_create(timer_name, 1, 0, function()
		if _G[reply_index] ~= nil then
			if _G[reply_index] ~= true then
				old_http(unpack(args))
			end

			timer_remove(timer_name)
			return
		end

		time = time + 1
		if time >= 60 then
			timer_remove(timer_name)
		end
	end)

	return true
end)