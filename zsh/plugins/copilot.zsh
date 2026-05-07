nvcop () {
  name=$(echo -n $PWD | sha256sum | cut -c1-32)
  echo $name
  id=$(sqlite3 $HOME/.copilot/session-store.db "select id from sessions where summary = '$name' limit 1"|tr -d "[:space:]")
  if [[ -n "$id" ]]; then
    echo "Resuming session with id: $id"
    EDITOR=nvim copilot --resume=$id
  else
    echo "Starting new session with name: $name"
    EDITOR=nvim copilot --name=$name
  fi
}
