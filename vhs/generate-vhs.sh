#!/bin/bash

script_dir=$(dirname "$0")
cd "$script_dir" || exit

commands=("vhs" "nvim" "parallel" "find")
for cmd in "${commands[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo >&2 "I require $cmd, but it's not installed. Aborting."
    exit 1
  fi
done

print_usage() {
  echo 'Usage: ./generate-vhs.sh [ opts ]'
  echo '  -u, --update: Update Neovim plugins etc.'
  echo '  -h, --help: Print this help text.'
}

TEMP=$(getopt -o 'uh' --long 'update,help' -n 'generate-vhs.sh' -- "$@")
eval set -- "$TEMP"
unset TEMP

update_flag=false

while true; do
  case "$1" in
  '-h' | '--help')
    print_usage
    exit 1
    ;;
  '-u' | '--update')
    migrate_flag=true
    shift
    continue
    ;;
  '--')
    shift
    break
    ;;
  *)
    echo 'Internal error!' >&2
    exit 1
    ;;
  esac
done

if [ "$update_flag" = true ]; then
  ./nvim --headless -c "+Lazy! sync" +qa
fi

find -type f -name "*.tape" | parallel vhs
