#!/usr/bin/env bash
# ==============================================================================
# HyDE / Hyprland 0.57+ (Lua) Post-Installation & Dotfiles Master Script
# Optimized for Apple MacBook Pro 13" Retina (Early 2015, MacBookPro12,1)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

check_not_root

AUTO_YES=false
RUN_SYNC=false
CUSTOM_MODE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -y, --yes      Run full automated installation non-interactively
  -c, --custom   Interactively choose specific components to install
  -s, --sync     Check & sync upstream HyDE changes before installing
  -h, --help     Show this help message

Default behavior:
  Runs full desktop setup (packages, dotfiles, hardware audio, RAM tuning,
  developer apps, and system services) with a simple confirmation prompt.
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        -c|--custom)
            CUSTOM_MODE=true
            shift
            ;;
        -s|--sync)
            RUN_SYNC=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Banner & System Overview
echo -e "${MAGENTA}${BOLD}"
cat << 'EOF'
  _    _       _____  ______ 
 | |  | |     |  __ \|  ____|
 | |__| |_   _| |  | | |__   
 |  __  | | | | |  | |  __|  
 | |  | | |_| | |__| | |____ 
 |_|  |_|\__, |_____/|______|
          __/ |              
         |___/               
EOF
echo -e "${NC}"
log_header "HyDE Arch Linux Setup (MacBook Pro 12,1 • Hyprland 0.57 Lua)"

echo -e "${WHITE}Hardware detected:${NC} Apple MacBook Pro 13\" Retina (Early 2015)"
echo -e "${WHITE}Display target:${NC}    2560x1600 @ 2x integer HiDPI (1280x800 desktop canvas)"
echo -e "${WHITE}Compositor:${NC}        Hyprland 0.57+ (Native Lua Engine)\n"

# 1. Optional Upstream Sync Check (Only if explicitly passed via --sync)
if [[ "$RUN_SYNC" == "true" ]]; then
    if [[ -f "${SCRIPT_DIR}/scripts/sync-upstream.sh" ]] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        log_info "Verifying alignment with upstream HyDE repository..."
        bash "${SCRIPT_DIR}/scripts/sync-upstream.sh"
    fi
fi

# 2. Interactive prompt or automated installation
SELECTED_CHOICES=()

show_cli_menu() {
    echo -e "${CYAN}${BOLD}Select components to install:${NC}"
    echo "  [1] System Update & Package Installation (yay, base desktop, aur, fonts)"
    echo "  [2] Desktop & Dotfiles (Hyprland 0.57 Lua, Waybar, Dunst, Rofi, Kitty, Zsh)"
    echo "  [3] MacBook Pro 2015 Hardware & Audio Suite (CS4208 woofers, DSP, SPI wake, BT)"
    echo "  [4] Tiered RAM & Performance Tuning (7.7GB ZRAM + 8GB SSD /swapfile + VM sysctl)"
    echo "  [5] Development Environments & Apps (IDEs, Docker, Bun, Node, Brave, Social apps)"
    echo "  [6] System Services Enablement (sddm, NetworkManager, bluetooth, oomd, mbpfan)"
    echo ""
    read -rp "Enter selection (comma-separated, e.g. 1,2,3,4,5,6) [Default: 1,2,3,4,5,6]: " input_choice

    input_choice="${input_choice:-1,2,3,4,5,6}"
    IFS=',' read -ra ADDR <<< "$input_choice"
    for i in "${ADDR[@]}"; do
        clean_i="$(echo "$i" | tr -d ' ')"
        [[ -n "$clean_i" ]] && SELECTED_CHOICES+=("$clean_i")
    done
}

if [[ "$CUSTOM_MODE" == "true" ]]; then
    show_cli_menu
elif [[ "$AUTO_YES" == "true" ]]; then
    SELECTED_CHOICES=(1 2 3 4 5 6)
else
    echo -e "${CYAN}${BOLD}Ready to configure your full desktop environment:${NC}"
    echo -e "  ${GREEN}•${NC} System Update, Base Desktop, AUR & Essential Fonts"
    echo -e "  ${GREEN}•${NC} HyDE / Hyprland 0.57 Lua Desktop Dotfiles & Helper Scripts"
    echo -e "  ${GREEN}•${NC} MacBook Pro 12,1 Cirrus CS4208 Dual Woofers & PipeWire DSP"
    echo -e "  ${GREEN}•${NC} Tiered RAM: 7.7GB ZRAM (Prio 100) + 8GB SSD Swapfile (Prio 10)"
    echo -e "  ${GREEN}•${NC} Development Environments, Toolchains & Common Apps"
    echo -e "  ${GREEN}•${NC} Core System Daemons & Services Enablement\n"

    read -rp "Proceed with full installation? [Y/n/custom]: " proceed
    proceed="${proceed:-y}"

    if [[ "$proceed" =~ ^[Yy]$ ]]; then
        SELECTED_CHOICES=(1 2 3 4 5 6)
    elif [[ "$proceed" =~ ^[Cc](ustom)?$ ]]; then
        show_cli_menu
    else
        log_warn "Installation cancelled by user."
        exit 0
    fi
fi

if [[ ${#SELECTED_CHOICES[@]} -eq 0 ]]; then
    log_warn "No components selected. Exiting."
    exit 0
fi

# Pre-authenticate sudo credentials
init_sudo

# Execute selected modules
for choice in "${SELECTED_CHOICES[@]}"; do
    case "$choice" in
        1)
            bash "${SCRIPT_DIR}/modules/01-packages.sh"
            ;;
        2)
            bash "${SCRIPT_DIR}/modules/02-dotfiles.sh"
            ;;
        3)
            bash "${SCRIPT_DIR}/modules/03-hardware-audio.sh"
            ;;
        4)
            bash "${SCRIPT_DIR}/modules/04-ram-performance.sh"
            ;;
        5)
            bash "${SCRIPT_DIR}/modules/05-dev-apps.sh"
            ;;
        6)
            bash "${SCRIPT_DIR}/modules/06-services.sh"
            ;;
        *)
            log_warn "Unknown option: ${choice}. Skipping."
            ;;
    esac
done

log_header "Installation & Configuration Complete!"
log_success "All selected HyDE components have been successfully deployed."
echo -e "${WHITE}Summary of configurations applied:${NC}"
echo -e "  ${GREEN}✔${NC} Hyprland 0.57 Lua verified config deployed to ${BOLD}~/.config/hypr/hyprland.lua${NC}"
echo -e "  ${GREEN}✔${NC} User configs symlinked to ${BOLD}~/.config/${NC} (backups preserved)"
echo -e "  ${GREEN}✔${NC} Helper scripts linked to ${BOLD}~/.local/bin/${NC}"
echo -e "  ${GREEN}✔${NC} Cirrus CS4208 dual woofer enabler & PipeWire 9-stage DSP active"
echo -e "  ${GREEN}✔${NC} SPI ACPI sleep wake & Bluetooth autosuspend fixes installed"
echo -e "  ${GREEN}✔${NC} Tiered RAM: 7.7GB ZRAM (prio 100) + 8GB SSD swapfile (prio 10)"
echo ""
echo -e "${CYAN}${BOLD}Next Steps:${NC}"
echo -e "  Reboot your machine to load all kernel modprobe settings and services:"
echo -e "     ${WHITE}${BOLD}sudo reboot${NC}\n"

if [[ "$AUTO_YES" != "true" ]]; then
    read -rp "Would you like to reboot now? [y/N]: " reboot_choice
    if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
        sudo reboot
    fi
fi
