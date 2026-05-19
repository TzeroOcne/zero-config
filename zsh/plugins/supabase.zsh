SUPABASE_PROFILE_CACHE_DIR="${HOME}/.cache/supabase"
SUPABASE_PROFILE_ENV_DIR="${SUPABASE_PROFILE_CACHE_DIR}/profiles"
SUPABASE_PROFILE_CURRENT_FILE="${SUPABASE_PROFILE_CACHE_DIR}/current-profile"

supabase_profile_env_file() {
  local profile_name="$1"
  printf '%s/%s.env\n' "$SUPABASE_PROFILE_ENV_DIR" "$profile_name"
}

supabase_profile_validate_name() {
  local profile_name="$1"

  if [[ -z "$profile_name" ]]; then
    echo "Profile name is required."
    return 1
  fi

  if [[ ! "$profile_name" =~ '^[A-Za-z0-9._-]+$' ]]; then
    echo "Invalid profile name: $profile_name"
    echo "Use only letters, numbers, dots, underscores, and dashes."
    return 1
  fi
}

supabase_profile_current_name() {
  [[ -f "$SUPABASE_PROFILE_CURRENT_FILE" ]] || return 1
  tr -d '\r\n' < "$SUPABASE_PROFILE_CURRENT_FILE"
}

supabase_profile_exists() {
  local profile_name="$1"
  [[ -f "$(supabase_profile_env_file "$profile_name")" ]]
}

supabase_profile_store() {
  local token="$1"
  local profile_name="$2"
  local env_file

  [[ -n "$token" ]] || {
    echo "Token is required."
    return 1
  }

  supabase_profile_validate_name "$profile_name" || return 1

  mkdir -p "$SUPABASE_PROFILE_ENV_DIR" || return 1
  env_file="$(supabase_profile_env_file "$profile_name")"

  (
    umask 077
    print -r -- "export SUPABASE_PROFILE_NAME=${(qqq)profile_name}"
    print -r -- "export SUPABASE_ACCESS_TOKEN=${(qqq)token}"
  ) >| "$env_file" || return 1

  print -r -- "$profile_name" >| "$SUPABASE_PROFILE_CURRENT_FILE" || return 1
  source "$env_file" >/dev/null 2>&1 || {
    rm -f "$env_file"
    rm -f "$SUPABASE_PROFILE_CURRENT_FILE"
    echo "Failed to load Supabase profile: $profile_name"
    return 1
  }

  export SUPABASE_PROFILE_NAME
  export SUPABASE_ACCESS_TOKEN
  echo "Stored Supabase profile: $profile_name"
}

supabase_profile_use() {
  local profile_name="$1"
  local env_file

  supabase_profile_validate_name "$profile_name" || return 1

  env_file="$(supabase_profile_env_file "$profile_name")"
  if [[ ! -f "$env_file" ]]; then
    echo "No saved Supabase profile named: $profile_name"
    return 1
  fi

  source "$env_file" >/dev/null 2>&1 || {
    rm -f "$env_file"
    if [[ "$(supabase_profile_current_name 2>/dev/null)" == "$profile_name" ]]; then
      rm -f "$SUPABASE_PROFILE_CURRENT_FILE"
    fi
    echo "Removed unreadable Supabase profile: $profile_name"
    return 1
  }

  export SUPABASE_PROFILE_NAME
  export SUPABASE_ACCESS_TOKEN
  print -r -- "$profile_name" >| "$SUPABASE_PROFILE_CURRENT_FILE" || return 1
  echo "Loaded Supabase profile: $profile_name"
}

supabase_profile_list() {
  local env_files
  local env_file
  local profile_name
  local current_profile

  setopt local_options null_glob
  env_files=("$SUPABASE_PROFILE_ENV_DIR"/*.env)
  current_profile="$(supabase_profile_current_name 2>/dev/null)"

  if [[ ${#env_files[@]} -eq 0 ]]; then
    echo "No saved Supabase profiles."
    return 0
  fi

  for env_file in "${env_files[@]}"; do
    profile_name="${env_file:t:r}"
    if [[ "$profile_name" == "$current_profile" ]]; then
      echo "[current] $profile_name"
    else
      echo "[saved  ] $profile_name"
    fi
  done
}

supabase_profile_remove() {
  local profile_name="$1"
  local env_file

  supabase_profile_validate_name "$profile_name" || return 1

  env_file="$(supabase_profile_env_file "$profile_name")"
  if [[ ! -f "$env_file" ]]; then
    echo "No saved Supabase profile named: $profile_name"
    return 1
  fi

  rm -f "$env_file" || return 1

  if [[ "$(supabase_profile_current_name 2>/dev/null)" == "$profile_name" ]]; then
    rm -f "$SUPABASE_PROFILE_CURRENT_FILE"
    unset SUPABASE_PROFILE_NAME
    unset SUPABASE_ACCESS_TOKEN
  fi

  echo "Removed Supabase profile: $profile_name"
}

supabase_profile_select() {
  local env_files
  local env_file
  local profile_names=()
  local selected

  setopt local_options null_glob
  env_files=("$SUPABASE_PROFILE_ENV_DIR"/*.env)

  if [[ ${#env_files[@]} -eq 0 ]]; then
    echo "No saved Supabase profiles."
    return 1
  fi

  for env_file in "${env_files[@]}"; do
    profile_names+=("${env_file:t:r}")
  done

  if command -v gum >/dev/null 2>&1; then
    selected=$(gum choose --header="Select a Supabase profile" "${profile_names[@]}")
  else
    echo "Available Supabase profiles:"
    print -l -- "${profile_names[@]}"
    read "selected?Supabase profile: "
  fi

  [[ -n "$selected" ]] || {
    echo "No Supabase profile selected."
    return 1
  }

  supabase_profile_use "$selected"
}

supabase_profile_current() {
  local current_profile

  current_profile="$(supabase_profile_current_name 2>/dev/null)"
  if [[ -z "$current_profile" ]]; then
    echo "No active Supabase profile."
    return 1
  fi

  echo "$current_profile"
}

supabase_profile_auto_load_current() {
  local current_profile

  current_profile="$(supabase_profile_current_name 2>/dev/null)"
  [[ -n "$current_profile" ]] || return 0

  if supabase_profile_exists "$current_profile"; then
    supabase_profile_use "$current_profile" >/dev/null 2>&1 || rm -f "$SUPABASE_PROFILE_CURRENT_FILE"
  else
    rm -f "$SUPABASE_PROFILE_CURRENT_FILE"
    unset SUPABASE_PROFILE_NAME
    unset SUPABASE_ACCESS_TOKEN
  fi
}

supabase() {
  local current_token="${SUPABASE_ACCESS_TOKEN:-}"

  if [[ -n "$current_token" ]]; then
    SUPABASE_ACCESS_TOKEN="$current_token" command supabase "$@"
  else
    command supabase "$@"
  fi
}

alias supabase-profile-store='supabase_profile_store'
alias supabase-profile-use='supabase_profile_use'
alias supabase-profile-list='supabase_profile_list'
alias supabase-profile-remove='supabase_profile_remove'
alias supabase-profile-select='supabase_profile_select'
alias supabase-profile-current='supabase_profile_current'

supabase_profile_auto_load_current
