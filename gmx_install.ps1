# Check if the script is running on Windows
if ($env:OS -eq "Windows_NT") {
	$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not ($currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
		# If running on Windows, execute with elevated privileges
		Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
		Exit
	} else {
		Write-Host "User is elevated."
	}
} else {
	$currentUser = whoami
	if (-not ($currentUser -eq "root")) {
		# If running on macOS, execute with sudo
		sudo pwsh -NoProfile -ExecutionPolicy Bypass -File "$PSCommandPath"
		Exit
	} else {
		Write-Host "User is elevated."
	}
}

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptpath
Push-Location $scriptDir # make sure the working directory is the script directory

$gmodPath = Read-Host -Prompt 'Input Garrys Mod path'
$symLinks = "gmx", "menu/menu.lua", "menu/_menu.lua"
Foreach ($link in $symLinks) {
	$targetPath = Join-Path -Path $gmodPath -ChildPath "lua/$link"
	$sourcePath = Join-Path -Path (Resolve-Path "./lua") -ChildPath "$link"

	Write-Host "Creating symlink $sourcePath -> $targetPath"

	if ((Test-Path -Path $targetPath)) {
		(Get-Item $targetPath).Delete()
	}

	try {
		New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath
		Write-Host "Symlink created" -ForegroundColor Green
	} catch [System.Exception] {
		Write-Host "Failed to create symlink $sourcePath -> $targetPath : $_" -ForegroundColor Red
	}
}

Get-ChildItem "./lua/bin" -Filter *.dll | ForEach-Object {
	$targetFileName = Split-Path "$_" -Leaf
	$targetPath = Join-Path -Path $gmodPath -ChildPath "lua/bin/$targetFileName"
	$sourcePath = Join-Path -Path (Resolve-Path "./") -ChildPath "lua/bin/$targetFileName"

	Write-Host "Creating symlink $sourcePath -> $targetPath"

	if (!(Test-Path -Path $targetPath)) {
		try {
			New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath
			Write-Host "Symlink created" -ForegroundColor Green
		} catch [System.Exception] {

			Write-Host "Failed to create symlink $sourcePath -> $targetPath : $_" -ForegroundColor Red
		}
	} else {
		Write-Host "Symbolic link already exists: $targetPath"
	}
}

Write-Host "All done! Exiting in 5s..."
Start-Sleep -Seconds 20