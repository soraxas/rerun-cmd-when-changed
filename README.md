# File/Directory Watcher Script

This script allows you to monitor changes to a specific file or directory. It uses `inotifywait` to watch for events such as file modifications, moves, creations, deletions, or attribute changes. The script operates silently with no output, except for error messages or when the `--help` option is used.

## Features

- Watches a **file** or a **directory**.
- Supports the following file system events: modify, move, create, delete, and attribute change.
- Silent operation, with no output unless specified by the user.
- Graceful shutdown when interrupted (using Ctrl+C).
- Supports both short and long-form options for flexibility.

## Installation

### Prerequisites

- This script requires `inotifywait`, which is part of the `inotify-tools` package on Linux. You can install it using the following commands:

#### For Ubuntu/Debian-based systems:
```bash
sudo apt-get install inotify-tools
```

#### For RedHat/CentOS/Fedora-based systems:
```bash
sudo yum install inotify-tools
```

#### For macOS (using Homebrew):
```bash
brew install inotify-tools
```

### Script Setup

1. Clone this repository or copy the script to your local machine.
2. Make the script executable:

```bash
chmod +x file_directory_watcher.sh
```

## Usage

```bash
./file_directory_watcher.sh [OPTIONS]
```

### Examples

#### Watch a specific file:
```bash
./file_directory_watcher.sh -f /path/to/file
```

This command will watch the file `/path/to/file` for any changes (modifications, moves, creates, deletes, or attribute changes).

#### Watch a specific directory:
```bash
./file_directory_watcher.sh -d /path/to/directory
```

This command will watch the directory `/path/to/directory` and its contents recursively for any changes.

