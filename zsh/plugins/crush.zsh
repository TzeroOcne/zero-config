nvcrs() {
  if [[ $# -eq 1 && "$1" == "--continue" ]]; then
    echo "Continuing most recent session"
    crush --continue
  elif [[ $# -eq 0 ]]; then
    local session_id
    session_id=$(crush session list -c . 2>/dev/null | head -1 | awk '{print $1}')
    if [[ -n "$session_id" ]]; then
      echo "Resuming session $session_id for $PWD"
      EDITOR=nvim crush --session "$session_id"
    else
      echo "Starting new session for $PWD"
      EDITOR=nvim crush --cwd .
    fi
  else
    echo "Starting new session for $PWD with prompt: $*"
    EDITOR=nvim crush --cwd . --prompt "$*"
  fi
}

cls() {
  crush session list "$@"
}

crm() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: crm <session-id>"
    return 1
  fi
  crush session delete "$@"
}
