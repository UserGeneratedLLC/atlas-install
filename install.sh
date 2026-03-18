#!/usr/bin/env bash
set -euo pipefail

# ── Atlas Installer ──────────────────────────────────────────────────────────
# One-line install:
#   curl -fsSL https://raw.githubusercontent.com/UserGeneratedLLC/atlas-install/main/install.sh | bash
#
# Requires access to the @usergeneratedllc GitHub Packages registry.
# ─────────────────────────────────────────────────────────────────────────────

SCOPE="@usergeneratedllc"
REGISTRY="https://npm.pkg.github.com"
PAT_URL="https://github.com/settings/tokens/new?scopes=read:packages&description=atlas-read-packages"
MIN_NODE_MAJOR=18

# ── Colors ───────────────────────────────────────────────────────────────────

if [ -t 1 ]; then
  BOLD="\033[1m"
  GREEN="\033[32m"
  YELLOW="\033[33m"
  RED="\033[31m"
  CYAN="\033[36m"
  RESET="\033[0m"
else
  BOLD="" GREEN="" YELLOW="" RED="" CYAN="" RESET=""
fi

info()  { printf "${BOLD}${CYAN}[atlas]${RESET} %s\n" "$*"; }
ok()    { printf "${BOLD}${GREEN}[atlas]${RESET} %s\n" "$*"; }
warn()  { printf "${BOLD}${YELLOW}[atlas]${RESET} %s\n" "$*"; }
err()   { printf "${BOLD}${RED}[atlas]${RESET} %s\n" "$*" >&2; }
fatal() { err "$@"; exit 1; }

# ── Detect OS & package manager ─────────────────────────────────────────────

detect_os() {
  OS="$(uname -s)"
  case "$OS" in
    Darwin) PLATFORM="macos" ;;
    Linux)  PLATFORM="linux" ;;
    *)      fatal "Unsupported OS: $OS" ;;
  esac
}

detect_pkg_manager() {
  if [ "$PLATFORM" = "macos" ]; then
    PKG_MANAGER="brew"
    return
  fi

  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="${ID:-unknown}"
  else
    DISTRO="unknown"
  fi

  if command -v apt-get >/dev/null 2>&1; then
    PKG_MANAGER="apt"
  elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
  elif command -v yum >/dev/null 2>&1; then
    PKG_MANAGER="yum"
  elif command -v pacman >/dev/null 2>&1; then
    PKG_MANAGER="pacman"
  elif command -v apk >/dev/null 2>&1; then
    PKG_MANAGER="apk"
  elif command -v zypper >/dev/null 2>&1; then
    PKG_MANAGER="zypper"
  else
    fatal "Could not detect a supported package manager. Install git and Node.js >= $MIN_NODE_MAJOR manually, then re-run this script."
  fi
}

# ── Package install helpers ──────────────────────────────────────────────────

pkg_install() {
  local pkg="$1"
  case "$PKG_MANAGER" in
    brew)    brew install "$pkg" ;;
    apt)     sudo apt-get update -qq && sudo apt-get install -y -qq "$pkg" ;;
    dnf)     sudo dnf install -y "$pkg" ;;
    yum)     sudo yum install -y "$pkg" ;;
    pacman)  sudo pacman -Sy --noconfirm "$pkg" ;;
    apk)     sudo apk add --no-cache "$pkg" ;;
    zypper)  sudo zypper install -y "$pkg" ;;
  esac
}

# ── Homebrew (macOS only) ────────────────────────────────────────────────────

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi
  info "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add brew to PATH for Apple Silicon
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  command -v brew >/dev/null 2>&1 || fatal "Homebrew installation failed."
  ok "Homebrew installed."
}

# ── Git ──────────────────────────────────────────────────────────────────────

ensure_git() {
  if command -v git >/dev/null 2>&1; then
    ok "git already installed ($(git --version | head -1))."
    return
  fi
  info "Installing git..."
  pkg_install git
  command -v git >/dev/null 2>&1 || fatal "git installation failed."
  ok "git installed."
}

# ── Node.js / npm ───────────────────────────────────────────────────────────

node_version_ok() {
  if ! command -v node >/dev/null 2>&1; then
    return 1
  fi
  local ver
  ver="$(node -v 2>/dev/null | sed 's/^v//')"
  local major="${ver%%.*}"
  [ "$major" -ge "$MIN_NODE_MAJOR" ] 2>/dev/null
}

ensure_node() {
  if node_version_ok; then
    ok "Node.js already installed ($(node -v))."
    return
  fi

  if command -v node >/dev/null 2>&1; then
    warn "Node.js $(node -v) is too old (need >= $MIN_NODE_MAJOR). Upgrading..."
  else
    info "Installing Node.js..."
  fi

  case "$PKG_MANAGER" in
    brew)
      brew install node
      ;;
    apt)
      info "Using NodeSource LTS for a current Node.js version..."
      curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
      sudo apt-get install -y -qq nodejs
      ;;
    dnf|yum)
      curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo -E bash -
      sudo "$PKG_MANAGER" install -y nodejs
      ;;
    pacman)
      sudo pacman -Sy --noconfirm nodejs npm
      ;;
    apk)
      sudo apk add --no-cache nodejs npm
      ;;
    zypper)
      sudo zypper install -y nodejs npm
      ;;
  esac

  node_version_ok || fatal "Node.js installation failed or version is still below $MIN_NODE_MAJOR."
  ok "Node.js installed ($(node -v))."
}

# ── npm registry auth ───────────────────────────────────────────────────────

npmrc_has_registry() {
  local npmrc="${HOME}/.npmrc"
  [ -f "$npmrc" ] && grep -q "${SCOPE}:registry" "$npmrc" 2>/dev/null
}

npmrc_has_token() {
  local npmrc="${HOME}/.npmrc"
  [ -f "$npmrc" ] && grep -q "//npm.pkg.github.com/:_authToken" "$npmrc" 2>/dev/null
}

open_browser() {
  local url="$1"
  if [ "$PLATFORM" = "macos" ]; then
    open "$url" 2>/dev/null || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" 2>/dev/null || true
  elif command -v wslview >/dev/null 2>&1; then
    wslview "$url" 2>/dev/null || true
  else
    warn "Could not open browser automatically."
  fi
}

ensure_npm_auth() {
  if npmrc_has_registry && npmrc_has_token; then
    ok "npm registry auth already configured."
    return
  fi

  echo ""
  info "Atlas is distributed via GitHub Packages. A GitHub Personal Access Token"
  info "with the read:packages scope is required."
  echo ""
  info "Opening your browser to create a token..."
  info "  1. Make sure 'read:packages' is checked"
  info "  2. Click 'Generate token'"
  info "  3. Copy the token and paste it below"
  echo ""

  open_browser "$PAT_URL"

  printf "${BOLD}${CYAN}[atlas]${RESET} Paste your GitHub token (input is hidden): "
  local token=""

  # When piped from curl, stdin is the script itself -- reattach to the terminal
  if [ -t 0 ]; then
    read -rs token
  elif [ -e /dev/tty ]; then
    read -rs token < /dev/tty
  else
    fatal "Cannot read token: no terminal available. Run the script directly (not piped) or set up auth manually."
  fi
  echo ""

  [ -n "$token" ] || fatal "No token provided. Aborting."

  npm config set "${SCOPE}:registry" "$REGISTRY"
  npm config set "//npm.pkg.github.com/:_authToken" "$token"

  ok "npm registry auth configured."
}

# ── Install Atlas ────────────────────────────────────────────────────────────

ensure_atlas() {
  info "Installing Atlas..."
  npm install -g "${SCOPE}/atlas"

  if command -v atlas >/dev/null 2>&1; then
    ok "Atlas installed ($(atlas --version 2>/dev/null || echo 'unknown version'))."
  else
    local bindir
    bindir="$(npm config get prefix)/bin"
    warn "Atlas installed but 'atlas' is not on your PATH."
    warn "Add this to your shell profile:"
    warn "  export PATH=\"$bindir:\$PATH\""
    echo ""
  fi
}

run_atlas_install() {
  if ! command -v atlas >/dev/null 2>&1; then
    warn "Skipping plugin/extension install (atlas not on PATH)."
    return
  fi
  info "Installing Roblox Studio plugin and Cursor/VS Code extension..."
  atlas install || warn "atlas install had issues -- you can retry with: atlas install"
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo ""
  printf "${BOLD}  Atlas Installer${RESET}\n"
  echo ""

  detect_os

  if [ "$PLATFORM" = "macos" ]; then
    ensure_brew
  fi
  detect_pkg_manager

  ensure_git
  ensure_node
  ensure_npm_auth
  ensure_atlas
  run_atlas_install

  echo ""
  ok "Done! Atlas is ready to use."
  echo ""
  info "Get started:"
  info "  atlas clone PLACEID    Clone an existing Roblox place"
  info "  atlas init             Create a new project"
  info "  atlas serve            Start live sync to Studio"
  info "  atlas studio           Open the project in Roblox Studio"
  info "  atlas cursor           Open the project in Cursor"
  echo ""
}

main "$@"
