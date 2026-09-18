#!/bin/sh

# Esattosoft AI Agent installer for macOS Apple Silicon
# Public installer. Application source remains private.

set -eu

REPO="Esattosoft/esattosoft-ai-agent-docs"
METADATA_URL="https://raw.githubusercontent.com/${REPO}/main/latest.json"

BIN_DIR="${HOME}/.local/bin"
COMMAND_PATH="${BIN_DIR}/esattosoft-ai"

RUNTIME_PARENT="${HOME}/.local/lib"
RUNTIME_DIR="${RUNTIME_PARENT}/esattosoft-ai"
RUNTIME_EXEC="${RUNTIME_DIR}/esattosoft-ai"

step() {
    printf '[Esattosoft] %s\n' "$1"
}

ok() {
    printf '[OK] %s\n' "$1"
}

warn() {
    printf '[!] %s\n' "$1"
}

fail() {
    printf '\n[ERROR] %s\n' "$1" >&2
    exit 1
}

json_string() {
    key="$1"
    printf '%s\n' "$METADATA" \
        | /usr/bin/sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        | /usr/bin/head -n 1
}

cleanup() {
    if [ -n "${TEMP_DIR:-}" ] && [ -d "$TEMP_DIR" ]; then
        /bin/rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT HUP INT TERM

OS="$(/usr/bin/uname -s)"
ARCH="$(/usr/bin/uname -m)"

[ "$OS" = "Darwin" ] || fail "This installer supports macOS only."

if [ "$ARCH" != "arm64" ]; then
    fail "This release currently supports macOS Apple Silicon (arm64) only. Detected architecture: $ARCH"
fi

command -v curl >/dev/null 2>&1 || fail "curl is required but was not found."
[ -x /usr/bin/shasum ] || fail "shasum is required but was not found."
[ -x /usr/bin/tar ] || fail "tar is required but was not found."

step "Checking latest macOS release..."

METADATA="$(/usr/bin/curl -fsSL --retry 3 "$METADATA_URL")" \
    || fail "Could not download release metadata."

VERSION="$(json_string macos_arm64_version)"
DOWNLOAD_URL="$(json_string macos_arm64)"
EXPECTED_SHA="$(json_string macos_arm64_sha256)"

if [ -z "$VERSION" ] || [ -z "$DOWNLOAD_URL" ] || [ -z "$EXPECTED_SHA" ]; then
    fail "macOS release metadata is incomplete."
fi

step "Latest macOS version: $VERSION"

TEMP_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/esattosoft-ai-install.XXXXXX")" \
    || fail "Could not create temporary directory."

TEMP_ARCHIVE="${TEMP_DIR}/esattosoft-ai-macos-arm64.tar.gz"
EXTRACT_DIR="${TEMP_DIR}/extract"
OLD_RUNTIME_BACKUP="${TEMP_DIR}/old-runtime"
OLD_COMMAND_BACKUP="${TEMP_DIR}/old-command"

step "Downloading Esattosoft AI Agent..."

 /usr/bin/curl \
    -fL \
    --retry 3 \
    --connect-timeout 20 \
    "$DOWNLOAD_URL" \
    -o "$TEMP_ARCHIVE" \
    || fail "Download failed."

step "Verifying SHA256..."

ACTUAL_SHA="$(/usr/bin/shasum -a 256 "$TEMP_ARCHIVE" | /usr/bin/awk '{print $1}')"
EXPECTED_SHA="$(printf '%s' "$EXPECTED_SHA" | /usr/bin/tr '[:upper:]' '[:lower:]')"
ACTUAL_SHA="$(printf '%s' "$ACTUAL_SHA" | /usr/bin/tr '[:upper:]' '[:lower:]')"

if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
    fail "SHA256 verification failed. Expected $EXPECTED_SHA but received $ACTUAL_SHA."
fi

ok "SHA256 verified."

step "Extracting standalone package..."

/bin/mkdir -p "$EXTRACT_DIR"
/usr/bin/tar -xzf "$TEMP_ARCHIVE" -C "$EXTRACT_DIR" \
    || fail "Could not extract the downloaded package."

if [ ! -f "${EXTRACT_DIR}/esattosoft-ai" ]; then
    fail "Downloaded package is invalid: esattosoft-ai was not found after extraction."
fi

if [ ! -x "${EXTRACT_DIR}/esattosoft-ai" ]; then
    /bin/chmod 0755 "${EXTRACT_DIR}/esattosoft-ai" \
        || fail "Could not make the extracted executable runnable."
fi

PACKAGE_FILE_COUNT="$(/usr/bin/find "$EXTRACT_DIR" -type f | /usr/bin/wc -l | /usr/bin/tr -d ' ')"
if [ "${PACKAGE_FILE_COUNT:-0}" -lt 2 ]; then
    fail "Downloaded standalone package appears incomplete."
fi

/bin/mkdir -p "$BIN_DIR" "$RUNTIME_PARENT"

# Preserve the current runtime so an installation failure can roll back.
if [ -e "$RUNTIME_DIR" ]; then
    /bin/mv "$RUNTIME_DIR" "$OLD_RUNTIME_BACKUP" \
        || fail "Could not back up the existing runtime."
fi

# Preserve an existing command. v1.6.16 used a regular single binary here.
if [ -e "$COMMAND_PATH" ] || [ -L "$COMMAND_PATH" ]; then
    /bin/mv "$COMMAND_PATH" "$OLD_COMMAND_BACKUP" \
        || {
            if [ -e "$OLD_RUNTIME_BACKUP" ]; then
                /bin/mv "$OLD_RUNTIME_BACKUP" "$RUNTIME_DIR" 2>/dev/null || true
            fi
            fail "Could not back up the existing command."
        }
fi

INSTALL_OK=0

if /bin/mv "$EXTRACT_DIR" "$RUNTIME_DIR"; then
    if [ -x "$RUNTIME_EXEC" ]; then
        if /bin/ln -s "$RUNTIME_EXEC" "$COMMAND_PATH"; then
            INSTALL_OK=1
        fi
    fi
fi

if [ "$INSTALL_OK" -ne 1 ]; then
    /bin/rm -f "$COMMAND_PATH" 2>/dev/null || true
    /bin/rm -rf "$RUNTIME_DIR" 2>/dev/null || true

    if [ -e "$OLD_RUNTIME_BACKUP" ]; then
        /bin/mv "$OLD_RUNTIME_BACKUP" "$RUNTIME_DIR" 2>/dev/null || true
    fi

    if [ -e "$OLD_COMMAND_BACKUP" ] || [ -L "$OLD_COMMAND_BACKUP" ]; then
        /bin/mv "$OLD_COMMAND_BACKUP" "$COMMAND_PATH" 2>/dev/null || true
    fi

    fail "Installation failed. The previous installation was restored where possible."
fi

ok "Installed standalone runtime to $RUNTIME_DIR"
ok "Command available at $COMMAND_PATH"

SHELL_NAME="$(/usr/bin/basename "${SHELL:-/bin/zsh}")"

case "$SHELL_NAME" in
    zsh)
        PROFILE="${HOME}/.zprofile"
        ;;
    bash)
        PROFILE="${HOME}/.bash_profile"
        ;;
    *)
        PROFILE="${HOME}/.profile"
        ;;
esac

PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

if [ ! -f "$PROFILE" ] || ! /usr/bin/grep -Fqx "$PATH_LINE" "$PROFILE" 2>/dev/null; then
    {
        printf '\n# Esattosoft AI Agent\n'
        printf '%s\n' "$PATH_LINE"
    } >> "$PROFILE"

    ok "Added ~/.local/bin to PATH in $PROFILE"
    warn "Open a new Terminal window before using 'esattosoft-ai' by name."
else
    ok "~/.local/bin is already configured in $PROFILE"
fi

printf '\n'
ok "Esattosoft AI Agent v${VERSION} installed."

if command -v ollama >/dev/null 2>&1; then
    ok "Ollama detected."
    printf '\nRecommended lightweight model:\n'
    printf '  ollama pull qwen3.5:4b\n'
else
    warn "Ollama was not detected in PATH."
    printf 'Install Ollama, then pull a model before using the agent:\n'
    printf '  https://ollama.com\n'
    printf '  ollama pull qwen3.5:4b\n'
fi

printf '\nStart Esattosoft AI Agent:\n'
printf '  esattosoft-ai\n'
printf '\nWebsite: https://www.esattosoft.com\n'
