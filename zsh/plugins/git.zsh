gpick() {
  local green="\033[32m"
  local red="\033[31m"
  local yellow="\033[33m"
  local cyan="\033[36m"
  local reset="\033[0m"

  local show_add=0 show_mod=0 show_del=0
  local branch=""
  local files_given=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -[amd]*)
        local flags="${1#-}"
        local len=${#flags}
        local c
        for ((i=1; i<=len; i++)); do
          c=$(expr substr "$flags" $i 1)
          case "$c" in
            a) show_add=1 ;;
            m) show_mod=1 ;;
            d) show_del=1 ;;
            *) echo "Unknown option: -$c"; return 1 ;;
          esac
        done
        shift
        ;;
      --) shift; break ;;
      -*)
        echo "Unknown option: $1"
        return 1
        ;;
      *)
        if [[ -z "$branch" ]]; then
          branch="$1"
        else
          files_given+=("$1")
        fi
        shift
        ;;
    esac
  done

  if (( show_add + show_mod + show_del == 0 )); then
    show_add=1
    show_mod=1
    show_del=1
  fi

  if [[ -z "$branch" ]]; then
    branch=$(git branch --format="%(refname:short)" | \
      awk -v green="$green" -v red="$red" -v cyan="$cyan" -v reset="$reset" '
        {
          if ($0 ~ /^feature\//) print green $0 reset;
          else if ($0 ~ /^hotfix\//) print red $0 reset;
          else print cyan $0 reset;
        }' | fzf --ansi --prompt="Pick a branch: ")
    [[ -z "$branch" ]] && { echo "No branch selected."; return 1; }
    branch=$(echo "$branch" | sed $'s/\033\\[[0-9;]*m//g')
  fi

  local file_array=()

  if (( ${#files_given[@]} )); then
    file_array=("${files_given[@]}")
  else
    local files
    files=$(git diff HEAD "$branch" --name-status | awk -v green="$green" -v red="$red" -v yellow="$yellow" -v reset="$reset" \
      -v show_add="$show_add" -v show_mod="$show_mod" -v show_del="$show_del" '
      {
        status = $1
        $1 = ""; sub(/^ +/, "")
        if (status ~ /^M/ && show_mod == 1)
          printf "%s[MOD]%s %s\n", yellow, reset, $0
        else if (status ~ /^A/ && show_add == 1)
          printf "%s[ADD]%s %s\n", green, reset, $0
        else if (status ~ /^D/ && show_del == 1)
          printf "%s[DEL]%s %s\n", red, reset, $0
      }' | fzf --ansi -m \
          --preview='echo {} | cut -c 8- | cut -c -4 | xargs -I{} git diff HEAD '"$branch"' -- "{}"' \
          --preview-window=right:70%:wrap \
          --prompt="Pick one or more files from $branch: ")

    [[ -z "$files" ]] && { echo "No file selected."; return 1; }

    while IFS= read -r line; do
      file_array+=("$(echo "$line" | sed -E 's/^ *\[[A-Z]+\] *//')")
    done <<< "$files"
  fi

  for f in "${file_array[@]}"; do
    git restore --source "$branch" "$f"
    echo -e "${green}Picked $f from $branch.${reset}"
  done
}
