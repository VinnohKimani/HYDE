#!/usr/bin/env bash
# ==============================================================================
# Module 01: System Update & Package Installation
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log_step "Starting System Update & Package Installation"

# 1. Update official repositories
log_info "Synchronizing package databases and updating base system..."
sudo pacman -Syu --noconfirm --needed

# 2. Check and bootstrap AUR helper (yay-bin or yay)
if ! has_cmd yay; then
    log_info "AUR helper 'yay' not found. Bootstrapping yay-bin..."
    sudo pacman -S --needed --noconfirm git base-devel

    BUILD_DIR=$(mktemp -d /tmp/yay-build-XXXXXX)
    git clone https://aur.archlinux.org/yay-bin.git "${BUILD_DIR}"
    (
        cd "${BUILD_DIR}"
        makepkg -si --noconfirm
    )
    rm -rf "${BUILD_DIR}"
    log_success "yay installed successfully."
else
    log_info "AUR helper 'yay' is already installed."
fi

# Function to install from package list file
install_pkg_list() {
    local file="$1"
    local desc="$2"
    if [[ ! -f "$file" ]]; then
        log_warn "Package list ${file} not found. Skipping."
        return
    fi

    log_info "Reading ${desc} from ${file}..."
    local pkgs=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Strip comments and trim whitespace
        line=$(echo "$line" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [[ -z "$line" ]] && continue
        pkgs+=("$line")
    done < "$file"

    if [[ ${#pkgs[@]} -gt 0 ]]; then
        log_info "Installing ${#pkgs[@]} packages for ${desc}..."
        yay -S --needed --noconfirm "${pkgs[@]}" || {
            log_warn "Some packages encountered issues during batch install. Retrying individually..."
            for pkg in "${pkgs[@]}"; do
                yay -S --needed --noconfirm "$pkg" || log_warn "Failed to install: $pkg"
            done
        }
        log_success "Completed installation for ${desc}."
    fi
}

# Install base desktop packages
install_pkg_list "${SCRIPT_DIR}/pkgs/base-desktop.lst" "Base Desktop (HyDE / Hyprland)"

# Install AUR packages
install_pkg_list "${SCRIPT_DIR}/pkgs/aur.lst" "AUR Utilities & Theming"

log_success "Module 01: System update and package installation finished."
