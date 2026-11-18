#!/usr/bin/env bash
# ==============================================================================
# Module 02: Desktop & Dotfiles Deployment (HyDE / Hyprland 0.57 Lua)
# Backs up existing ~/.config directories and symlinks repository configs
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log_step "Deploying Desktop Configurations & User Dotfiles"

BACKUP_TS=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="${HOME}/.config_backup_${BACKUP_TS}"
CONFIG_DIR="${HOME}/.config"
BIN_DIR="${HOME}/.local/bin"
WALLPAPERS_DIR="${HOME}/Pictures/Wallpapers"

mkdir -p "${CONFIG_DIR}" "${BIN_DIR}" "${WALLPAPERS_DIR}"

log_info "Target configuration directory: ${CONFIG_DIR}"
log_info "Timestamped backup directory if needed: ${BACKUP_DIR}"

# 1. Symlink ~/.config modules
DOTFILES_SRC="${SCRIPT_DIR}/dotfiles"

link_config_dir() {
    local folder_name="$1"
    local src="${DOTFILES_SRC}/${folder_name}"
    local dest="${CONFIG_DIR}/${folder_name}"

    if [[ ! -d "$src" ]]; then
        return
    fi

    if [[ -e "$dest" ]] || [[ -L "$dest" ]]; then
        # If it's already a symlink pointing to our repo, skip
        if [[ -L "$dest" ]] && [[ "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
            log_info "Symlink already valid: ${dest} -> ${src}"
            return
        fi

        # Backup existing file or folder
        mkdir -p "${BACKUP_DIR}"
        log_warn "Backing up existing ${dest} -> ${BACKUP_DIR}/${folder_name}"
        mv "$dest" "${BACKUP_DIR}/${folder_name}"
    fi

    log_info "Creating symlink: ${dest} -> ${src}"
    ln -sfn "$src" "$dest"
    log_success "Linked ~/.config/${folder_name}"
}

# Link all config components
for item in "hypr" "waybar" "dunst" "rofi" "kitty" "hyde" "pipewire"; do
    link_config_dir "$item"
done

# 2. Symlink Shell Dotfiles (Zsh)
if [[ -f "${DOTFILES_SRC}/zsh/.zshrc" ]]; then
    if [[ -f "${HOME}/.zshrc" ]] && [[ ! -L "${HOME}/.zshrc" ]]; then
        mkdir -p "${BACKUP_DIR}"
        mv "${HOME}/.zshrc" "${BACKUP_DIR}/.zshrc"
    fi
    ln -sfn "${DOTFILES_SRC}/zsh/.zshrc" "${HOME}/.zshrc"
    log_success "Linked ~/.zshrc"
fi

if [[ -f "${DOTFILES_SRC}/zsh/.zprofile" ]]; then
    if [[ -f "${HOME}/.zprofile" ]] && [[ ! -L "${HOME}/.zprofile" ]]; then
        mkdir -p "${BACKUP_DIR}"
        mv "${HOME}/.zprofile" "${BACKUP_DIR}/.zprofile"
    fi
    ln -sfn "${DOTFILES_SRC}/zsh/.zprofile" "${HOME}/.zprofile"
    log_success "Linked ~/.zprofile"
fi

# 3. Symlink Helper Scripts into ~/.local/bin
log_info "Installing user helper scripts to ${BIN_DIR}..."
for script in "${SCRIPT_DIR}/scripts"/*.sh; do
    if [[ -f "$script" ]]; then
        sname="$(basename "$script")"
        chmod +x "$script"
        ln -sfn "$script" "${BIN_DIR}/${sname}"
        log_info "Linked ${BIN_DIR}/${sname}"
    fi
done

# 4. Copy Default Assets & Wallpaper
if [[ -f "${SCRIPT_DIR}/assets/wallpapers/default.svg" ]]; then
    cp -u "${SCRIPT_DIR}/assets/wallpapers/default.svg" "${WALLPAPERS_DIR}/default.svg" 2>/dev/null || cp "${SCRIPT_DIR}/assets/wallpapers/default.svg" "${WALLPAPERS_DIR}/default.svg"
    log_success "Copied default wallpaper to ${WALLPAPERS_DIR}/default.svg"
fi

log_success "Module 02: Dotfiles and scripts deployed successfully."
