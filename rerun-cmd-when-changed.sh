#!/bin/sh

# SIGINT handler to gracefully exit
sigint_handler() {
  kill $PID 2>&1 | pipe_output
  exit
}

# Exit immediately if any command fails
set -e

# Trap SIGINT signal (Ctrl+C) to handle interruption
trap sigint_handler SIGINT

# Function to display help message
usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS] <COMMAND...>

Options:
  -h, --help              Display this help message and exit.
  -f, --file FILE         Watch a specific file.
  -d, --directory DIR     Recursively watch a specific directory (default: current directory).
  -v, --verbose           Verbose
  -r, --recursive         Watch directories recursively (default: false).

Examples:
  $(basename "$0") -f /path/to/file -- echo hello
  $(basename "$0") -d /path/to/directory python main.py
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
      -d|--directory)
        DIRECTORY_TO_WATCH="$1"
        shift
        ;;
      -r|--recursive)
        RECURSIVE=true
        ;;
      -v|--verbose)
        VERBOSE=true
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
  # default to current directory if neither is specified
  DIRECTORY_TO_WATCH="."
fi

if [ $# -lt 1 ]; then
  echo "> Error: No command provided."
  usage
  exit 1
fi

DEPS="inotifywait"
# Check if required dependencies are installed
for dep in $DEPS; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    echo "> Error: Required dependency '$dep' is not installed." >&2
    exit 1
  fi
done

# Function to handle verbose mode
pipe_output() {
  if [ -n "$VERBOSE" ]; then
    cat # Pipe to stdout
  else
    cat >/dev/null # Pipe to /dev/null
  fi
}

# Watch file or directory based on user input
while true; do
  "$@" &
  PID=$!

  if [ -n "$FILE_TO_WATCH" ]; then
    # Watch the specified file without output
    inotifywait -q -e modify -e move -e create -e delete -e attrib "$FILE_TO_WATCH" &>/dev/null
  elif [ -n "$DIRECTORY_TO_WATCH" ]; then
    # Watch the specified directory without output
    inotifywait -q -e modify -e move -e create -e delete -e attrib $([ "$RECURSIVE" = true ] && echo "-r") "$DIRECTORY_TO_WATCH" &>/dev/null
  fi

  # the process might have already exited, hence the || true
  kill $PID 2>&1 | pipe_output || true
done
