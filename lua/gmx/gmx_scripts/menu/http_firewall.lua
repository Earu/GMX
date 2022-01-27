local deny_rules = {}

hook.Add("OnHTTPRequest", "gmx_http_firewall", function(url, method)
	local domain = url:gsub("^https?://", ""):Split("/")[1]:Trim()
	local rule = deny_rules[domain]
	if rule then
		if rule.method == "*" then return true end
		if rule.method == method then return true end
	end
end)