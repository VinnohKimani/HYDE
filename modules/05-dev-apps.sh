#!/usr/bin/env bash
# ==============================================================================
# Module 05: Development Environments & Applications
# Installs IDEs, runtimes (Node, Bun, Python, Rust, Docker), and productivity apps
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log_step "Installing Development Environments & Applications"

# Helper to install from package list
install_pkg_list() {
    local file="$1"
    local desc="$2"
    if [[ ! -f "$file" ]]; then
        return
    fi

    log_info "Installing packages for ${desc}..."
    local pkgs=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(echo "$line" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [[ -z "$line" ]] && continue
        pkgs+=("$line")
    done < "$file"

    if [[ ${#pkgs[@]} -gt 0 ]]; then
        yay -S --needed --noconfirm "${pkgs[@]}" || {
            log_warn "Some packages failed in batch mode. Attempting sequential install..."
            for pkg in "${pkgs[@]}"; do
                yay -S --needed --noconfirm "$pkg" || log_warn "Could not install: $pkg"
            done
        }
    fi
}

# 1. Install Developer Toolchain
install_pkg_list "${SCRIPT_DIR}/pkgs/dev.lst" "Developer Tooling & Runtimes"

# 2. Check and Install Bun runtime if not present
if ! has_cmd bun; then
    log_info "Installing Bun runtime..."
    if ! yay -S --needed --noconfirm bun-bin 2>/dev/null; then
        log_info "Installing Bun via official script..."
        curl -fsSL https://bun.sh/install | bash || log_warn "Failed to install Bun via curl."
    fi
else
    log_info "Bun runtime is already installed: $(bun --version 2>/dev/null || true)"
fi

# 3. Configure Docker permissions
if has_cmd docker; then
    log_info "Configuring Docker group permissions for user '${USER}'..."
    if ! getent group docker >/dev/null 2>&1; then
        sudo groupadd docker || true
    fi
    sudo usermod -aG docker "${USER}" || true
    log_success "User '${USER}' added to 'docker' group (effective upon next login)."
fi

# 4. Install End-User Applications
install_pkg_list "${SCRIPT_DIR}/pkgs/apps.lst" "Productivity & Communication Applications"

log_success "Module 05: Development environments & applications installed."
