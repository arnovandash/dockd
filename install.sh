#!/usr/bin/bash
# dockd installer
# Usage: curl -fsSL https://raw.githubusercontent.com/arnovandash/dockd/main/install.sh | bash

set -e

REPO="https://raw.githubusercontent.com/arnovandash/dockd/main"
BIN="$HOME/.local/bin"
SYSTEMD="$HOME/.config/systemd/user"
AUTOSTART="$HOME/.config/autostart"
MODULES="$HOME/.config/dockd/modules"
STATE="$HOME/.config/dockd"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
die()  { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

echo ""
echo "  dockd — Steam Deck dock mode switcher"
echo "  https://github.com/arnovandash/dockd"
echo ""

# Check SteamOS
[ -f /etc/os-release ] && grep -q "SteamOS" /etc/os-release \
    || warn "Not running SteamOS — proceed at your own risk"

# Dependencies
for cmd in gdbus systemctl steamos-session-select kwriteconfig6; do
    command -v "$cmd" &>/dev/null || die "Required command not found: $cmd"
done

# Create directories
mkdir -p "$BIN" "$SYSTEMD" "$AUTOSTART" "$MODULES" "$STATE"
ok "Directories ready"

# Enable linger so user services start at boot without login
echo "Enabling linger (requires sudo)..."
sudo loginctl enable-linger "$(whoami)"
ok "Linger enabled"

# Download scripts
echo "Downloading scripts..."
curl -fsSL "$REPO/bin/dockd.sh"       -o "$BIN/dockd.sh"
curl -fsSL "$REPO/bin/dockd-toggle"   -o "$BIN/dockd-toggle"
curl -fsSL "$REPO/systemd/dockd.service" -o "$SYSTEMD/dockd.service"
curl -fsSL "$REPO/autostart/dockd-init.sh"      -o "$AUTOSTART/dockd-init.sh"
curl -fsSL "$REPO/autostart/dockd-init.desktop" -o "$AUTOSTART/dockd-init.desktop"
curl -fsSL "$REPO/modules/example.sh.disabled"  -o "$MODULES/example.sh.disabled"
chmod +x "$BIN/dockd.sh" "$BIN/dockd-toggle" "$AUTOSTART/dockd-init.sh"
ok "Scripts installed"

# Add ~/.local/bin to PATH if not already there
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [ -f "$rc" ] && echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
    done
    warn "Added ~/.local/bin to PATH — restart your shell or run: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# Configure power button to do nothing (DPMS timer handles screen-off)
kwriteconfig6 --file powermanagementprofilesrc \
    --group 'AC' --group 'HandleButtonEvents' \
    --key 'powerButtonAction' 0
ok "Power button configured"

# Enable and start service
systemctl --user daemon-reload
systemctl --user enable dockd.service
systemctl --user start dockd.service
ok "dockd service enabled and started"

echo ""
echo "  Installation complete."
echo ""
echo "  Plug in charger  → Desktop (server) mode"
echo "  Unplug charger   → Gaming mode"
echo "  dockd-toggle     → enable/disable auto-switching"
echo "  ~/.config/dockd/modules/  → drop module scripts here"
echo ""
