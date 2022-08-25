if not system.IsWindows() then return end

require("http_filter")

local firewall_rules = {
	-- weird
	["garrysmod.io"]            = { method = "*", type = "DENY" },
	["dl.cloudsmith.io"]        = { method = "*", type = "DENY" },
	["molly.network"]           = { method = "*", type = "DENY" },
	["www.models-resource.com"] = { method = "*", type = "DENY" },
	["appdomain.cloud"]         = { method = "*", type = "DENY" },

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
	["rain.piaempi.gay"]     = { method = "GET", type = "ALLOW" },
	["zombie.computer"]      = { method = "GET", type = "ALLOW" },
	["api.allorigins.win"]   = { method = "*", type = "ALLOW" },

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
	return chunks[#chunks - 1]:Trim() .. "." .. chunks[#chunks]:Trim()
end

hook.Add("OnHTTPRequest", "gmx_http_firewall", function(url, method, headers, content_type, body)
	if not url then return end

	local sub_domain = url:gsub("^https?://", ""):Split("/")[1]:Trim():gsub(":[0-9]+$", "")
	local domain = get_domain(sub_domain)
	local rule = firewall_rules[sub_domain] or firewall_rules[domain] -- priority to sub domain
	if rule then
		if rule.type == "DENY" and (rule.method == "*" or rule.method == method) then
			gmx.Print("HTTP request blocked:", method, url)
			return true
		end

		if rule.type == "ALLOW" and rule.method ~= method and rule.method ~= "*" then
			gmx.Print("HTTP request blocked:", method, url)
			return true
		end
	else
		gmx.Print("Blocking HTTP request because no rule was defined:", method, domain, sub_domain, url)
		return true
	end
end)