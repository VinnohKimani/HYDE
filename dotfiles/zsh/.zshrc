# Zsh interactive configuration for HyDE Arch Linux

# Exports & Paths
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${HOME}/.bun/bin:${PATH}"
export EDITOR="nvim"
export VISUAL="nvim"
export BROWSER="brave"
export TERMINAL="kitty"

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory sharehistory incappendhistory hist_ignore_all_dups hist_ignore_space

# Keybindings (vi / standard mac mode)
bindkey -e
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# Completion
autoload -Uz compinit
compinit -d ~/.cache/zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Starship Prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# Zsh Syntax Highlighting & Autosuggestions
if [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
if [[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Handy Aliases
alias ls="ls --color=auto"
alias ll="ls -lah --color=auto"
alias la="ls -A --color=auto"
alias grep="grep --color=auto"
alias ip="ip -color=auto"
alias sysupdate="sudo pacman -Syu && yay -Sua"
alias pacclean="sudo pacman -Rns \$(pacman -Qtdq) 2>/dev/null || true; yay -Sc --noconfirm"
alias reload-hypr="hyprctl reload"
alias woofer-boost="sudo /usr/local/bin/macbook-cs4208-woofers.sh"

# Fastfetch welcome
if [[ -o interactive ]] && command -v fastfetch >/dev/null 2>&1 && [[ -z "${FASTFETCH_RAN:-}" ]]; then
    export FASTFETCH_RAN=1
    fastfetch
fi
