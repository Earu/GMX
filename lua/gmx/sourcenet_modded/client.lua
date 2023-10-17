require("sourcenet")

NET_HOOKS = NET_HOOKS or {
	attach = {},
	detach = {}
}

NET_ATTACHED = false

function HookNetChannel(...)
	for _, arg in pairs({...}) do
		local name = arg.name:gsub("::", "_")
		local exists = false

		for _, nethook in pairs(NET_HOOKS.attach) do
			if nethook.name == name then
				exists = true
				break
			end
		end

		if not exists then
			table.insert(NET_HOOKS.attach, {
				name = name,
				hook = _G["Attach__" .. name],
				func = v.func,
				args = v.args,
				nochan = v.nochan
			})

			table.insert(NET_HOOKS.detach, {
				name = name,
				hook = _G["Detach__" .. name],
				func = v.func,
				args = v.args,
				nochan = v.nochan
			})
		end
	end

	local function StandardNetHook(netchan, nethook)
		local args = {}

		if nethook.func then
			table.insert(args, nethook.func(netchan))
		elseif not nethook.nochan then
			table.insert(args, netchan)
		end

		if nethook.args then
			for _, arg in pairs(nethook.args) do
				table.insert(args, arg)
			end
		end

		nethook.hook(unpack(args))
	end

	local function AttachNetChannel(netchan)
		if NET_ATTACHED then return false end
		if not netchan then return false end

		Attach__CNetChan_Shutdown(netchan)
		NET_ATTACHED = true

		for _, nethook in pairs(NET_HOOKS.attach) do
			StandardNetHook(netchan, nethook)
		end

		return true
	end

	local function DetachNetChannel(netchan)
		if not NET_ATTACHED then return false end
		if not netchan then return false end

		Detach__CNetChan_Shutdown(netchan)
		NET_ATTACHED = false

		for _, nethook in pairs(NET_HOOKS.detach) do
			StandardNetHook(netchan, nethook)
		end

		return true
	end

	if not AttachNetChannel(CNetChan()) then
		-- Wait until channel is created
		hook.Add("Think", "CreateNetChannel", function()
			local netchan = CNetChan()

			if netchan ~= nil and AttachNetChannel(netchan) then
				hook.Remove("Think", "CreateNetChannel")
			end
		end)
	end

	hook.Add("PreNetChannelShutdown", "DetachHooks", function(netchan, reason)
		DetachNetChannel(netchan)
	end)
end