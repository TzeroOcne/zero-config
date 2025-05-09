start_new_ssh_agent() {
	eval $(ssh-agent -s)
}

kill_current_ssh_agent() {
	eval $(ssh-agent -k)
}

delete_empty_ssh_folders() {
  # Find empty directories starting with /tmp/ssh-
  empty_folders=(/tmp/ssh-*(NOn))

  if [ -z "$empty_folders" ]; then
    echo "No empty ssh folders found."
    return
  fi

  # Loop through each empty folder and remove it
  for folder in $empty_folders; do
    echo "Removing empty ssh folder: $folder"
    rmdir "$folder"
  done
}

cleanup_ssh_agents() {
  deactivateBanner
  # Get the PIDs of all running ssh-agent processes
  agent_pids=$(ps | grep '[s]sh-agent' | awk '{print $1}')

  if [ -z "$agent_pids" ]; then
    echo "No ssh-agent processes found."
    return
  fi

  # Get a list of all ssh-agent socket files
  socket_files=(/tmp/ssh-*(N))

  if [ -z "$socket_files" ]; then
    echo "No ssh-agent socket files found."
    return
  fi

  # Loop through each socket file
  for socket_file in $socket_files; do
    # Extract the PID from the socket file name
    pid=$(ls "$socket_file" | awk -F. '{print $2}')
    ((pid = pid + 1))

    # Check if the corresponding ssh-agent process is still running
    if ! echo "$agent_pids" | grep -q "^$pid$"; then
      echo "Removing orphaned socket file: $socket_file $pid"
      rm -rf "$socket_file"
    fi
  done
  activateBanner
}

load_current_ssh_agent() {
	AGENT_PID_LIST=$(ps | grep ssh-agent$ | awk '{print $1}')
	if [ -z "$AGENT_PID_LIST" ]; then
		start_new_ssh_agent
	else
		OPTIONS=(0)
		IDX=0
		echo "[0] Start new agent"
		while read -r AGENT_PID; do
			((IDX++))
			((AUTH_SOCK_NUM = AGENT_PID - 1))
			AUTH_SOCK=$(ls /tmp/ssh*/agent*$AUTH_SOCK_NUM 2>/dev/null)
			AGENT_DATA=$(SSH_AGENT_PID=$AGENT_PID SSH_AUTH_SOCK=$AUTH_SOCK ssh-add -l | head -n 1)
			AGENT_EMAIL=$(echo $AGENT_DATA | cut -d' ' -f3)
			OPTIONS+=($AGENT_PID)
			OPTIONS+=($AUTH_SOCK)
			if [ "$AGENT_EMAIL" = "has" ]; then
				AGENT_EMAIL=""
			fi
			echo "[$IDX] PID: $AGENT_PID $AGENT_EMAIL"
		done <<<"$AGENT_PID_LIST"
		printf "Select between 1 to $IDX to select existing agents\nor 0 to start new one (default: 0): "
		read -r REPLY
		if [ -z "$REPLY" ]; then
			REPLY=0
		fi
		case $REPLY in
		0)
			start_new_ssh_agent
			;;
		*)
			AUTH_SOCK_INDEX=$((REPLY * 2 + 1))
			AGENT_PID_INDEX=$((AUTH_SOCK_INDEX - 1))
			export SSH_AUTH_SOCK=${OPTIONS[$AUTH_SOCK_INDEX]}
			export SSH_AGENT_PID=${OPTIONS[$AGENT_PID_INDEX]}
			echo "Agent PID $SSH_AGENT_PID loaded"
			;;
		esac
	fi
}

HISTFILE=~/.config/zsh/history/.zsh_history

BANNER_ACTIVE=0

activateBanner() {
  BANNER_ACTIVE=1
}

deactivateBanner() {
  BANNER_ACTIVE=0
}

toggleBanner() {
  ((BANNER_ACTIVE = 1 - BANNER_ACTIVE))
}

DONE_BANNER="\x1b[1;32m
██████╗  ██████╗ ███╗   ██╗███████╗
██╔══██╗██╔═══██╗████╗  ██║██╔════╝
██║  ██║██║   ██║██╔██╗ ██║█████╗  
██║  ██║██║   ██║██║╚██╗██║██╔══╝  
██████╔╝╚██████╔╝██║ ╚████║███████╗
╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝
                                   "

ERROR_BANNER="\033[1;31m
███████╗██████╗ ██████╗  ██████╗ ██████╗ 
██╔════╝██╔══██╗██╔══██╗██╔═══██╗██╔══██╗
█████╗  ██████╔╝██████╔╝██║   ██║██████╔╝
██╔══╝  ██╔══██╗██╔══██╗██║   ██║██╔══██╗
███████╗██║  ██║██║  ██║╚██████╔╝██║  ██║
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝
                                         "

bannerDone() {
  if [[ $BANNER_ACTIVE == 1 ]]; then
    echo $DONE_BANNER
  fi
}

bannerError() {
  if [[ $BANNER_ACTIVE == 1 ]]; then
    echo $ERROR_BANNER
  fi
}

alias oil='nvim -c "Oil"'
alias bare="NVIM_APPNAME=nvim-bare nvim"
alias nvim-lazy="NVIM_APPNAME=nvim-lazy nvim"
alias lazy=nvim-lazy
alias nvim-mini="NVIM_APPNAME=nvim-mini nvim"
alias mini=nvim-mini
alias dadbod='nvim -c "DBUI"'
alias nvq='nvim -c "q"'
alias rmshada='rm -rf $LOCALAPPDATA/nvim*data/shada/*'
alias rmswap='rm -rf $LOCALAPPDATA/nvim*data/swap/*'
alias lg='lazygit'
alias gim='git init;git branch -M main;bannerDone'

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
