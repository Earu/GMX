# /!\ RUN AS ADMIN /!\

$gmodPath = Read-Host -Prompt 'Input Garrys Mod path'
$symLinks = "gmx", "menu/menu.lua", "menu/_menu.lua"
Foreach ($link in $symLinks) {
	$targetPath = Join-Path -Path $gmodPath -ChildPath "lua/$link"
	$sourcePath = Join-Path -Path "./lua" -ChildPath "$link"

	Write-Host "Creating symlink $sourcePath -> $targetPath"

	if ((Test-Path -Path $targetPath)) {
		(Get-Item $targetPath).Delete()
	}

	try {
		New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath
		Write-Host "Symlink created" -ForegroundColor Green
	} catch [System.Exception] {
		Write-Host "Failed to create symlink $sourcePath -> $targetPath : $_.ScriptStackTrace" -ForegroundColor Red
	}
}

Get-ChildItem "./lua/bin" -Filter *.dll | ForEach-Object {
	$targetPath = Join-Path -Path $gmodPath -ChildPath "lua/bin/$_"
	$sourcePath = Join-Path -Path "./" -ChildPath "lua/bin/$_"

	Write-Host "Creating symlink $sourcePath -> $targetPath"

	if (!(Test-Path -Path $targetPath)) {
		try {
			New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath
			Write-Host "Symlink created" -ForegroundColor Green
		} catch [System.Exception] {
			Write-Host "Failed to create symlink $sourcePath -> $targetPath : $_.ScriptStackTrace" -ForegroundColor Red
		}
	} else {
		Write-Host "Symbolic link already exists: $targetPath"
	}
}

Write-Host "All done! Exiting in 5s..."
Start-Sleep -Seconds 20