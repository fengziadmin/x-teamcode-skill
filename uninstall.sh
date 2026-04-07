#!/usr/bin/env bash
set -e

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
MARKETPLACE_DIR="$CLAUDE_DIR/plugins/marketplaces/x-teamcode-skill"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

info()  { echo -e "${GREEN}[x-teamcode]${NC} $1"; }

info "Uninstalling x-teamcode skill..."

# Remove from settings.json
if [ -f "$SETTINGS_FILE" ]; then
  python3 << 'PYTHON_SCRIPT'
import json, os

settings_file = os.path.expanduser("~/.claude/settings.json")

with open(settings_file, "r") as f:
    settings = json.load(f)

changed = False

if "enabledPlugins" in settings and "x-teamcode@x-teamcode-skill" in settings["enabledPlugins"]:
    del settings["enabledPlugins"]["x-teamcode@x-teamcode-skill"]
    changed = True
    print("[x-teamcode] Removed from enabledPlugins.")

if "extraKnownMarketplaces" in settings and "x-teamcode-skill" in settings["extraKnownMarketplaces"]:
    del settings["extraKnownMarketplaces"]["x-teamcode-skill"]
    changed = True
    print("[x-teamcode] Removed from extraKnownMarketplaces.")

if changed:
    with open(settings_file, "w") as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)
        f.write("\n")
else:
    print("[x-teamcode] Not found in settings.")

PYTHON_SCRIPT
fi

# Remove marketplace directory/symlink
if [ -e "$MARKETPLACE_DIR" ]; then
  rm -rf "$MARKETPLACE_DIR"
  info "Removed marketplace directory."
fi

echo ""
info "Uninstall complete. Restart Claude Code to take effect."
