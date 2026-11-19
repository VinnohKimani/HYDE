#!/usr/bin/env bash
# ==============================================================================
# Upstream Synchronization & Drift Detection Tool for HyDE
# Safely tracks upstream HyDE (HyDE-Project/HyDE) without clobbering
# custom MacBook Pro 12,1 hardware, audio, ZRAM, or Lua configurations.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Configuration defaults
DEFAULT_UPSTREAM_URL="https://github.com/HyDE-Project/HyDE.git"
UPSTREAM_REMOTE="upstream"
UPSTREAM_URL="${UPSTREAM_URL:-$DEFAULT_UPSTREAM_URL}"
UPSTREAM_BRANCH=""

# Protected file patterns (local MacBook Pro 12,1 customizations)
PROTECTED_PATTERNS=(
    "system/audio/"
    "system/memory/"
    "system/hardware/"
    "dotfiles/hypr/hyprland.lua"
    "dotfiles/hyde/config.toml"
    "scripts/brightness.sh"
    "scripts/volume.sh"
    "scripts/display-switch.sh"
    "scripts/battery-monitor.sh"
    "modules/03-hardware-audio.sh"
    "modules/04-ram-performance.sh"
)

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -c, --check       Perform non-destructive drift check and exit (exit 1 if drift detected)
  -d, --diff        Display unified diff against upstream
  -l, --log         Show upstream commit log not present in local HEAD
  -s, --stage       Create a dedicated staging branch to safely test upstream merge
  -r, --remote URL  Override upstream git remote URL
  -h, --help        Show this help message

Running with no arguments launches the interactive inspection menu.
EOF
    exit 0
}

# Parse command line flags
MODE="interactive"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--check)
            MODE="check"
            shift
            ;;
        -d|--diff)
            MODE="diff"
            shift
            ;;
        -l|--log)
            MODE="log"
            shift
            ;;
        -s|--stage)
            MODE="stage"
            shift
            ;;
        -r|--remote)
            UPSTREAM_URL="$2"
            shift 2
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

cd "${SCRIPT_DIR}"

# Ensure working directory is a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log_error "Not inside a git repository."
    exit 1
fi

# 1. Verify or add upstream remote
setup_upstream_remote() {
    if ! git remote get-url "${UPSTREAM_REMOTE}" >/dev/null 2>&1; then
        log_info "Remote '${UPSTREAM_REMOTE}' not found. Adding: ${UPSTREAM_URL}"
        git remote add "${UPSTREAM_REMOTE}" "${UPSTREAM_URL}"
    else
        local existing_url
        existing_url="$(git remote get-url "${UPSTREAM_REMOTE}")"
        log_info "Using upstream remote '${UPSTREAM_REMOTE}' (${existing_url})"
    fi

    log_info "Fetching latest upstream changes..."
    if [[ "$(git rev-parse --is-shallow 2>/dev/null || echo false)" == "true" ]]; then
        log_warn "Shallow git clone detected (--depth 1). Unshallowing to allow commit drift calculation..."
        git fetch --unshallow "${UPSTREAM_REMOTE}" "${UPSTREAM_BRANCH:-master}" --quiet 2>/dev/null || \
            git fetch --depth=100 "${UPSTREAM_REMOTE}" --quiet 2>/dev/null || true
    else
        git fetch "${UPSTREAM_REMOTE}" --prune --quiet 2>/dev/null || true
    fi

    # Determine upstream primary branch (master or main)
    if git rev-parse --verify "${UPSTREAM_REMOTE}/master" >/dev/null 2>&1; then
        UPSTREAM_BRANCH="master"
    elif git rev-parse --verify "${UPSTREAM_REMOTE}/main" >/dev/null 2>&1; then
        UPSTREAM_BRANCH="main"
    else
        # Fallback to upstream HEAD
        UPSTREAM_BRANCH="$(git remote show "${UPSTREAM_REMOTE}" | grep 'HEAD branch' | cut -d: -f2 | tr -d ' ')"
    fi

    UPSTREAM_REF="${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}"
    log_success "Upstream tracking target resolved: ${UPSTREAM_REF}"
}

# Check if a path matches any protected patterns
is_protected() {
    local file_path="$1"
    for pattern in "${PROTECTED_PATTERNS[@]}"; do
        if [[ "$file_path" == *"$pattern"* ]]; then
            return 0
        fi
    done
    return 1
}

# 2. Check drift statistics
calculate_drift() {
    CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    COMMITS_BEHIND=$(git rev-list --count "HEAD..${UPSTREAM_REF}" 2>/dev/null || echo "0")
    COMMITS_AHEAD=$(git rev-list --count "${UPSTREAM_REF}..HEAD" 2>/dev/null || echo "0")
}

# Display changed files with protection badges
list_changed_files() {
    log_step "Upstream Changed Files (Relative to ${CURRENT_BRANCH})"
    
    local changed_files
    changed_files=$(git diff --name-status "HEAD...${UPSTREAM_REF}" || true)

    if [[ -z "$changed_files" ]]; then
        log_success "No file differences detected against ${UPSTREAM_REF}."
        return
    fi

    echo -e "${DIM}Status  File path${NC}"
    echo "------------------------------------------------------------------"
    while IFS=$'\t' read -r status filepath extra; do
        [[ -z "$status" ]] && continue
        
        local status_label
        case "$status" in
            M*) status_label="${YELLOW}Modified${NC} " ;;
            A*) status_label="${GREEN}Added   ${NC} " ;;
            D*) status_label="${RED}Deleted ${NC} " ;;
            R*) status_label="${BLUE}Renamed ${NC} "; filepath="${extra:-$filepath}" ;;
            *)  status_label="${CYAN}${status}     ${NC} " ;;
        esac

        if is_protected "$filepath"; then
            printf " %b %-45s ${RED}${BOLD}[PROTECTED: CUSTOM MBP12,1]${NC}\n" "$status_label" "$filepath"
        else
            printf " %b %-45s\n" "$status_label" "$filepath"
        fi
    done <<< "$changed_files"
    echo "------------------------------------------------------------------"
    echo -e "${YELLOW}Note:${NC} Files flagged as ${RED}[PROTECTED]${NC} contain your customized hardware/audio tuning."
    echo ""
}

# Determine appropriate pager
get_pager() {
    if [[ -n "${PAGER:-}" ]] && has_cmd "${PAGER%% *}"; then
        echo "$PAGER"
    elif has_cmd delta; then
        echo "delta"
    elif has_cmd less; then
        echo "less -R"
    else
        echo "cat"
    fi
}

# Display diff with optional pager
show_diff() {
    log_header "Unified Diff: HEAD vs ${UPSTREAM_REF}"
    local pager
    pager="$(get_pager)"
    git diff --color=always "HEAD...${UPSTREAM_REF}" 2>/dev/null | $pager || true
}

# Display upstream commit log
show_log() {
    log_header "Upstream Commits (${UPSTREAM_REF}) Not In Local HEAD"
    local pager
    pager="$(get_pager)"
    git log --graph --oneline --decorate --color=always "HEAD..${UPSTREAM_REF}" 2>/dev/null | $pager || true
}

# Safely create a staging branch to test merge
create_staging_branch() {
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local stage_branch="sync/upstream-${timestamp}"

    # Warn if uncommitted local changes exist
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log_error "You have uncommitted local changes in working directory."
        log_warn "Please commit or stash your changes before creating a staging branch."
        return 1
    fi

    log_step "Creating isolated staging branch: ${stage_branch}"
    git checkout -b "${stage_branch}"
    log_info "Attempting dry-run merge of ${UPSTREAM_REF}..."

    if git merge --no-commit --no-ff "${UPSTREAM_REF}"; then
        log_success "Upstream merged cleanly into ${stage_branch} (no commit created yet)."
        log_info "Review changes with: git status / git diff --staged"
        log_info "To abort and return to ${CURRENT_BRANCH}: git merge --abort && git checkout ${CURRENT_BRANCH}"
    else
        log_warn "Conflicts encountered during merge into staging branch."
        log_info "Conflicted files:"
        git status --short
        log_info "To cancel this test merge: git merge --abort && git checkout ${CURRENT_BRANCH} && git branch -D ${stage_branch}"
    fi
}

# Interactively checkout specific upstream files
selective_checkout() {
    log_step "Selective Upstream File Checkout"
    echo -e "Enter the relative file path to checkout from ${UPSTREAM_REF} (or 'cancel'):"
    read -rp "File path: " target_file

    if [[ "$target_file" == "cancel" ]] || [[ -z "$target_file" ]]; then
        log_info "Selective checkout cancelled."
        return
    fi

    if is_protected "$target_file"; then
        echo -e "${RED}${BOLD}WARNING:${NC} '${target_file}' is a PROTECTED customization for MacBook Pro 12,1."
        read -rp "Are you absolutely sure you want to overwrite it with upstream? (type 'YES'): " confirm
        if [[ "$confirm" != "YES" ]]; then
            log_warn "Checkout aborted. Protected file preserved."
            return
        fi
    fi

    if git checkout "${UPSTREAM_REF}" -- "$target_file"; then
        log_success "Updated '${target_file}' from ${UPSTREAM_REF}."
        log_info "Inspect changes with: git diff -- '${target_file}'"
    else
        log_error "Failed to checkout '${target_file}' from ${UPSTREAM_REF}."
    fi
}

# Main Execution Flow
setup_upstream_remote
calculate_drift

log_header "HyDE Upstream Drift Report"
echo -e "Current Local Branch : ${BOLD}${CURRENT_BRANCH}${NC}"
echo -e "Upstream Remote Target: ${BOLD}${UPSTREAM_REF}${NC}"
echo -e "Commits Behind        : ${CYAN}${BOLD}${COMMITS_BEHIND}${NC}"
echo -e "Commits Ahead (Custom): ${MAGENTA}${BOLD}${COMMITS_AHEAD}${NC}\n"

# Handle non-interactive CLI modes
case "$MODE" in
    check)
        list_changed_files
        if [[ "$COMMITS_BEHIND" -gt 0 ]]; then
            log_warn "System is behind upstream by ${COMMITS_BEHIND} commit(s)."
            exit 1
        else
            log_success "Repository is fully up-to-date with upstream ${UPSTREAM_REF}."
            exit 0
        fi
        ;;
    diff)
        show_diff
        exit 0
        ;;
    log)
        show_log
        exit 0
        ;;
    stage)
        create_staging_branch
        exit 0
        ;;
esac

# Interactive Menu Loop
while true; do
    echo -e "${CYAN}${BOLD}Upstream Synchronization Options:${NC}"
    echo "  [1] List changed files & inspection status"
    echo "  [2] View unified diff against upstream"
    echo "  [3] Show upstream commit history / changelog"
    echo "  [4] Create staging branch (${CURRENT_BRANCH} -> sync/upstream-*) to test merge"
    echo "  [5] Selectively checkout a specific file from upstream"
    echo "  [6] Exit safely"
    echo ""
    read -rp "Select an option [1-6] (Default 1): " choice
    choice="${choice:-1}"

    case "$choice" in
        1)
            list_changed_files
            ;;
        2)
            show_diff
            ;;
        3)
            show_log
            ;;
        4)
            create_staging_branch
            break
            ;;
        5)
            selective_checkout
            ;;
        6|q|exit)
            log_info "Exiting upstream sync tool. No modifications made."
            break
            ;;
        *)
            log_warn "Invalid option. Please enter 1-6."
            ;;
    esac
    echo ""
done
