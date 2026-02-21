# dockd

Automatic dock mode switcher for the Steam Deck.

- **Charger plugged in** → switches to Desktop Mode and starts server services
- **Charger unplugged** → switches back to Gaming Mode

Sleep detection prevents mode switches from firing during suspend/resume cycles — put the Deck to sleep before plugging or unplugging to stay in your current mode.

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/arnovandash/dockd/main/install.sh | bash
```

---

## Usage

| Action | Result |
|--------|--------|
| Plug in charger (while awake) | → Desktop Mode |
| Unplug charger (while awake) | → Gaming Mode |
| Sleep, then plug/unplug | → no switch |
| `dockd-toggle` | Enable / disable auto-switching |

**Screen** automatically turns off after 2 minutes when idle in Desktop Mode.

---

## Modules

Drop scripts into `~/.config/dockd/modules/` to run services automatically on mode switch. Scripts must accept `start` and `stop` arguments and follow the naming convention `<priority>-<name>.sh` (e.g. `10-openclaw.sh`).

Modules run in filename order when entering server mode, and in reverse order when entering gaming mode.

See `modules/example.sh.disabled` for a template.

After adding a module:
```bash
systemctl --user restart dockd
```

---

## Files

```
~/.local/bin/dockd.sh           main daemon
~/.local/bin/dockd-toggle       enable/disable toggle
~/.config/systemd/user/dockd.service
~/.config/autostart/dockd-init.sh      runs on Plasma session start
~/.config/dockd/modules/               module scripts
~/.config/dockd/.enabled               flag: auto-switch enabled
~/.local/share/dockd.log               log file
```

---

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/arnovandash/dockd/main/uninstall.sh | bash
```

---
