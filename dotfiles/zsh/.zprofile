# Zsh profile executed on login shell

export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${HOME}/.bun/bin:${PATH}"

# Autostart Hyprland on tty1 if not running under display manager
if [[ -z "${DISPLAY}" ]] && [[ "${XDG_VTNR:-0}" -eq 1 ]] && [[ -z "${WAYLAND_DISPLAY}" ]]; then
    exec Hyprland
fi
