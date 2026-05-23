COPILOT_SESSION_CACHE_DIR="$HOME/.cache/copilot"
COPILOT_SESSION_NAME_CACHE="$COPILOT_SESSION_CACHE_DIR/session-names"

copilot_cache_has_name() {
  local name="$1"

  [[ -f "$COPILOT_SESSION_NAME_CACHE" ]] || return 1
  grep -Fxq -- "$name" "$COPILOT_SESSION_NAME_CACHE"
}

copilot_cache_store_name() {
  local name="$1"

  mkdir -p "$COPILOT_SESSION_CACHE_DIR" || return 1

  if ! copilot_cache_has_name "$name"; then
    print -r -- "$name" >> "$COPILOT_SESSION_NAME_CACHE"
  fi
}

nvcop () {
  local name

  name=$(echo -n $PWD | sha256sum | cut -c1-32)
  echo "$name"

  if copilot_cache_has_name "$name"; then
    echo "Resuming session with name: $name"
    EDITOR=neovide copilot --resume="$name"
  else
    copilot_cache_store_name "$name" || return 1
    echo "Starting new session with name: $name"
    EDITOR=neovide copilot --name="$name"
  fi
}
