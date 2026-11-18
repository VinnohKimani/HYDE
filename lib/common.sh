#!/usr/bin/env bash
# ==============================================================================
# Common Helper Utilities & Logging for HyDE MacBook Pro Post-Install
# ==============================================================================

# Colors & Formatting
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    printf "${BLUE}${BOLD}[INFO]${NC} %b\n" "$*"
}

log_success() {
    printf "${GREEN}${BOLD}[OK]${NC} %b\n" "$*"
}

log_warn() {
    printf "${YELLOW}${BOLD}[WARN]${NC} %b\n" "$*"
}

log_error() {
    printf "${RED}${BOLD}[ERROR]${NC} %b\n" "$*" >&2
}

log_step() {
    printf "\n${CYAN}${BOLD}==> %b${NC}\n" "$*"
}

log_header() {
    printf "\n${MAGENTA}${BOLD}======================================================================${NC}\n"
    printf "${MAGENTA}${BOLD}  %b${NC}\n" "$*"
    printf "${MAGENTA}${BOLD}======================================================================${NC}\n\n"
}

# Ensure script is NOT run directly as root
check_not_root() {
    if [[ "${EUID}" -eq 0 ]]; then
        log_error "This script must NOT be run directly as root (sudo)."
        log_error "Please run as your regular user: ./install.sh"
        log_error "Administrative privileges will be requested when needed."
        exit 1
    fi
}

# Keep-alive for sudo timestamp
init_sudo() {
    log_info "Acquiring administrative privilege..."
    if ! sudo -v; then
        log_error "Failed to authenticate sudo. Aborting."
        exit 1
    fi

    # Keep sudo timestamp updated in background
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" 2>/dev/null || exit
    done 2>/dev/null &
    SUDO_KEEP_ALIVE_PID=$!
    trap 'kill "${SUDO_KEEP_ALIVE_PID}" 2>/dev/null || true' EXIT
}

# Check if command exists
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}
