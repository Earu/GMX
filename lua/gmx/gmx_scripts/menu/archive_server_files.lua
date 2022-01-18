require("zip")

local function create_tmp_package(base_path)
	local files = gmx.GetServerLuaFiles()
	for _, path_info in pairs(files) do
		local code = gmx.ReadFromLuaCache(path_info.VirtualPath, true)
		if not code or #code == 0 then
			code = " -- could not read this file"
		end

		local real_path = ("%s/tmp/%s.txt"):format(base_path, path_info.VirtualPath)
		local parent_dir = real_path:GetPathFromFilename()

		file.CreateDir(parent_dir)
		file.Write(real_path, code)
	end
end

hook.Add("ClientFullyInitialized", "gmx_archive_lua_files", function(srv_ip, host_name)
	local short_host_name = host_name:gsub("[%s%-%/%\\%[%]%:]", "_"):gsub("_+", "_"):gsub("_$", "")
	local archives_path = ("Archives/%s_%s"):format(srv_ip:gsub("%.","_"):gsub("%:", "_"), short_host_name)
	file.CreateDir(archives_path)

	local zip_path = ("data/%s/%s.zip"):format(archives_path, os.date("%x"):gsub("/", "_"))
	local package_path = ("data/%s/tmp/"):format(archives_path)
	create_tmp_package(archives_path)

	file.Write(("%s/metadata.json"):format(archives_path), util.TableToJSON({
		date = os.date("%x"),
		address = srv_ip,
		hostname = short_host_name,
		map = game.GetMap(),
	}, true))

	Zip(zip_path, package_path, true)
end)