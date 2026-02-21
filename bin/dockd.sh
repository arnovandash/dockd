#!/usr/bin/bash
# dockd — Steam Deck dock mode switcher
#
# Watches AC power state and automatically switches between:
#   - Server mode (Desktop/Plasma) when charger is plugged in
#   - Gaming mode (Gamescope) when charger is unplugged
#
# Sleep detection via logind D-Bus prevents mode switches from
# firing during suspend/resume cycles.
#
# Modules: drop scripts into ~/.config/dockd/modules/ that accept
# "start" and "stop" arguments. They run in filename order on
# server start, and in reverse order on gaming start.
#
# Toggle:  run `dockd-toggle` to enable/disable auto-switching
# Log:     ~/.local/share/dockd.log

MODULES_DIR="$HOME/.config/dockd/modules"
STATE_DIR="$HOME/.config/dockd"
LOG="$HOME/.local/share/dockd.log"
SUSPENDED_FLAG="$STATE_DIR/.suspended"
ENABLED_FLAG="$STATE_DIR/.enabled"

# Auto-detect AC adapter power file (works across Deck models)
POWER_FILE=$(
    for f in /sys/class/power_supply/*/online; do
        type=$(cat "$(dirname "$f")/type" 2>/dev/null)
        [ "$type" = "Mains" ] && echo "$f" && break
    done
)

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

is_enabled()   { [ -f "$ENABLED_FLAG" ]; }
is_suspended() { [ -f "$SUSPENDED_FLAG" ]; }
get_power()    { cat "$POWER_FILE" 2>/dev/null; }

get_mode() {
    if systemctl --user is-active gamescope-session.service &>/dev/null; then
        echo "gaming"
    else
        echo "desktop"
    fi
}

run_modules() {
    local action="$1"
    local modules=("$MODULES_DIR"/*.sh)
    [ ! -f "${modules[0]}" ] && return

    if [ "$action" = "stop" ]; then
        # Run in reverse order on stop so dependencies unwind correctly
        for (( i=${#modules[@]}-1; i>=0; i-- )); do
            log "Module [stop]: ${modules[$i]}"
            bash "${modules[$i]}" stop 2>&1 | tee -a "$LOG" || true
        done
    else
        for module in "${modules[@]}"; do
            log "Module [start]: $module"
            bash "$module" start 2>&1 | tee -a "$LOG" || true
        done
    fi
}

switch_to_server() {
    if ! is_enabled;  then log "dockd disabled — skipping switch to server"; return; fi
    if is_suspended;  then log "Suspended — skipping switch to server"; return; fi
    if [ "$(get_mode)" = "desktop" ]; then
        log "Already in desktop mode — running modules"
        run_modules start
        return
    fi
    log "Switching → server (Desktop) mode"
    run_modules stop
    steamos-session-select plasma
}

switch_to_gaming() {
    if ! is_enabled;  then log "dockd disabled — skipping switch to gaming"; return; fi
    if is_suspended;  then log "Suspended — skipping switch to gaming"; return; fi
    if [ "$(get_mode)" = "gaming" ]; then
        log "Already in gaming mode — skipping"
        return
    fi
    log "Switching → gaming (Gamescope) mode"
    run_modules stop
    steamos-session-select gamescope
}

# Listens for logind PrepareForSleep signals over D-Bus.
# Sets a flag before suspend and clears it after resume (with a
# short grace period) so AC poll events don't fire mid-transition.
monitor_sleep() {
    gdbus monitor --system \
        --dest org.freedesktop.login1 \
        --object-path /org/freedesktop/login1 2>/dev/null \
    | grep --line-buffered "PrepareForSleep" \
    | while read -r line; do
        if echo "$line" | grep -q "true"; then
            log "Suspending — blocking mode switches"
            touch "$SUSPENDED_FLAG"
        else
            log "Resumed — unblocking in 15s"
            (sleep 15 && rm -f "$SUSPENDED_FLAG" && log "Suspend block cleared") &
        fi
    done
}

# Polls AC power state every 3 seconds.
# UPower D-Bus emits no events on SteamOS, so polling is required.
monitor_power() {
    local prev curr
    prev=$(get_power)
    while true; do
        sleep 3
        curr=$(get_power)
        if [ "$curr" != "$prev" ]; then
            if [ "$curr" = "1" ]; then
                log "AC connected"
                switch_to_server
            else
                log "AC disconnected"
                switch_to_gaming
            fi
            prev=$curr
        fi
    done
}

mkdir -p "$STATE_DIR" "$MODULES_DIR"
[ ! -f "$ENABLED_FLAG" ] && touch "$ENABLED_FLAG"

# Brief settle delay on start to avoid false triggers on resume
sleep 10

log "Started — mode=$(get_mode), enabled=$(is_enabled && echo yes || echo no), ac=$(get_power)"

monitor_sleep &
monitor_power
