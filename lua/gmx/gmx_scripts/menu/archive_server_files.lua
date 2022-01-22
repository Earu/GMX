require("zip")

local function create_tmp_package(base_path)
	local files = gmx.GetServerLuaFiles()
	for _, path_info in pairs(files) do
		local code = gmx.ReadFromLuaCache(path_info.VirtualPath, false)
		if not code or #code == 0 then
			code = " -- could not read this file"
		end

		local real_path = ("%s/tmp/%s.txt"):format(base_path, path_info.VirtualPath)
		local parent_dir = real_path:GetPathFromFilename()

		file.CreateDir(parent_dir)
		file.Write(real_path, code)
	end
end

local can_archive = false
local short_host_name, archives_path, zip_path, package_path, server_ip
local function archive_lua_files()
	if not can_archive then
		gmx.Print("Cannot dump any files right now")
		return
	end

	file.CreateDir(archives_path)
	create_tmp_package(archives_path)
	file.Write(("%s/metadata.json"):format(archives_path), util.TableToJSON({
		date = os.date("%x"),
		address = server_ip,
		hostname = short_host_name,
		map = game.GetMap(),
	}, true))

	Zip(zip_path, package_path, true)
end

concommand.Add("gmx_archive_lua_files", archive_lua_files)

hook.Add("ClientFullyInitialized", "gmx_archive_lua_files", function(srv_ip, host_name)
	short_host_name = host_name:gsub("[%s%-%/%\\%[%]%:]", "_"):gsub("_+", "_"):gsub("_$", "")
	archives_path = ("Archives/%s_%s"):format(srv_ip:gsub("%.","_"):gsub("%:", "_"), short_host_name)
	zip_path = ("data/%s/%s.zip"):format(archives_path, os.date("%x"):gsub("/", "_"))
	package_path = ("data/%s/tmp/"):format(archives_path)
	server_ip = srv_ip

	can_archive = true
	archive_lua_files()
end)

hook.Add("ClientStateDestroyed", "gmx_archive_lua_files", function()
	can_archive = false
end)