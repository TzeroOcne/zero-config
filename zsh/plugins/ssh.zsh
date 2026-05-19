SSH_AGENT_ENV_DIR="${HOME}/.cache/ssh-agents"

ssh_agent_env_file() {
  local agent_name="$1"
  printf '%s/%s.env\n' "$SSH_AGENT_ENV_DIR" "$agent_name"
}

ssh_agent_restore_env() {
  local previous_pid="$1"
  local previous_sock="$2"

  if [[ -n "$previous_pid" ]]; then
    export SSH_AGENT_PID="$previous_pid"
  else
    unset SSH_AGENT_PID
  fi

  if [[ -n "$previous_sock" ]]; then
    export SSH_AUTH_SOCK="$previous_sock"
  else
    unset SSH_AUTH_SOCK
  fi
}

ssh_agent_is_valid() {
  [[ -n "$SSH_AGENT_PID" ]] || return 1
  [[ -n "$SSH_AUTH_SOCK" ]] || return 1
  kill -0 "$SSH_AGENT_PID" 2>/dev/null || return 1
  [[ -S "$SSH_AUTH_SOCK" ]] || return 1

  SSH_AGENT_PID="$SSH_AGENT_PID" SSH_AUTH_SOCK="$SSH_AUTH_SOCK" ssh-add -l >/dev/null 2>&1
  case $? in
    0|1) return 0 ;;
    *) return 1 ;;
  esac
}

ssh_agent_env_is_valid() {
  local env_file="$1"
  [[ -f "$env_file" ]] || return 1

  (
    source "$env_file" >/dev/null 2>&1 || exit 1
    ssh_agent_is_valid
  )
}

ssh_agent_read_value() {
  local env_file="$1"
  local variable_name="$2"

  (
    source "$env_file" >/dev/null 2>&1 || exit 1
    print -r -- ${(P)variable_name}
  )
}

cleanup_dead_ssh_agents() {
  local env_files
  local env_file
  local agent_name
  local agent_pid
  local removed=0

  setopt local_options null_glob
  env_files=("$SSH_AGENT_ENV_DIR"/*.env)

  for env_file in "${env_files[@]}"; do
    if ssh_agent_env_is_valid "$env_file"; then
      continue
    fi

    agent_name="${env_file:t:r}"
    agent_pid="$(ssh_agent_read_value "$env_file" SSH_AGENT_PID 2>/dev/null)"
    echo "Removed dead SSH agent: $agent_name${agent_pid:+ ($agent_pid)}"
    rm -f "$env_file"
    removed=$((removed + 1))
  done

  if [[ "$removed" -eq 0 ]]; then
    echo "No dead SSH agents found."
  fi
}

ssh_agent_validate_name() {
  local agent_name="$1"

  if [[ -z "$agent_name" ]]; then
    echo "Agent name is required."
    return 1
  fi

  if [[ ! "$agent_name" =~ '^[A-Za-z0-9._-]+$' ]]; then
    echo "Invalid agent name: $agent_name"
    echo "Use only letters, numbers, dots, underscores, and dashes."
    return 1
  fi
}

start_named_ssh_agent() {
  local agent_name="$1"
  local env_file

  ssh_agent_validate_name "$agent_name" || return 1

  env_file="$(ssh_agent_env_file "$agent_name")"
  mkdir -p "$SSH_AGENT_ENV_DIR" || return 1

  if [[ -f "$env_file" ]]; then
    kill_named_ssh_agent "$agent_name" >/dev/null 2>&1 || rm -f "$env_file"
  fi

  ssh-agent -s >| "$env_file" || return 1
  source "$env_file" >/dev/null 2>&1 || return 1

  if ! ssh_agent_is_valid; then
    rm -f "$env_file"
    echo "Failed to start SSH agent: $agent_name"
    return 1
  fi

  echo "Loaded SSH agent: $agent_name ($SSH_AGENT_PID)"
}

load_named_ssh_agent() {
  local agent_name="$1"
  local env_file
  local previous_pid="$SSH_AGENT_PID"
  local previous_sock="$SSH_AUTH_SOCK"

  ssh_agent_validate_name "$agent_name" || return 1

  env_file="$(ssh_agent_env_file "$agent_name")"

  if [[ ! -f "$env_file" ]]; then
    echo "No saved SSH agent named: $agent_name"
    return 1
  fi

  source "$env_file" >/dev/null 2>&1 || {
    rm -f "$env_file"
    ssh_agent_restore_env "$previous_pid" "$previous_sock"
    echo "Removed unreadable SSH agent file: $agent_name"
    return 1
  }

  if ! ssh_agent_is_valid; then
    rm -f "$env_file"
    ssh_agent_restore_env "$previous_pid" "$previous_sock"
    echo "Removed stale SSH agent: $agent_name"
    return 1
  fi

  echo "Loaded SSH agent: $agent_name ($SSH_AGENT_PID)"
}

list_ssh_agents() {
  local env_files
  local env_file
  local agent_name
  local agent_pid
  local key_summary

  cleanup_dead_ssh_agents >/dev/null

  setopt local_options null_glob
  env_files=("$SSH_AGENT_ENV_DIR"/*.env)

  if [[ ${#env_files[@]} -eq 0 ]]; then
    echo "No saved SSH agents."
    return 0
  fi

  for env_file in "${env_files[@]}"; do
    agent_name="${env_file:t:r}"
    agent_pid="$(ssh_agent_read_value "$env_file" SSH_AGENT_PID 2>/dev/null)"

    if ssh_agent_env_is_valid "$env_file"; then
      key_summary="$(
        source "$env_file" >/dev/null 2>&1 || exit 1
        ssh-add -l 2>/dev/null | head -n 1
      )"

      if [[ -n "$key_summary" ]]; then
        echo "[alive] $agent_name ($agent_pid) - $key_summary"
      else
        echo "[alive] $agent_name ($agent_pid)"
      fi
    fi
  done
}

kill_named_ssh_agent() {
  local agent_name="$1"
  local env_file
  local previous_pid="$SSH_AGENT_PID"
  local previous_sock="$SSH_AUTH_SOCK"
  local target_pid
  local target_sock

  ssh_agent_validate_name "$agent_name" || return 1

  env_file="$(ssh_agent_env_file "$agent_name")"

  if [[ ! -f "$env_file" ]]; then
    echo "No saved SSH agent named: $agent_name"
    return 1
  fi

  source "$env_file" >/dev/null 2>&1 || {
    rm -f "$env_file"
    ssh_agent_restore_env "$previous_pid" "$previous_sock"
    echo "Removed unreadable SSH agent file: $agent_name"
    return 1
  }

  target_pid="$SSH_AGENT_PID"
  target_sock="$SSH_AUTH_SOCK"

  if ssh_agent_is_valid; then
    SSH_AGENT_PID="$target_pid" SSH_AUTH_SOCK="$target_sock" ssh-agent -k >/dev/null 2>&1 || {
      ssh_agent_restore_env "$previous_pid" "$previous_sock"
      return 1
    }
  fi

  rm -f "$env_file"

  if [[ "$previous_pid" != "$target_pid" || "$previous_sock" != "$target_sock" ]]; then
    ssh_agent_restore_env "$previous_pid" "$previous_sock"
  else
    unset SSH_AGENT_PID
    unset SSH_AUTH_SOCK
  fi

  echo "Removed SSH agent: $agent_name"
}

select_named_ssh_agent() {
  local env_files
  local env_file
  local agent_names=()
  local selected
  local agent_name

  cleanup_dead_ssh_agents >/dev/null

  setopt local_options null_glob
  env_files=("$SSH_AGENT_ENV_DIR"/*.env)

  for env_file in "${env_files[@]}"; do
    if ssh_agent_env_is_valid "$env_file"; then
      agent_names+=("${env_file:t:r}")
    fi
  done

  if [[ ${#agent_names[@]} -eq 0 ]]; then
    echo "No saved SSH agents. Starting a new one requires a name."
    return 1
  fi

  if command -v gum >/dev/null 2>&1; then
    selected=$(gum choose --header="Select an SSH agent" "Start new agent" "${agent_names[@]}")
  else
    echo "Available SSH agents:"
    print -l -- "${agent_names[@]}"
    echo "Type an agent name to load, or type 'Start new agent'."
    read "selected?SSH agent: "
  fi

  if [[ "$selected" == "Start new agent" ]]; then
    if command -v gum >/dev/null 2>&1; then
      agent_name=$(gum input --placeholder="agent name")
    else
      read "agent_name?New SSH agent name: "
    fi

    [[ -n "$agent_name" ]] || {
      echo "Agent name is required."
      return 1
    }

    start_named_ssh_agent "$agent_name"
    return $?
  fi

  load_named_ssh_agent "$selected"
}

start_new_ssh_agent() {
  local agent_name="${1:-default}"
  start_named_ssh_agent "$agent_name"
}

load_current_ssh_agent() {
  if [[ -n "$1" ]]; then
    load_named_ssh_agent "$1"
  else
    select_named_ssh_agent
  fi
}

kill_current_ssh_agent() {
  local env_file

  if ! ssh_agent_is_valid; then
    echo "No active SSH agent is loaded."
    return 1
  fi

  for env_file in "$SSH_AGENT_ENV_DIR"/*.env(N); do
    if [[ "$(ssh_agent_read_value "$env_file" SSH_AGENT_PID 2>/dev/null)" == "$SSH_AGENT_PID" ]] && [[ "$(ssh_agent_read_value "$env_file" SSH_AUTH_SOCK 2>/dev/null)" == "$SSH_AUTH_SOCK" ]]; then
      kill_named_ssh_agent "${env_file:t:r}"
      return $?
    fi
  done

  ssh-agent -k >/dev/null 2>&1 || return 1
  unset SSH_AGENT_PID
  unset SSH_AUTH_SOCK
  echo "Killed current SSH agent."
}

alias ssh-agent-start='start_named_ssh_agent'
alias ssh-agent-load='load_named_ssh_agent'
alias ssh-agent-list='list_ssh_agents'
alias ssh-agent-kill='kill_named_ssh_agent'
alias ssh-agent-select='select_named_ssh_agent'
alias ssh-agent-clean='cleanup_dead_ssh_agents'
