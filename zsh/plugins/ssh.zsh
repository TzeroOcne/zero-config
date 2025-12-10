start_new_ssh_agent() {
  # Define your agent start logic here
  echo "Starting new SSH agent..."
  eval $(ssh-agent -s)
}

kill_current_ssh_agent() {
	eval $(ssh-agent -k)
}

delete_empty_ssh_folders() {
  # Loop through directories starting with /tmp/ssh-
  for folder in /tmp/ssh-*; do
    # Check if it's a directory and exists
    [ -d "$folder" ] || continue

    # Check if the directory is empty
    if [ -z "$(ls -A "$folder")" ]; then
      echo "Removing empty ssh folder: $folder"
      rmdir "$folder"
    fi
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
	AGENT_PID_LIST=("${(@f)$(ps ax | grep '[s]sh-agent' | awk '{print $1}')}")

	if [ ${#AGENT_PID_LIST[@]} -eq 0 ]; then
		start_new_ssh_agent
	else
		OPTIONS=("Start new agent")
		AGENT_PIDS=()
		AUTH_SOCKS=()

		for AGENT_PID in $AGENT_PID_LIST; do
			((AUTH_SOCK_NUM = AGENT_PID - 1))
			AUTH_SOCK=$(ls /tmp/ssh*/agent*${AUTH_SOCK_NUM} 2>/dev/null | head -n1)
			if [ -z "$AUTH_SOCK" ]; then
				continue
			fi
			AGENT_DATA=$(SSH_AGENT_PID=$AGENT_PID SSH_AUTH_SOCK=$AUTH_SOCK ssh-add -l 2>/dev/null | head -n1)
			AGENT_EMAIL=$(echo "$AGENT_DATA" | cut -d' ' -f3)
			[[ "$AGENT_EMAIL" == "has" ]] && AGENT_EMAIL=""
			OPTIONS+=("PID: $AGENT_PID $AGENT_EMAIL")
			AGENT_PIDS+=("$AGENT_PID")
			AUTH_SOCKS+=("$AUTH_SOCK")
		done

		if [ ${#AGENT_PIDS[@]} -eq 0 ]; then
			start_new_ssh_agent
			return
		fi

    SELECTED=$(gum choose --header="Select an SSH agent" "${OPTIONS[@]}")

		if [[ "$SELECTED" == "Start new agent" ]]; then
			start_new_ssh_agent
		else
      for i in {1..${#OPTIONS[@]}}; do
				if [[ "${OPTIONS[$i]}" == "$SELECTED" ]]; then
					INDEX=$((i - 1)) # subtract one since first option is "Start new agent"
					export SSH_AGENT_PID="${AGENT_PIDS[$INDEX]}"
					export SSH_AUTH_SOCK="${AUTH_SOCKS[$INDEX]}"
					echo "Agent PID $SSH_AGENT_PID loaded"
					break
				fi
			done
		fi
	fi
}

LOCKFILE="/tmp/.ssh_cleanup_done"

if [ ! -f "$LOCKFILE" ]; then
  touch "$LOCKFILE"
  echo "Cleaning up SSH agents and empty folders..."

  cleanup_ssh_agents
  delete_empty_ssh_folders
fi
