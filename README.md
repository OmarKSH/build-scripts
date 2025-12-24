# build-scripts

A flexible shell-based build automation tool that runs project-specific build scripts inside **isolated environments** (Docker containers or chroot runtimes).

This repository is designed to make it easy to **build, package, and post-process binaries** reproducibly across different Linux distributions.

---

## Features

- 🔧 Run custom build scripts from a `scripts/` directory
- 🐳 Automatically falls back to **Docker** if no local chroot runtime is found
- 🏗️ Supports **chroot-based runtimes** (extracted root filesystems)
- 📦 Automatic dependency installation for:
  - `apt` (Debian/Ubuntu)
  - `apk` (Alpine)
  - `xbps-install` (Void Linux)
- 🧹 Post-build processing:
  - `strip` binaries
  - Optional `upx` compression
  - Optional `packelf` ELF packing
- 🛡️ Runs builds in isolated environments for safety and reproducibility
- 🎯 Interactive runtime and script selection (supports `fzf` if installed)

---

## Repository Structure

```
.
├── build.sh              # Main build runner script
├── scripts/              # Per-project build definitions
├── chroots/              # Optional chroot runtimes (.tar or directories)
└── README.md
```

---

## Build Script Format (`scripts/*`)

Each file inside `scripts/` is a **sourced shell script** that defines variables used by the build system.

Common variables:

```sh
TARGET_DIR=project-source-dir
DOWNLOAD_CMD="git clone https://example.com/project.git $TARGET_DIR"
BUILD_CMD="make"
TARGET="binary-name"
PKG_CMD=""        # Optional package install command
CLEANUP_CMD=""    # Optional cleanup command
```

If BUILD_CMD is missing, the script will drop you into an interactive shell inside the specified container/runtime.

---

## Usage

### Basic usage

```sh
./build.sh
```

This will:
1. Prompt you to select a build script
2. Prompt you to select a runtime (or fall back to Docker)

### Specify script or runtime

```sh
./build.sh <script-name> <runtime-name>
```

Examples:

```sh
./build.sh zip alpine
./build.sh dwm ubuntu:22.04
```

---

## Runtimes

### Docker (default)

If no matching runtime is found in `chroots/`, Docker is used automatically

### Chroot runtimes

You can place extracted root filesystems or tarballs in `chroots/`:

```
chroots/
├── alpine.tar.gz
├── voidlinux/
│   ├── bin/
│   ├── dev/
│   ├── proc/
│   └── sys/
```

These will be detected and offered as selectable runtimes.

---

## Output Behavior

- Built binaries are copied back to the host directory
- If name collisions occur, random suffixes are added
- You are prompted before deleting source directories or runtimes

---

## Requirements

- POSIX-compatible shell (`sh`)
- One of:
  - Docker
  - `sudo` + chroot-capable Linux system
- Optional tools:
  - `fzf` (interactive selection)
  - `upx` (binary compression)
  - `git`

---

## Safety Notes

- This script runs commands as **root inside containers or chroots**
- Review build scripts before running
- Use trusted Docker images or chroot archives only
