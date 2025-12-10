export LOCALAPPDATA="$(cygpath $LOCALAPPDATA)"

export PATH="$LOCALAPPDATA/Microsoft/WinGet/Links:$PATH"
export PATH="$PATH:$LOCALAPPDATA/mise/shims"

for file in "$HOME/.config/nnry/zsh/plugins"/*.zsh; do
  [ -f "$file" ] && source "$file"
done

HISTFILE=~/.config/zsh/history/.zsh_history

. $HOME/.config/nnry/zsh/alias.zsh

# Function to bind arrow keys outside of menuselect
bindArrowKeys() {
    bindkey "^[[A" up-line-or-search
    bindkey "^[[B" down-line-or-search
}

# Function to unbind arrow keys when in menuselect
unbindArrowKeys() {
    bindkey "^[[A" undefined
    bindkey "^[[B" undefined
}

# Hook to unbind arrow keys when entering menuselect
zle-line-init() {
    if [[ $WIDGET = menuselect || $BUFFER = python* ]]; then
        unbindArrowKeys
    else
        bindArrowKeys
    fi
}

# Hook to rebind arrow keys when leaving menuselect
zle-line-finish() {
    if [[ $WIDGET = menuselect ]]; then
        bindArrowKeys
    else
        unbindArrowKeys
    fi
}

zle -N zle-line-init
zle -N zle-line-finish

eval "$(oh-my-posh init zsh --config $HOME/.config/nnry/zero.omp.toml)"

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

eval "$(zoxide init zsh --cmd cd)"

# Bind arrow keys when starting the shell
bindArrowKeys

bindkey              '^I' menu-select
bindkey "$terminfo[kcbt]" menu-select

bindkey -M menuselect              '^I'         menu-complete
bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete

activateBanner

export PATH="$HOME/.config/nnry/zsh/scripts:$PATH"

fpath=($HOME/.config/nnry/zsh/completions $fpath)
autoload -Uz compinit
compinit
