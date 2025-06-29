#!/usr/bin/env bash
# xshot automatic screenshots
# coded by D_baj
# recode by AzRyCb
# improved version with better error handling
# xshot 1.0.5 Enhanced

# Enable strict error handling
set -euo pipefail

# Color definitions
readonly o='\033[0m'
readonly r='\033[1;31m'
readonly b='\033[1;36m'
readonly bx='\033[2;7;36m'
readonly w='\033[1;37m'
readonly y='\033[1;33m'
readonly g='\033[1;32m'

# Hex color palette
readonly -a hex_color=(
    "#3d465c"  # dark
    "#1E222B"  # dark2
    "#F8F9FA"  # light
    "#000000"  # black
    "#ffffff"  # white (fixed typo)
    "#59d6ff"  # blue
    "#e6e6e6"  # gray
    "#38d13e"  # green
)

# Status indicators
readonly N="${r}[${y}~${r}]"
readonly P="${r}[${y}?${r}] "
readonly W="${r}[${r}!${r}] "
readonly F="${r}[${r}x${r}] "
readonly S="${r}[${g}✓${r}] "
readonly I="${r}[${r}*${r}] "
readonly B="${r}[${y}+${r}] "

# Path configurations
readonly camera_path="/sdcard/DCIM/Camera"
readonly screenshots_path="/sdcard/DCIM/Screenshots"
readonly camera_backup="${camera_path}/backup"
readonly screenshots_backup="${screenshots_path}/backup"
readonly manual_backup="/sdcard/DCIM/backup"

# Style configurations
readonly convert_titlebar="yes"
readonly add_on_img=""
readonly width_img=500
readonly height_img=1000

# Border settings
readonly border_size=50
readonly border_radius=10
readonly border_c_dark="${hex_color[0]}"
readonly border_c_light="${hex_color[2]}"

# Shadow settings
readonly shadow_size="85x10+0+10"
readonly shadow_color="${hex_color[3]}"

# Footer settings
readonly owner_info=" @AzRyCb"
readonly footer_text=" Enhanced Screenshots Using Xshot"
readonly footer_xy="+0+30"
readonly footer_xy_time="+0+20"
readonly footer_size=20
readonly footer_size_time=15
readonly footer_color="${hex_color[3]}"

# Timestamp settings
readonly footer_xy_timeStamp2="+50+50"
readonly footer_xy_timeStamp="+50+200"
readonly footer_size_timeStamp=55
readonly footer_color_timeStamp="${hex_color[5]}"
readonly footer_color_timeStamp2="${hex_color[6]}"

# Global variables
count=1
backup="yes"
wm="yes"
type=""
color=""
space1=""
space2=""
path=""
path_backup=""
run=""
file=""
file_name=""
titlebar_color=""
border_color=""

# Check formats
readonly -a check_format=(
    "${g}Done"
    "${r}Failed"
    "${g}Done"
    "${r}Failed"
)

# Function to check dependencies
check_dependencies() {
    local deps=("magick" "inotifywait" "bc")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "$(log)${r}Missing dependencies: ${missing[*]}"
        echo -e "$(log)${y}Please run the install script first"
        exit 1
    fi
}

# Function to create backup directories
create_backup_dirs() {
    local dirs=("$screenshots_backup" "$camera_backup" "$manual_backup")
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" || {
                echo -e "$(log)${r}Failed to create backup directory: $dir"
                exit 1
            }
        fi
    done
}

# Function to check storage access
check_storage() {
    if [[ ! -d "/sdcard" ]]; then
        echo -e "$(log)${r}Storage not accessible. Please run: termux-setup-storage"
        exit 1
    fi
    
    if [[ ! -w "/sdcard" ]]; then
        echo -e "$(log)${r}No write permission to storage"
        exit 1
    fi
}

# Set theme functions
light() {
    color="LIGHT"
    titlebar_color="${hex_color[1]}"
    border_color="${border_c_light}"
}

dark() {
    color="DARK"
    titlebar_color="${hex_color[1]}"
    border_color="${border_c_dark}"
}

# Backup function
backup_file() {
    if [[ "$backup" == "yes" && -f "$file" ]]; then
        local renamed
        renamed=$(echo "$file_name" | sed "s/.jpg/_backup.jpg/g")
        
        chmod +r "$file" 2>/dev/null || true
        
        if cp "$file" "${path_backup}/${renamed}" 2>/dev/null; then
            echo -e "$(log)${g}Backup created: ${renamed}"
        else
            echo -e "$(log)${y}Warning: Failed to create backup"
        fi
    fi
}

# Logging function
log() {
    echo -e "${r}[${y}$(date +'%H:%M:%S')${r}]${o} $*"
}

# Prompt function
prompt() {
    echo -e "$(log)${b}Please input file : ${y}"
}

# Check function with better error handling
check() {
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        if [[ "$type" == "MANUAL SHOT" ]]; then
            echo -e "   $(log)${check_format[2]}"
        else
            echo -e "   $(log)${check_format[0]}"
        fi
        return 0
    else
        if [[ "$type" == "MANUAL SHOT" ]]; then
            echo -e "   $(log)${check_format[3]}"
        else
            echo -e "   $(log)${check_format[1]}"
        fi
        echo -e "$(log)${r}Command failed with exit code: $exit_code"
        exit 1
    fi
}

# Count function
count_display() {
    echo -e "${r}[${y}$((count + 1))${r}]${o}"
}

# Header function
header() {
    clear
    echo -e "
${r}             ╔═══════════════════════════════╗
             ║    ╔═╗╔═╦═══╦╗ ╔╦═══╦════╗    ║
             ║    ╚╗╚╝╔╣╔═╗║║ ║║╔═╗║╔╗╔╗║    ║
             ║     ╚╗╔╝║╚══╣╚═╝║║ ║╠╝║║╚╝    ║
             ║     ╔╝╚╗╚══╗║╔═╗║║ ║║ ║║      ║
             ║    ╔╝╔╗╚╣╚═╝║║ ║║╚═╝║ ║║      ║
             ║    ╚═╝╚═╩═══╩╝ ╚╩═══╝ ╚╝      ║
             ║            ${b}V1.0.5${r}             ║
             ║       screenshot tools${r}        ║
             ╚═══════════════════════════════╝

             ╔═══════════════════════════════╗
             ║        ${y}    EXECUTE${r}            ║
   ╔═════════╩═══════════════════════════════╩═════════╗
   ╚═══════════════════════════════════════════════════╝
   ╔════════════════════╗         ╔════════════════════╗
   ║ ${y}TYPE : ${b}${type}${space1}${y}THEME : ${b}${color}${space2}
   ╚════════════════════╝         ╚════════════════════╝
                  press ctrl + c to exit${o}"
}

# Help function
help() {
    echo -e "${y}
  ╔═══════════════════════════════════════════════════════╗
  ║                    XSHOT HELP                         ║
  ╚═══════════════════════════════════════════════════════╝

  Usage:
      xshot [mode] [theme] [options]

  Modes:
      -h           Show this help display
      -i           Show program information
      -a           Autoshot (automatically detect new screenshots)
      -m           Manual input file
      -wm          Add watermark timestamp to camera images

  Themes:
      -l           Light theme
      -d           Dark theme (default)

  Options:
      -!           Run without footer text

  Examples:
      xshot -a -l          # Autoshot with light theme
      xshot -a -d -!       # Autoshot dark theme, no footer
      xshot -m -l          # Manual mode with light theme
      xshot -wm            # Watermark mode for camera images

  Notes:
      - Autoshot monitors: ${screenshots_path}
      - Watermark monitors: ${camera_path}
      - Backups are saved automatically
      - Requires storage permission (termux-setup-storage)

${o}"
}

# Program info function
program_info() {
    echo -e "${r}             
                 ╔═══════════════════════════════╗
                 ║    ╔═╗╔═╦═══╦╗ ╔╦═══╦════╗    ║
                 ║    ╚╗╚╝╔╣╔═╗║║ ║║╔═╗║╔╗╔╗║    ║
                 ║     ╚╗╔╝║╚══╣╚═╝║║ ║╠╝║║╚╝    ║
                 ║     ╔╝╚╗╚══╗║╔═╗║║ ║║ ║║      ║
                 ║    ╔╝╔╗╚╣╚═╝║║ ║║╚═╝║ ║║      ║
                 ║    ╚═╝╚═╩═══╩╝ ╚╩═══╝ ╚╝      ║
                 ║            ${b}V1.0.5${r}             ║
                 ║       screenshot tools${r}        ║
                 ╚═══════════════════════════════╝
${b}
            A tool to make your screenshots look better
                           Original: D_4J
                           Remake: AzRyCb
                           Enhanced: $(date +'%Y')
                     Build date: $(date +'%d/%m/%Y')
${o}"
}

# Titlebar function with improved error handling
titlebar() {
    # Check if file exists and is readable
    if [[ ! -f "$file" ]]; then
        echo -e "$(log)${r}File not found: $file"
        return 1
    fi
    
    if [[ ! -r "$file" ]]; then
        echo -e "$(log)${r}File not readable: $file"
        return 1
    fi

    # macOS-style titlebar colors
    local gr="#27C93F"  # green
    local yl="#FFBD2E"  # yellow
    local rd="#FF5F56"  # red
    local bl="#282C34"  # black

    # Calculate dimensions with error handling
    local rad br x0 y0 x1
    if ! rad=$(echo "0.0025 * ${width_img} * ${height_img} / 100" | bc 2>/dev/null); then
        rad=15  # fallback value
    fi
    
    if ! br=$(echo "${rad} * 5" | bc 2>/dev/null); then
        br=75  # fallback value
    fi
    
    if ! x0=$(echo "${rad} * 3" | bc 2>/dev/null); then
        x0=45  # fallback value
    fi
    
    if ! y0=$(echo "${br} * 0.5" | bc 2>/dev/null); then
        y0=37  # fallback value
    fi
    
    if ! x1=$(echo "${x0} + ${rad}" | bc 2>/dev/null); then
        x1=60  # fallback value
    fi

    # Create circle positions array
    declare -A arr=()
    for i in {0..2}; do
        arr[$i,0]=$x0
        arr[$i,1]=$y0
        arr[$i,2]=$x1
        arr[$i,3]=$y0
        if ! x0=$(echo "${x0} + ${rad} * 3" | bc 2>/dev/null); then
            x0=$((x0 + 45))  # fallback increment
        fi
        if ! x1=$(echo "${x0} + ${rad}" | bc 2>/dev/null); then
            x1=$((x0 + 15))  # fallback increment
        fi
    done

    # Apply titlebar with error handling
    if magick "$file" \
        -background "${titlebar_color}" \
        -gravity north -splice "0x${br}" \
        -draw "fill ${rd} circle ${arr[0,0]},${arr[0,1]} ${arr[0,2]},${arr[0,3]}
               fill ${yl} circle ${arr[1,0]},${arr[1,1]} ${arr[1,2]},${arr[1,3]} 
               fill ${gr} circle ${arr[2,0]},${arr[2,1]} ${arr[2,2]},${arr[2,3]}" \
        "$file" 2>/dev/null; then
        return 0
    else
        echo -e "$(log)${r}Failed to apply titlebar"
        return 1
    fi
}

# Screenshot processing function
ss() {
    local footer_time
    footer_time=" $(date +'%a %d.%h.%Y')  $(date +'%H:%M')"
    
    # Apply shadow and border effects
    if ! magick "$file" \
        -alpha set -virtual-pixel transparent \
        -channel A -blur 0x5 -threshold 50% +channel \
        \( +clone -background "${shadow_color}" \
        -shadow "${shadow_size}" \) \
        +swap -background none -layers merge +repage \
        -bordercolor "${border_color}" -border "${border_size}" \
        "$file" 2>/dev/null; then
        echo -e "$(log)${r}Failed to apply effects"
        return 1
    fi

    # Add footer text if enabled
    if [[ "$wm" != "no" ]]; then
        if ! magick "$file" \
            -gravity South -background none \
            -font JetBrains-Mono-Medium-Nerd-Font-Complete \
            -pointsize "${footer_size}" \
            -fill "${footer_color}" \
            -annotate "${footer_xy}" "${footer_text}" \
            -gravity North -background none \
            -pointsize "${footer_size_time}" \
            -annotate "${footer_xy_time}" "${footer_time}" \
            "$file" 2>/dev/null; then
            echo -e "$(log)${y}Warning: Failed to add footer text, continuing without it"
        fi
    fi

    check
    display_result
}

# Display result function
display_result() {
    if [[ "$type" == "MANUAL SHOT" ]]; then
        echo -e "   $(log)${g}Output: ${file}"
    else
        echo -e "   ${r}[ ${g}${file}${r} ]"
        ((count++))
        echo -e "   ${r}[${y}${count}${r}]"
        echo -e "   $(log)${b}Waiting for new file..."
    fi
}

# Timestamp watermark function
timeStamp() {
    local owner_info=" @AzRyCb"
    local owner_info2
    owner_info2=" $(date +'%H:%M')
 $(date +'%a %d.%h.%Y')"

    if magick "${file}" \
        -gravity SouthWest -background black \
        -font JetBrains-Mono-Medium-Nerd-Font-Complete \
        -pointsize "${footer_size_timeStamp}" \
        -fill "${footer_color_timeStamp}" \
        -annotate "${footer_xy_timeStamp}" "${owner_info}" \
        -fill "${footer_color_timeStamp2}" \
        -annotate "${footer_xy_timeStamp2}" "${owner_info2}" \
        "${file}" 2>/dev/null; then
        check
        echo -e "   ${r}[   ${g}${file}${r}     ]"
        ((count++))
        echo -e "   ${r}[${y}${count}${r}]"
        echo -e "   $(log)${b}Waiting for new file..."
    else
        echo -e "$(log)${r}Failed to add timestamp"
        return 1
    fi
}

# Main processing function
main() {
    file_name=$(echo "${filename}" | awk '{print $3}')
    file="${path}/${file_name}"
    
    echo -e "   $(log)${b}Processing file: ${y}${file_name}"
    
    if [[ ! -f "$file" ]]; then
        echo -e "   $(log)${r}File not found: $file"
        return 1
    fi
    
    if [[ "$run" == "auto" ]]; then
        backup_file
        echo -e "   $(log)${b}Converting..."
        titlebar && ss
    elif [[ "$run" == "wm" ]]; then
        backup_file
        echo -e "   $(log)${b}Adding watermark..."
        timeStamp
    fi
}

# Autoshot function
autoshot() {
    header
    echo -e "   ${r}[${y}${count}${r}]"
    echo -e "   $(log)${b}Monitoring: ${y}${path}"
    echo -e "   $(log)${b}Waiting for new files..."
    
    # Check if path exists
    if [[ ! -d "$path" ]]; then
        echo -e "$(log)${r}Directory not found: $path"
        exit 1
    fi
    
    # Start monitoring with better error handling
    inotifywait -m -e create "$path" 2>/dev/null | \
    while IFS= read -r filename; do
        main
    done
}

# Manual mode function
manual() {
    header
    
    while true; do
        read -r -p "   $(prompt)" file_name
        
        if [[ -z "$file_name" ]]; then
            echo -e "   $(log)${r}Please enter a filename"
            continue
        fi
        
        echo -e "   $(log)${b}Searching for file: ${y}${file_name}${b} in /sdcard"
        
        if cd /sdcard 2>/dev/null; then
            local result
            result=$(find . -name "${file_name}" -type f 2>/dev/null | head -1 | sed 's/^.\///')
            
            if [[ -z "$result" ]]; then
                echo -e "   $(log)${r}File not found. Please check the filename and try again."
                continue
            fi
            
            echo -e "   $(log)${g}Found: ${y}/sdcard/${result}"
            file="/sdcard/${result}"
            
            if [[ -f "$file" && -r "$file" ]]; then
                echo -e "   $(log)${b}Processing file..."
                titlebar && ss
                break
            else
                echo -e "   $(log)${r}File is not accessible"
                continue
            fi
        else
            echo -e "   $(log)${r}Cannot access storage. Please run: termux-setup-storage"
            exit 1
        fi
    done
}

# Initialize function
initialize() {
    check_dependencies
    check_storage
    create_backup_dirs
}

# Cleanup function
cleanup() {
    echo -e "\n$(log)${y}Cleaning up and exiting..."
    exit 0
}

# Signal handlers
trap cleanup SIGINT SIGTERM

# Main execution logic
main_execution() {
    # Initialize
    initialize
    
    # Parse watermark option
    if [[ "${3:-}" == "-!" || "${4:-}" == "-!" ]]; then
        wm="no"
    fi
    
    case "${1:-}" in
        -a)
            type="AUTOSHOT"
            space1="${r}    ║         ║ "
            path="$screenshots_path"
            path_backup="$screenshots_backup"
            run="auto"
            
            case "${2:-}" in
                -l)
                    space2="${r}      ║"
                    light
                    autoshot
                    ;;
                -d|"")
                    space2="${r}       ║"
                    dark
                    autoshot
                    ;;
                *)
                    help
                    ;;
            esac
            ;;
            
        -m)
            type="MANUAL SHOT"
            space1="${r} ║         ║ "
            run="manual"
            
            case "${2:-}" in
                -l)
                    space2="${r}      ║"
                    light
                    manual
                    ;;
                -d|"")
                    space2="${r}       ║"
                    dark
                    manual
                    ;;
                *)
                    help
                    ;;
            esac
            ;;
            
        -wm)
            type="TIME STAMP"
            path="$camera_path"
            path_backup="$camera_backup"
            space1="${r}  ║         ║ "
            color="NONE"
            space2="${r}       ║"
            run="wm"
            autoshot
            ;;
            
        -i)
            program_info
            ;;
            
        -h|--help|"")
            help
            ;;
            
        *)
            echo -e "$(log)${r}Unknown option: $1"
            help
            exit 1
            ;;
    esac
}

# Run main execution
main_execution "$@"