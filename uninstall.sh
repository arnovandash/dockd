#!/usr/bin/bash
# dockd uninstaller

set -e

BIN="$HOME/.local/bin"
SYSTEMD="$HOME/.config/systemd/user"
AUTOSTART="$HOME/.config/autostart"
STATE="$HOME/.config/dockd"

GREEN='\033[0;32m'; NC='\033[0m'
ok() { echo -e "${GREEN}✓${NC} $*"; }

echo ""
echo "  dockd uninstaller"
echo ""

# Stop and disable service
systemctl --user stop dockd.service 2>/dev/null   && ok "Service stopped"   || true
systemctl --user disable dockd.service 2>/dev/null && ok "Service disabled"  || true
rm -f "$SYSTEMD/dockd.service"
systemctl --user daemon-reload
ok "Service removed"

# Remove scripts
rm -f "$BIN/dockd.sh" "$BIN/dockd-toggle"
ok "Scripts removed"

# Remove autostart
rm -f "$AUTOSTART/dockd-init.sh" "$AUTOSTART/dockd-init.desktop"
ok "Autostart removed"

# Remove state and modules
# When piped via curl, stdin is not a terminal — remove automatically
if [ -t 0 ]; then
    read -rp "Remove ~/.config/dockd/ (includes modules)? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] && rm -rf "$STATE" && ok "State and modules removed" \
        || ok "Kept ~/.config/dockd/ — remove manually if needed"
else
    rm -rf "$STATE"
    ok "State and modules removed"
fi

# Disable linger
sudo loginctl disable-linger "$(whoami)"
ok "Linger disabled"

# Restore power button default (sleep on press)
kwriteconfig6 --file powermanagementprofilesrc \
    --group 'AC' --group 'HandleButtonEvents' \
    --key 'powerButtonAction' 64 2>/dev/null || true
ok "Power button restored"

echo ""
echo "  dockd uninstalled."
echo ""
