require("stringtable")

gmx.SkidCheckDB = {}
http.Fetch("https://api.github.com/repos/MFSiNC/SkidCheck-2.0/git/trees/main?recursive=1", function(json, json_len, _, http_code)
	if http_code ~= 200 then return end
	if json_len == 0 then return end

	local skid_data = util.JSONToTable(json)
	if not skid_data then return end
	if not skid_data.tree then return end

	local content_data = {}
	for _, data in pairs(skid_data.tree) do
		if not data.path then continue end
		if not data.path:match("lua%/skidcheck%/sv%_SkidList%_[A-Z]%.lua") then continue end

		local content_url = ("https://raw.githubusercontent.com/%s/%s/%s"):format("MFSiNC/SkidCheck-2.0", "main", data.path)
		table.insert(content_data, { URL = content_url, Path = data.path })
	end

	for _, data in ipairs(content_data) do
		http.Fetch(data.URL, function(lua, lua_len, _, _http_code)
			if _http_code ~= 200 then return end
			if lua_len == 0 then return end

			local fn = CompileString(lua, data.Path)
			setfenv(fn, {
				pairs = pairs,
				HAC = {
					Skiddies = gmx.SkidCheckDB,
				}
			})

			local succ, err = pcall(fn)
			if not succ then gmx.Print(err) end
		end, gmx.Print)
	end
end, gmx.Print)

function gmx.GetConnectedPlayers()
	if not IsInGame() then return {} end

	local user_info = StringTable("userinfo")
	if not user_info then return {} end

	local ret = {}
	local player_data = user_info:GetTableData()
	for _, data in pairs(player_data) do
		if #data > 0 then
			local player_name = ("%q"):format(data:sub(1, 128):match("(.-)%z")):gsub("\"", "")
			local steamid = ("%q"):format(data:sub(128 + 5, 128 + 4 + 31):match("(.-)%z")):gsub("\"", "")

			ret[steamid] = player_name
		end
	end

	return ret
end

function gmx.CheckMaliciousUsers()
	local players = gmx.GetConnectedPlayers()
	local warned = false

	for steamid, player_name in pairs(players) do
		if gmx.SkidCheckDB[steamid] then
			if not warned then
				gmx.Print(("-"):rep(80))
			end

			gmx.Print("SkidCheck", ("Potential MALICIOUS user found %s \"%s\": %s"):format(steamid, player_name, gmx.SkidCheckDB[steamid]))
			warned = true
		end
	end

	if warned then
		gmx.Print(("-"):rep(80))
	end
end

hook.Add("ClientFullyInitialized", "gmx_player_trust", gmx.CheckMaliciousUsers)

local last_player_count = 0
timer.Create("gmx_player_trust", 1, 0, function()
	if not IsInGame() then return end
	local player_count = table.Count(gmx.GetConnectedPlayers())
	if player_count ~= last_player_count then
		gmx.CheckMaliciousUsers()
		last_player_count = player_count
	end
end)