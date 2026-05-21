export LOCALAPPDATA="$(cygpath $LOCALAPPDATA)"

PRE_PATH="$PREPATH:$LOCALAPPDATA/mise/shims"
PRE_PATH="$PRE_PATH:$LOCALAPPDATA/Microsoft/WinGet/Links"
export PATH="$PRE_PATH:$PATH"
# export PATH="$PATH:$LOCALAPPDATA/Microsoft/WinGet/Links"
export PATH="$PATH:$LOCALAPPDATA/Programs/oh-my-posh/bin"
export PATH="$PATH:$HOME/Path"

for file in "$HOME/.config/zero-config/zsh/plugins"/*.zsh; do
  [ -f "$file" ] && source "$file"
done

[ ! -d ~/.config/zsh/history ] && mkdir -p ~/.config/zsh/history
HISTFILE=~/.config/zsh/history/.zsh_history

. $HOME/.config/zero-config/zsh/alias.zsh

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

eval "$(oh-my-posh init zsh --config $HOME/.config/zero-config/zero.omp.toml)"

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

eval "$(zoxide init zsh --cmd cd)"

if [[ "$OS" == "Windows_NT" && "$TERM_PROGRAM" == "WezTerm" ]]; then
  source "$HOME/.config/zero-config/zsh/integration/wezterm/windows-bash-osc.sh"
fi

# Set up zellij
# eval "$(zellij setup --generate-auto-start zsh | tr -d '\r')"

# Bind arrow keys when starting the shell
bindArrowKeys

bindkey              '^I' menu-select
bindkey "$terminfo[kcbt]" menu-select

bindkey -M menuselect              '^I'         menu-complete
bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete

activateBanner

export PATH="$HOME/.config/zero-config/zsh/scripts:$PATH"

fpath=($HOME/.config/zero-config/zsh/completions $fpath)

autoload -Uz compinit
compinit

# zmodload zsh/complist
#
# # menu select
# zstyle ':completion:*' menu select
#
# bindkey '^I' menu-select
# bindkey "$terminfo[kcbt]" reverse-menu-select
#
# bindkey -M menuselect '^I' menu-complete
# bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete

# Fix Start Path
if [[ "$(pwd)" =~ ${HOME}$ ]]; then
  cd
fi
