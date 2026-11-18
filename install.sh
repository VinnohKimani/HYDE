#!/usr/bin/env bash
# ==============================================================================
# HyDE / Hyprland 0.57+ (Lua) Post-Installation & Dotfiles Master Script
# Optimized for Apple MacBook Pro 13" (Early 2015, MacBookPro12,1)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Ensure script is executed as regular user, not root
check_not_root

log_header "HyDE Arch Linux Post-Install (MacBook Pro 12,1)"

echo -e "${WHITE}Welcome to the automated post-install setup for HyDE (Hyprland 0.57+ on Lua).${NC}"
echo -e "${DIM}Platform: Apple MacBook Pro 13\" Retina (Early 2015 / MacBookPro12,1)${NC}\n"

# Component selection via whiptail with fallback to CLI menu
SELECTED_CHOICES=()

show_whiptail_menu() {
    local choices
    choices=$(whiptail --title "HyDE Arch Linux Setup (MacBook Pro 12,1)" \
        --checklist "Select components to configure and install (Space to toggle, Enter to confirm):" 20 78 6 \
        "1" "System Update & Package Installation" ON \
        "2" "Desktop & Dotfiles (HyDE / Hyprland 0.57 Lua)" ON \
        "3" "MacBook Pro 2015 Hardware & Audio Suite" ON \
        "4" "Tiered RAM & Performance Tuning (ZRAM + Swap)" ON \
        "5" "Development Environments & Applications" ON \
        "6" "System Services Enablement" ON \
        3>&1 1>&2 2>&3) || {
            log_warn "Installation aborted by user."
            exit 0
        }

    # Clean quotes from whiptail output: "1" "2" ...
    for choice in $choices; do
        SELECTED_CHOICES+=("$(echo "$choice" | tr -d '"')")
    done
}

show_cli_menu() {
    echo -e "${CYAN}${BOLD}Select components to install:${NC}"
    echo "  [1] System Update & Package Installation (yay, base desktop, aur)"
    echo "  [2] Desktop & Dotfiles (HyDE / Hyprland 0.57 Lua, Waybar, Dunst, Rofi, Kitty, Zsh)"
    echo "  [3] MacBook Pro 2015 Hardware & Audio Suite (CS4208 woofers, DSP, SPI wake, BT)"
    echo "  [4] Tiered RAM & Performance Tuning (7.7GB ZRAM + 8GB SSD /swapfile + VM sysctl)"
    echo "  [5] Development Environments & Apps (IDEs, Docker, Bun, Node, Brave, Social apps)"
    echo "  [6] System Services Enablement (sddm, NetworkManager, bluetooth, oomd)"
    echo ""
    read -rp "Enter selection (comma-separated, e.g. 1,2,3,4,5,6) [Default: 1,2,3,4,5,6]: " input_choice

    input_choice="${input_choice:-1,2,3,4,5,6}"
    IFS=',' read -ra ADDR <<< "$input_choice"
    for i in "${ADDR[@]}"; do
        clean_i="$(echo "$i" | tr -d ' ')"
        [[ -n "$clean_i" ]] && SELECTED_CHOICES+=("$clean_i")
    done
}

if has_cmd whiptail; then
    show_whiptail_menu
else
    show_cli_menu
fi

if [[ ${#SELECTED_CHOICES[@]} -eq 0 ]]; then
    log_warn "No components selected. Exiting."
    exit 0
fi

log_info "Selected modules: ${SELECTED_CHOICES[*]}"

# Prompt for sudo upfront if any system module was selected
NEEDS_SUDO=false
for c in "${SELECTED_CHOICES[@]}"; do
    if [[ "$c" =~ ^(1|3|4|5|6)$ ]]; then
        NEEDS_SUDO=true
        break
    fi
done

if [[ "$NEEDS_SUDO" == "true" ]]; then
    init_sudo
fi

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
echo -e "  ${GREEN}✔${NC} User configs symlinked to ${BOLD}~/.config/${NC} (backups preserved)"
echo -e "  ${GREEN}✔${NC} Helper scripts linked to ${BOLD}~/.local/bin/${NC}"
echo -e "  ${GREEN}✔${NC} Cirrus CS4208 dual woofer enabler & PipeWire 9-stage DSP active"
echo -e "  ${GREEN}✔${NC} SPI ACPI sleep wake & Bluetooth autosuspend fixes installed"
echo -e "  ${GREEN}✔${NC} Tiered RAM: 7.7GB ZRAM (prio 100) + 8GB SSD swapfile (prio 10)"
echo ""
echo -e "${CYAN}${BOLD}Next Steps:${NC}"
echo -e "  1. Reboot your machine to load all kernel modprobe settings and services:"
echo -e "     ${WHITE}${BOLD}sudo reboot${NC}"
echo -e "  2. Or start Hyprland directly from your current tty:"
echo -e "     ${WHITE}${BOLD}Hyprland${NC}"
echo ""
