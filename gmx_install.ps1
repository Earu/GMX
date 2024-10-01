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

function SymLink {
	param ([string]$sourcePath, [string]$targetPath)

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

# core
$symLinks = "gmx", "menu/menu.lua", "menu/_menu.lua"
Foreach ($link in $symLinks) {
	$sourcePath = Join-Path -Path (Resolve-Path "./lua") -ChildPath "$link"
	$targetPath = Join-Path -Path $gmodPath -ChildPath "lua/$link"

	SymLink $sourcePath $targetPath
}

# binaries
Get-ChildItem "./lua/bin" -Filter *.dll | ForEach-Object {
	$targetFileName = Split-Path "$_" -Leaf
	$sourcePath = Join-Path -Path (Resolve-Path "./") -ChildPath "lua/bin/$targetFileName"
	$targetPath = Join-Path -Path $gmodPath -ChildPath "lua/bin/$targetFileName"

	SymLink $sourcePath $targetPath
}

# source theme
$sourceSchemePath = Resolve-Path "./resource/SourceScheme.res"
$targetSchemePath = Join-Path -Path $gmodPath -ChildPath "resource/SourceScheme.res"
SymLink $sourceSchemePath $targetSchemePath

Write-Host "All done! Exiting in 5s..."
Start-Sleep -Seconds 5