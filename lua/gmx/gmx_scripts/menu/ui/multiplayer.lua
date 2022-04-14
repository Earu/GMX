local function parse_host_name_tags(host_name)
	local tags = {}
	local function add_tag(tag)
		tag = tag:Trim()
		if #tag > 1 and #tag < 15 then
			table.insert(tags, tag)
		end
	end

	local start_index, _ = host_name:find("[%|%,%-]")
	local end_index = 1
	while start_index do
		local tag = end_index == 1
			and host_name:sub(end_index, start_index - 1):Trim()
			or host_name:sub(end_index, start_index - 1):gsub("[%[%]%(%)]", ""):Trim()
			add_tag(tag)

		end_index = start_index + 1
		start_index, _ = host_name:find("[%|%,%-]", end_index)
	end

	local last_tag = host_name:sub(end_index, #host_name):gsub("[%[%]%(%)]", ""):Trim()
	add_tag(last_tag)

	local explicit_tag_patterns = {
		"%[(.+)%]", "%((.+)%)", "%{(.+)%}", "%<(.+)%>",
		"%[(.+)$", "%((.+)$", "%{(.+)$", "%<(.+)$",
	}

	local actual_host_name = (table.remove(tags, 1) or host_name)
	for _, tag_pattern in ipairs(explicit_tag_patterns) do
		actual_host_name = actual_host_name:gsub(tag_pattern, function(tag)
			add_tag(tag)
			return ""
		end)
	end

	return actual_host_name, tags
end

local function fetch_servers(srv_type, callback)
	local servers = {}
	serverlist.Query({
		Type = srv_type,
		Callback = function(ping, host_name, description, map_name, ply_count, max_ply_count, bot_ply_count, has_password, workshop_id, ip_address, gamemode)
			local actual_host_name, tags = parse_host_name_tags(host_name)
			table.insert(servers, {
				Ping = ping,
				FullHostName = host_name,
				HostName = actual_host_name,
				Tags = tags,
				Description = description,
				Map = map_name,
				PlayerCount = ply_count,
				MaxPlayerCount = max_ply_count,
				BotPlayerCount = bot_ply_count,
				HasPassword = has_password,
				WorkshopID = workshop_id,
				IPAddress = ip_address,
				Gamemode = gamemode,
			})
		end,
		Finished = function()
			callback(servers)
		end,
	})
end

gmx.FetchServers = fetch_servers