#!/usr/bin/bash
# dockd-init.sh — runs at Plasma (Desktop Mode) session start
#
# Sets a 2-minute screen-off DPMS timer and starts all dockd modules.
# Installed to ~/.config/autostart/ by the dockd installer.

# Wait for the X session to fully settle before issuing DPMS commands
sleep 5

# Set screen-off timer (2 minutes idle → display off, no suspend)
XAUTH=$(cat /proc/$(pgrep -x kwin_x11 | head -1)/environ 2>/dev/null \
    | tr '\0' '\n' | grep XAUTHORITY | cut -d= -f2)
if [ -n "$XAUTH" ]; then
    DISPLAY=:0 XAUTHORITY="$XAUTH" xset dpms 0 0 120
fi

# Start modules (handles the case where the session restarts mid-run)
MODULES_DIR="$HOME/.config/dockd/modules"
if [ -d "$MODULES_DIR" ]; then
    for module in "$MODULES_DIR"/*.sh; do
        [ -f "$module" ] && bash "$module" start
    done
fi
