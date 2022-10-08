if not system.IsWindows() then return end

require("http_filter")

local firewall_rules = {
	-- dev stuff
	["gitlab.com"]            = { method = "*", type = "ALLOW" },
	["githubusercontent.com"] = { method = "*", type = "ALLOW" },
	["githubassets.com"]      = { method = "*", type = "ALLOW" },
	["github.com"]            = { method = "*", type = "ALLOW" },
	["github.io"]             = { method = "*", type = "ALLOW" },

	-- services
	["windows.net"]                    = { method = "GET", type = "ALLOW" },
	["imgur.com"]                      = { method = "*",   type = "ALLOW" },
	["puu.sh"]                         = { method = "GET", type = "ALLOW" },
	["akamaihd.net"]                   = { method = "GET", type = "ALLOW" },
	["dropboxusercontent.com"]         = { method = "GET", type = "ALLOW" },
	["dropbox.com"]                    = { method = "GET", type = "ALLOW" },
	["onedrive.com"]                   = { method = "*",   type = "ALLOW" },
	["pastebin.com"]                   = { method = "GET", type = "ALLOW" },
	["drive.google.com"]               = { method = "GET", type = "ALLOW" },
	["discordapp.com"]                 = { method = "GET", type = "ALLOW" },
	["discordapp.net"]                 = { method = "GET", type = "ALLOW" },
	["cdn.cloudflare.steamstatic.com"] = { method = "*",   type = "ALLOW" },
	["steamcommunity.com"]             = { method = "GET", type = "ALLOW" },
	["keybase.pub"]                    = { method = "GET", type = "ALLOW" },
	["wikimedia.org"]                  = { method = "GET", type = "ALLOW" },
	["ip-api.com"]                     = { method = "GET", type = "ALLOW" },
	["api.sunrise-sunset.org"]         = { method = "GET", type = "ALLOW" },

	-- api & others
	["translate.yandex.net"] = { method = "GET", type = "ALLOW" },
	["tweetjs.com "]         = { method = "*",   type = "ALLOW" },
	["twemoji.maxcdn.com"]   = { method = "GET", type = "ALLOW" },
	["api.betterttv.net"]    = { method = "GET", type = "ALLOW" },
	["api.frankerfacez.com"] = { method = "GET", type = "ALLOW" },
	["api.allorigins.win"]   = { method = "*",   type = "ALLOW" },

	-- metastruct
	["g1.metastruct.uk.to"] = { method = "*",   type = "ALLOW" },
	["g2.metastruct.uk.to"] = { method = "*",   type = "ALLOW" },
	["metastruct.net"]      = { method = "*",   type = "ALLOW" },
	["sprays.xerasin.com"]  = { method = "*",   type = "ALLOW" },
	["0.0.0.0"]             = { method = "GET", type = "ALLOW" }, -- Metastruct weird override thing
	["threekelv.in"]        = { method = "GET", type = "ALLOW" },
}

local function get_domain(sub_domain)
	-- check if its an IP address
	if sub_domain:match("[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?%.[0-9][0-9]?[0-9]?%.") then
		return sub_domain
	end

	-- domain name + domain extension (.com, .net, etc)
	local chunks = sub_domain:Split(".")
	if #chunks == 1 then return sub_domain end -- localhost, or other weirdness?

	return chunks[#chunks - 1]:Trim() .. "." .. chunks[#chunks]:Trim()
end

local unknown_domains = {}
hook.Add("OnHTTPRequest", "gmx_http_firewall", function(url, method, headers, content_type, body)
	if not url then return end

	local sub_domain = url:gsub("^https?://", ""):Split("/")[1]:Trim():gsub(":[0-9]+$", "")
	local domain = get_domain(sub_domain)
	local rule = firewall_rules[sub_domain] or firewall_rules[domain] -- priority to sub domain
	if rule then
		if rule.type == "DENY" and (rule.method == "*" or rule.method == method) then
			gmx.Print("Firewall", "HTTP request blocked:", method, url)
			return true
		end

		if rule.type == "ALLOW" and rule.method ~= method and rule.method ~= "*" then
			gmx.Print("Firewall", "HTTP request blocked:", method, url)
			return true
		end
	else
		if not unknown_domains[domain] then
			gmx.Print("Firewall", "Blocking HTTP request because no rule was defined for: ", domain)
			unknown_domains[domain] = {}
		end

		table.insert(unknown_domains[domain], {
			URL = url,
			Method = method,
		})

		return true
	end
end)

concommand.Add("gmx_unknown_domains_requests", function()
	for domain, request_datas in pairs(unknown_domains) do
		MsgC(gmx.Colors.Accent, "- " .. domain .. " -\n")
		for _, request_data in ipairs(request_datas) do
			MsgC(gmx.Colors.Text, "\t- ", gmx.Colors.TextAlternative, request_data.Method, gmx.Colors.Text, "\t" .. request_data.URL .. "\n")
		end
	end
end)