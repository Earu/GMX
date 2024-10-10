#!/bin/bash

# Check if the script is running on macOS or Linux
if [[ "$(uname)" == "Darwin" || "$(uname)" == "Linux" ]]; then
    currentUser=$(whoami)
    if [[ "$currentUser" != "root" ]]; then
        # If running on macOS/Linux, execute with sudo
        sudo bash "$0"
        exit
    else
        echo "User is elevated."
    fi
else
    echo "This script only supports macOS or Linux."
    exit 1
fi

# Get the script's directory
scriptDir=$(dirname "$(readlink -f "$0")")
cd "$scriptDir" || exit

# Prompt for the Garry's Mod path
read -rp "Input Garry's Mod path: " gmodPath

# Function to create symbolic links
create_symlink() {
    local sourcePath="$1"
    local targetPath="$2"

    echo "Creating symlink $sourcePath -> $targetPath"

    # Remove the target path if it already exists
    if [[ -e "$targetPath" || -L "$targetPath" ]]; then
        rm -f "$targetPath"
    fi

    # Attempt to create the symbolic link
    ln -s "$sourcePath" "$targetPath" && echo -e "\e[32mSymlink created\e[0m" || echo -e "\e[31mFailed to create symlink $sourcePath -> $targetPath\e[0m"
}

# Core symlinks
symLinks=("gmx" "menu/menu.lua" "menu/_menu.lua")
for link in "${symLinks[@]}"; do
    sourcePath="$(realpath "./lua/$link")"
    targetPath="$gmodPath/lua/$link"

    create_symlink "$sourcePath" "$targetPath"
done

# Binaries symlink
for file in ./lua/bin/*.dll; do
    targetFileName=$(basename "$file")
    sourcePath="$(realpath "./lua/bin/$targetFileName")"
    targetPath="$gmodPath/lua/bin/$targetFileName"

    create_symlink "$sourcePath" "$targetPath"
done

# Source theme symlink
sourceSchemePath="$(realpath "./resource/SourceScheme.res")"
targetSchemePath="$gmodPath/resource/SourceScheme.res"
create_symlink "$sourceSchemePath" "$targetSchemePath"

# Inform the user and exit
echo "All done! Exiting in 5s..."
sleep 5