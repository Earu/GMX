gmx.Require("stringtable")

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

	local user_info = StringTable and StringTable("userinfo")
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

local connected_players = {}
local last_player_count = 0
timer.Create("gmx_player_trust", 1, 0, function()
	local new_connected_players = gmx.GetConnectedPlayers()
	local player_count = table.Count(new_connected_players)
	if player_count ~= last_player_count then
		for steamid, player_name in pairs(new_connected_players) do
			if not connected_players[steamid] then
				connected_players[steamid] = player_name
				hook.Run("GMXPlayerConnected", steamid, player_name)
			end
		end

		for steamid, player_name in pairs(connected_players) do
			if not new_connected_players[steamid] then
				connected_players[steamid] = nil
				hook.Run("GMXPlayerDisconnected", steamid, player_name)
			end
		end

		last_player_count = player_count
	end
end)

local ignored_resons = {
	"member of hack/troll group"
}

local function is_valid_reason(reason)
	for _, ignored_reason in ipairs(ignored_resons) do
		if reason:lower():find(ignored_reason, 1, true) then return false end
	end

	return true
end

hook.Add("GMXPlayerConnected", "gmx_check_malicious", function(steamid, player_name)
	local reason = gmx.SkidCheckDB[steamid]
	if reason and is_valid_reason(reason) then
		gmx.Print("SkidCheck", ("Potential MALICIOUS user found %s \"%s\": %s"):format(steamid, player_name, reason))
	end
end)

concommand.Add("gmx_check_malicious", function()
	local players = gmx.GetConnectedPlayers()
	for steamid, player_name in pairs(players) do
		local reason = gmx.SkidCheckDB[steamid]
		if reason and is_valid_reason(reason)  then
			gmx.Print("SkidCheck", ("Potential MALICIOUS user found %s \"%s\": %s"):format(steamid, player_name, reason))
		end
	end
end)

-- dont do that, too obvious
--[[timer.Create("gmx_fake_name", 1, 0, function()
	if not CNetChan then return end

	local chan = CNetChan()
	if not chan then return end

	if gmx.IsHostWhitelisted() then return end

	local buffer = chan:GetReliableBuffer()
	if not buffer then return end

	buffer:WriteUInt(net_SetConVar, NET_MESSAGE_BITS) -- message type
	buffer:WriteByte(1) -- convar count
	buffer:WriteString("name") -- convar name
	buffer:WriteString(gmx.GenerateUID(6)) -- convar value
end)]]