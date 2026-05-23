OPENCODE_CACHE_DIR="$HOME/.cache/opencode"
OPENCODE_DIR_SESSION_CACHE="$OPENCODE_CACHE_DIR/dir-sessions"

opencode_dir_hash() {
  echo -n "$PWD" | sha256sum | cut -c1-32
}

opencode_cached_session() {
  local hash="$1"
  [[ -f "$OPENCODE_DIR_SESSION_CACHE" ]] || return 1
  grep -m1 "^$hash " "$OPENCODE_DIR_SESSION_CACHE" | cut -d' ' -f2
}

opencode_cache_session() {
  local hash="$1" session_id="$2"
  mkdir -p "$OPENCODE_CACHE_DIR" || return 1
  if [[ -f "$OPENCODE_DIR_SESSION_CACHE" ]]; then
    sed -i "/^$hash /d" "$OPENCODE_DIR_SESSION_CACHE"
  fi
  print -r -- "$hash $session_id" >> "$OPENCODE_DIR_SESSION_CACHE"
}

nvopc() {
  local hash session_id
  hash=$(opencode_dir_hash)
  session_id=$(opencode_cached_session "$hash")

  if [[ -n "$session_id" ]]; then
    echo "Resuming session $session_id for $PWD"
    opencode --session "$session_id"
  else
    echo "Starting new session for $PWD"
    opencode
    # Cache the last session ID upon exit
    if [[ $? -eq 0 ]]; then
      local last_session
      last_session=$(opencode session list --format json 2>/dev/null | python3 -c "
import sys, json
try:
    sessions = json.load(sys.stdin)
    if sessions:
        print(sessions[-1].get('id', ''))
except: pass
" 2>/dev/null)
      [[ -n "$last_session" ]] && opencode_cache_session "$hash" "$last_session"
    fi
  fi
}

ocls() {
  opencode session list "$@"
}

ocrm() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: ocrm <session-id>"
    return 1
  fi
  opencode session delete "$@"
  if [[ -f "$OPENCODE_DIR_SESSION_CACHE" ]]; then
    for id in "$@"; do
      sed -i "/ $id$/d" "$OPENCODE_DIR_SESSION_CACHE"
    done
  fi
}
