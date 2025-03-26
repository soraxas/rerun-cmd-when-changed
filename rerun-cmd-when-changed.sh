#!/bin/sh

# SIGINT handler to gracefully exit
sigint_handler() {
  kill $PID
  exit
}

# Exit immediately if any command fails
set -e

# Trap SIGINT signal (Ctrl+C) to handle interruption
trap sigint_handler SIGINT

# Function to display help message
usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help              Display this help message and exit.
  -f, --file FILE         Watch a specific file.
  -d, --watch-directory DIR  Watch a specific directory.

Examples:
  $(basename "$0") -f /path/to/file
  $(basename "$0") -d /path/to/directory
EOF
}

# shellcheck disable=SC2116,SC2028
EOL=$(echo '\00\07\01\00')

# Process command-line arguments
if [ "$#" != 0 ]; then
  set -- "$@" "$EOL"
  while [ "$1" != "$EOL" ]; do
    opt="$1"; shift
    case "$opt" in
      -h|--help)
        usage
        exit 0
        ;;
      -f|--file)
        FILE_TO_WATCH="$1"
        shift
        ;;
      -d|--watch-directory)
        DIRECTORY_TO_WATCH="$1"
        shift
        ;;
      --*=*)  # Convert '--name=arg' to '--name' 'arg'
        set -- "${opt%%=*}" "${opt#*=}" "$@"
        ;;
      -[!-]?*)  # Convert '-abc' to '-a' '-b' '-c'
        # shellcheck disable=SC2046  # We want word splitting
        set -- $(echo "${opt#-}" | sed 's/\(.\)/ -\1/g') "$@"
        ;;
      --)  # Process remaining arguments as positional
        while [ "$1" != "$EOL" ]; do set -- "$@" "$1"; shift; done
        ;;
      -*)
        echo "Error: Unsupported flag '$opt'" >&2
        exit 1
        ;;
      *)
        # Set back any unused args
        set -- "$@" "$opt"
    esac
  done
  shift  # Remove the EOL token
fi

# Ensure that only one option (file or directory) is set
if [ -n "$DIRECTORY_TO_WATCH" ] && [ -n "$FILE_TO_WATCH" ]; then
  echo "> Error: Can only watch a file OR a directory, not both." >&2
  usage
  exit 1
elif [ -z "$DIRECTORY_TO_WATCH" ] && [ -z "$FILE_TO_WATCH" ]; then
  echo "> Error: You must provide either a file or a directory to watch." >&2
  usage
  exit 1
fi

# Watch file or directory based on user input
while true; do
  $@
  if [ -n "$FILE_TO_WATCH" ]; then
    # Watch the specified file without output
    inotifywait -q -e modify -e move -e create -e delete -e attrib "$FILE_TO_WATCH" &>/dev/null &
  elif [ -n "$DIRECTORY_TO_WATCH" ]; then
    # Watch the specified directory without output
    inotifywait -q -e modify -e move -e create -e delete -e attrib -r "$DIRECTORY_TO_WATCH" &>/dev/null &
  fi

  PID=$!
  wait $PID
done
