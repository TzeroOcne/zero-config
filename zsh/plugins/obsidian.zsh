obsc() {
  local cmd=$1
  shift

  case "$cmd" in
    init)
      # --- Step 1: Ensure .obsidian folder exists ---
      mkdir -p ".obsidian"

      # Files to initialize
      local files=(app.json appearance.json core-plugins.json graph.json workspace.json)

      for f in "${files[@]}"; do
        local file_path=".obsidian/$f"
        if [[ ! -f "$file_path" ]]; then
          echo '{}' > "$file_path"
          echo "➕ Created $file_path"
        else
          # Validate JSON and ensure it's an object
          if jq -e 'type == "object"' "$file_path" >/dev/null 2>&1; then
            echo "✔ Valid $file_path"
          else
            echo '{}' > "$file_path"
            echo "✘ Overwritten invalid $file_path"
          fi
        fi
      done
      echo "Initialized .obsidian with valid JSON files."

      # Path to obsidian.json
      local obsidian_json="$APPDATA/obsidian/obsidian.json"
      mkdir -p "$(dirname "$obsidian_json")"

      # Load existing or default
      local existing
      if [[ -f "$obsidian_json" ]]; then
        if jq -e 'type == "object" and has("vaults")' "$obsidian_json" >/dev/null 2>&1; then
          existing=$(<"$obsidian_json")
        else
          echo '{"vaults":{}}' > "$obsidian_json"
          existing='{"vaults":{}}'
          echo "✘ Overwritten invalid $obsidian_json"
        fi
      else
        existing='{"vaults":{}}'
      fi

      # Current absolute path (Windows-compatible, with backslashes)
      local current_path="$(pwd -W 2>/dev/null || pwd)"
      current_path="${current_path//\//\\}"   # replace / with \

      # Check if vault path already exists
      if jq -e --arg path "$current_path" \
            '.vaults | to_entries[] | select(.value.path == $path)' \
            <<<"$existing" >/dev/null; then
        echo "✔ Vault already exists for path: $current_path"
        return 0
      fi

      # Generate random hex id (16 chars)
      local vault_id
      if command -v xxd >/dev/null 2>&1; then
        vault_id=$(xxd -l 8 -p /dev/urandom | tr -d '\n')
      elif command -v openssl >/dev/null 2>&1; then
        vault_id=$(openssl rand -hex 8)
      else
        vault_id=$(date +%s | md5sum | cut -c1-16)
      fi

      # Timestamp in ms
      local ts=$(($(date +%s%N)/1000000))

      echo "vault_id: $vault_id"
      echo "path:     $current_path"
      echo "ts:       $ts"

      # Append vault entry (write back to obsidian.json)
      jq -c --arg id "$vault_id" \
            --arg path "$current_path" \
            --argjson ts "$ts" \
            '.vaults[$id] = {"path":$path,"ts":$ts}' \
            <<<"$existing" > "$obsidian_json"

      echo "➕ Added new vault to $obsidian_json"

      # Ensure $vault_id.json exists inside $APPDATA/obsidian
      local vault_file="$APPDATA/obsidian/$vault_id.json"
      if [[ ! -f "$vault_file" ]]; then
        echo '{}' > "$vault_file"
        echo "➕ Created $vault_file"
      else
        if jq -e 'type == "object"' "$vault_file" >/dev/null 2>&1; then
          echo "✔ Valid $vault_file"
        else
          echo '{}' > "$vault_file"
          echo "✘ Overwritten invalid $vault_file"
        fi
      fi
      ;;
    open)
      # Current absolute path with backslashes
      local current_path="$(pwd -W 2>/dev/null || pwd)"
      current_path="${current_path//\//\\}"

      local uri="obsidian://open?path=$current_path"
      echo "Opening Obsidian with URI:"
      echo "$uri"

      # Windows: use start, Linux: xdg-open, macOS: open
      if command -v start >/dev/null 2>&1; then
        start "" "$uri"
      elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$uri"
      elif command -v open >/dev/null 2>&1; then
        open "$uri"
      else
        echo "⚠️ Could not detect how to open URI. Please open manually."
      fi
      ;;
    *)
      echo "Usage: obsc <command>"
      echo
      echo "Commands:"
      echo "  init    Initialize .obsidian folder and register vault"
      echo "  open    Open current folder in Obsidian via URI"
      ;;
  esac
}
