require("http_filter")

local firewall_rules = {
	-- weird
	["garrysmod.io"]     = { method = "*", type = "DENY" },
	["dl.cloudsmith.io"] = { method = "*", type = "DENY" },

	-- dev stuff
	["dl.dropboxusercontent.com"] = { method = "GET", type = "ALLOW" },
	["api.github.com"]            = { method = "*",   type = "ALLOW" },
	["raw.githubusercontent.com"] = { method = "*",   type = "ALLOW" },
	["gitlab.com"]                = { method = "*",   type = "ALLOW" },

	-- trusted
	["api.betterttv.net"]              = { method = "GET", type = "ALLOW" },
	["translate.yandex.net"]           = { method = "GET", type = "ALLOW" },
	["api.frankerfacez.com"]           = { method = "GET", type = "ALLOW" },
	["drive.google.com"]               = { method = "GET", type = "ALLOW" },
	["i.imgur.com"]                    = { method = "GET", type = "ALLOW" },
	["sprays.xerasin.com"]             = { method = "*",   type = "ALLOW" },
	["rain.piaempi.gay"]               = { method = "GET", type = "ALLOW" },
	["cdn.cloudflare.steamstatic.com"] = { method = "*",   type = "ALLOW" },

	-- metastruct
	["g1.metastruct.net"]    = { method = "*",   type = "ALLOW" },
	["g2.metastruct.net"]    = { method = "*",   type = "ALLOW" },
	["g2cf.metastruct.net"]  = { method = "*",   type = "ALLOW" },
	["g3.metastruct.net"]    = { method = "*",   type = "ALLOW" },
	["metastruct.github.io"] = { method = "GET", type = "ALLOW" },
}

hook.Add("OnHTTPRequest", "gmx_http_firewall", function(url, method)
	local domain = url:gsub("^https?://", ""):Split("/")[1]:Trim()
	local rule = firewall_rules[domain]
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
		gmx.Print("Blocking HTTP request because no rule was defined:", method, domain, url)
		return true
	end
end)