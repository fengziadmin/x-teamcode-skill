#!/usr/bin/env bash
set -e

# X-TeamCode Installer
# Usage:
#   Local:  bash install.sh
#   Remote: bash <(curl -fsSL https://raw.githubusercontent.com/fengziadmin/x-teamcode-skill/master/install.sh)

PLUGIN_NAME="x-teamcode"
MARKETPLACE_NAME="x-teamcode-skill"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
MARKETPLACE_DIR="$CLAUDE_DIR/plugins/marketplaces/$MARKETPLACE_NAME"
REPO_URL="https://github.com/fengziadmin/x-teamcode-skill.git"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[x-teamcode]${NC} $1"; }
warn()  { echo -e "${YELLOW}[x-teamcode]${NC} $1"; }
error() { echo -e "${RED}[x-teamcode]${NC} $1"; exit 1; }

# --- Pre-checks ---
command -v git >/dev/null 2>&1 || error "git is not installed."

if [ ! -d "$CLAUDE_DIR" ]; then
  error "Claude Code config directory not found at $CLAUDE_DIR. Is Claude Code installed?"
fi

# --- Step 1: Get plugin files ---
info "Installing x-teamcode skill..."

if [ -f "$(dirname "$0")/.claude-plugin/plugin.json" ] 2>/dev/null; then
  # Running from inside the repo
  SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
  info "Using local source: $SOURCE_DIR"

  if [ -e "$MARKETPLACE_DIR" ]; then
    rm -rf "$MARKETPLACE_DIR"
  fi
  ln -sfn "$SOURCE_DIR" "$MARKETPLACE_DIR"
  info "Symlinked to marketplace directory."
else
  # Running remotely — clone the repo
  info "Cloning from GitHub..."
  if [ -d "$MARKETPLACE_DIR" ]; then
    warn "Existing installation found. Updating..."
    cd "$MARKETPLACE_DIR" && git pull --ff-only 2>/dev/null || {
      warn "Update failed. Re-cloning..."
      rm -rf "$MARKETPLACE_DIR"
      git clone --depth 1 "$REPO_URL" "$MARKETPLACE_DIR"
    }
  else
    git clone --depth 1 "$REPO_URL" "$MARKETPLACE_DIR"
  fi
  info "Downloaded to $MARKETPLACE_DIR"
fi

# --- Step 2: Update settings.json ---
info "Updating Claude Code settings..."

mkdir -p "$CLAUDE_DIR"

if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
fi

# Use python3 to safely merge JSON (available on macOS and most Linux)
python3 << 'PYTHON_SCRIPT'
import json, sys, os

settings_file = os.path.expanduser("~/.claude/settings.json")

with open(settings_file, "r") as f:
    settings = json.load(f)

# Ensure enabledPlugins exists
if "enabledPlugins" not in settings:
    settings["enabledPlugins"] = {}

# Add plugin
plugin_key = "x-teamcode@x-teamcode-skill"
if plugin_key not in settings["enabledPlugins"]:
    settings["enabledPlugins"][plugin_key] = True
    print("[x-teamcode] Added to enabledPlugins.")
else:
    print("[x-teamcode] Already in enabledPlugins.")

# Ensure extraKnownMarketplaces exists
if "extraKnownMarketplaces" not in settings:
    settings["extraKnownMarketplaces"] = {}

# Add marketplace
mp_key = "x-teamcode-skill"
if mp_key not in settings["extraKnownMarketplaces"]:
    marketplace_dir = os.path.expanduser("~/.claude/plugins/marketplaces/x-teamcode-skill")
    # Resolve symlink to get actual path
    real_path = os.path.realpath(marketplace_dir)
    settings["extraKnownMarketplaces"][mp_key] = {
        "source": {
            "source": "git",
            "url": f"file://{real_path}"
        }
    }
    print("[x-teamcode] Added to extraKnownMarketplaces.")
else:
    print("[x-teamcode] Already in extraKnownMarketplaces.")

# Enable experimental agent teams
if "env" not in settings:
    settings["env"] = {}

if settings["env"].get("CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS") != "1":
    settings["env"]["CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"] = "1"
    print("[x-teamcode] Enabled experimental agent teams.")
else:
    print("[x-teamcode] Agent teams already enabled.")

with open(settings_file, "w") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")

PYTHON_SCRIPT

# --- Done ---
echo ""
info "Installation complete!"
echo ""
echo "  Next steps:"
echo "    1. Restart Claude Code (exit and reopen)"
echo "    2. Type /x-teamcode to start"
echo ""
