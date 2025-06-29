#!/bin/bash

# Color definitions
o='\033[0m'
r='\033[1;31m'
b='\033[1;36m'
bx='\033[2;7;36m'
w='\033[1;37m'
y='\033[1;33m'
g='\033[1;32m'
N=$r'['$y'~'$r'] '
P=$r'['$y'?'$r'] '
W=$w'['$r'!'$w'] '
S=$w'['$g'✓'$w'] '
I=$r'['$y'i'$r'] '
B=$w'['$y'+'$w'] '

# Directory definitions
font_dir="/data/data/com.termux/files/home/.fonts"
local="/data/data/com.termux/files/home/.local"
bin="${local}/bin"
sdcard="/data/data/com.termux/files/home/storage/"
dir_package="/data/data/com.termux/files/usr/bin"

# Package definitions with correct binary names
package_names=("imagemagick" "inotify-tools" "bc" "nano")
package_binaries=("magick" "inotifywait" "bc" "nano")

# Logging function
log() {
    echo -e "${r}[${y}$(date +'%H:%M:%S')${r}]${o} $@"
}

# Check function with better error handling
check() {
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        return 0
    else
        echo -e "$(log)${r}Error: Command failed with exit code $exit_code"
        exit 1
    fi
}

# Already exists message
ad() {
    echo -e "$(log)${g}package already exists"
}

# Header function
header() {
    echo -e "${r}
╔══╗     ╔╗   ╔╗╔╗
╚╣╠╝    ╔╝╚╗  ║║║║
 ║║╔═╗╔═╩╗╔╬══╣║║║╔══╦═╗
 ║║║╔╗╣══╣║║╔╗║║║║║║═╣╔╝
╔╣╠╣║║╠══║╚╣╔╗║╚╣╚╣║═╣║
╚══╩╝╚╩══╩═╩╝╚╩═╩═╩══╩╝${b}
      xshot 1.0.4
${o}"
}

# Enter prompt function
enter() {
    echo -e "${P}${b}press enter to continue ..."
}

# Function to check if package is installed
is_package_installed() {
    local binary_name="$1"
    if command -v "$binary_name" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to install a package
install_package() {
    local package_name="$1"
    local binary_name="$2"
    
    echo -e "${r}[${y}${package_name}${r}]"
    
    if is_package_installed "$binary_name"; then
        ad
    else
        echo -e "$(log)${b}Installing ${package_name}..."
        pkg install "$package_name" -y
        check
        
        # Verify installation
        if is_package_installed "$binary_name"; then
            echo -e "$(log)${g}${package_name} installed successfully"
        else
            echo -e "$(log)${r}Failed to install ${package_name}"
            exit 1
        fi
    fi
}

# Function to setup directories
setup_directories() {
    echo -e "${I}${b}Looking for directory ${y}~/.local/bin/${b} ..."
    sleep 1s
    
    if [[ ! -d "$local" ]]; then
        echo -e "${I}${b}Creating directory ~/.local ..."
        mkdir -p "$local"
        check
    fi
    
    if [[ ! -d "$bin" ]]; then
        echo -e "${I}${b}Creating directory ~/.local/bin ..."
        mkdir -p "$bin"
        check
    else
        echo -e "${I}${b}directory ${y}~/.local/bin/${b} already exists"
    fi
}

# Function to install fonts
install_fonts() {
    echo -e "$(log)${b}Installing fonts"
    
    if [[ -d "$(pwd)/fonts" ]]; then
        # Create fonts directory if it doesn't exist
        if [[ ! -d "$font_dir" ]]; then
            mkdir -p "$font_dir"
        fi
        
        # Copy fonts
        cp -rf "$(pwd)/fonts/"* "$font_dir/"
        check
        echo -e "$(log)${g}Fonts installed successfully"
    else
        echo -e "$(log)${y}Warning: fonts directory not found, skipping font installation"
    fi
}

# Function to setup storage
setup_storage() {
    if [[ ! -d "$sdcard" ]]; then
        echo -e "$(log)${b}Setting up storage access..."
        termux-setup-storage
        
        # Wait for storage setup
        local count=0
        while [[ ! -d "$sdcard" && $count -lt 30 ]]; do
            sleep 1
            ((count++))
        done
        
        if [[ ! -d "$sdcard" ]]; then
            echo -e "$(log)${y}Warning: Storage setup may have failed or is taking longer than expected"
        fi
    fi
}

# Function to install xshot binary
install_xshot() {
    echo -e "${I}${b}Installing xshot binary..."
    sleep 1s
    
    if [[ -f "xshot.sh" ]]; then
        cp "xshot.sh" "$bin/xshot"
        check
        
        chmod +x "$bin/xshot"
        check
        
        echo -e "$(log)${g}xshot binary installed successfully"
    else
        echo -e "$(log)${r}Error: xshot.sh not found in current directory"
        exit 1
    fi
}

# Function to update PATH
update_path() {
    local shell_rc=""
    
    # Determine which shell config file to use
    if [[ -n "$BASH_VERSION" ]]; then
        shell_rc="$HOME/.bashrc"
    elif [[ -n "$ZSH_VERSION" ]]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.profile"
    fi
    
    # Check if .local/bin is already in bashrc/zshrc
    if ! grep -q "/.local/bin" "$shell_rc" 2>/dev/null; then
        echo -e "$(log)${b}Adding ~/.local/bin to PATH in $(basename $shell_rc)"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_rc"
        echo -e "$(log)${g}PATH updated successfully"
        echo -e "$(log)${y}Please run: source $shell_rc or restart terminal"
    fi
}

# Main installation function
main() {
    # Check if running in Termux
    if [[ ! -d "/data/data/com.termux" ]]; then
        echo -e "$(log)${r}Error: This script is designed for Termux only"
        exit 1
    fi
    
    # Show header
    header
    
    # Wait for user input
    read -p "$(enter)" enter
    
    # Install packages
    echo -e "$(log)${b}Installing package requirements"
    for i in "${!package_names[@]}"; do
        install_package "${package_names[$i]}" "${package_binaries[$i]}"
    done
    
    # Setup storage
    setup_storage
    
    # Setup directories
    setup_directories
    
    # Install fonts
    install_fonts
    
    # Install xshot binary
    install_xshot
    
    # Update PATH
    update_path
    
    # Installation complete
    echo -e "$(log)${g}Installation complete!"
    echo -e "${o}
${g}╔═══════════════════════════════════════╗
║              INSTALLATION              ║
║               SUCCESSFUL!              ║
╚═══════════════════════════════════════╝${o}

${b}To use xshot, you can:${o}
${y}1.${o} Run: ${g}xshot${o} (if PATH is updated)
${y}2.${o} Run: ${g}~/.local/bin/xshot${o}
${y}3.${o} Run: ${g}bash ~/.local/bin/xshot${o}

${r}Note:${o} If 'xshot' command is not found, restart your terminal
or run: ${g}source ~/.bashrc${o}
"
}

# Error handling
set -e
trap 'echo -e "$(log)${r}Installation interrupted"; exit 1' INT TERM

# Run main function
main "$@"