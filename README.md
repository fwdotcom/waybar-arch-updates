# waybar-arch-updates

[![Version](https://img.shields.io/badge/version-1.0-blue.svg)](https://github.com/fwdotcom/waybar-arch-updates/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-4EAA25.svg?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-Arch%20Linux-1793D1.svg?logo=arch-linux&logoColor=white)](https://archlinux.org/)


**Small Waybar module to display pending Arch Linux and optional AUR updates.**

Waybar does not provide a native module for displaying pending package updates. This module fills that gap: it checks official repositories and optionally the AUR at a configurable interval, displays the number of available updates in the bar, and highlights the status visually.

---

## Prerequisites

| Prerequisite | Purpose | Required |
|---|---|---|
| [Waybar](https://github.com/Alexays/Waybar) | Status bar | yes |
| `pacman` | Package manager | yes |
| `yay` | AUR helper | no |
| [Nerd Fonts](https://www.nerdfonts.com/) | Icons (`󰣇`, `󰏕`) | recommended |

---

## File Structure

```
waybar/scripts/waybar-arch-updates/
├── waybar-arch-updates.sh     # Bash script (Waybar exec)
├── waybar-arch-updates.css    # Module-specific styling
├── setup-pacman-hook.sh       # Installs the pacman hook
├── LICENSE
└── README.md
```

---

## Installation

**1. Make the script executable:**

```bash
chmod +x ~/.config/waybar/scripts/waybar-arch-updates/waybar-arch-updates.sh
```

**2. Register the module in `waybar/config.jsonc`:**

```jsonc
"custom/arch-updates": {
    "exec": "~/.config/waybar/scripts/waybar-arch-updates/waybar-arch-updates.sh",
    "return-type": "json",
    "interval": 3600,
    "signal": 8,
    "on-click": "kitty",
    "on-click-right": "pkill -RTMIN+8 waybar",
    "tooltip": true,
    "format": "{}"
}
```

Add the module to the desired module group:

```jsonc
"modules-right": [
    "...",
    "custom/arch-updates"
]
```

**3. Import the CSS in `waybar/style.css`:**

```css
@import "scripts/waybar-arch-updates/waybar-arch-updates.css";
```

---

## Configuration

### Script Behavior

The script queries two package sources:

| Source | Tool | Description |
|---|---|---|
| Official repos | `pacman -Qu` | Checks against the local DB (as of the last `pacman -Sy`) |
| AUR | `yay -Qua` | Optional; skipped if `yay` is not installed |

### JSON Output

Waybar expects the following format when `"return-type": "json"` is set:

```jsonc
// System up to date
{"text":"󰣇","tooltip":"System up to date","class":"up-to-date","alt":"up-to-date"}

// Updates available
{"text":"󰏕 5","tooltip":"Pacman: 3 · AUR: 2\n\npackage-a ...\n\nAUR:\naur-package-b ...","class":"has-updates","alt":"has-updates"}
```

| Field | Description |
|---|---|
| `text` | Text displayed in the bar |
| `tooltip` | Hover text with package list |
| `class` | CSS class: `up-to-date` or `has-updates` |
| `alt` | Mirrors `class` — for icon themes |

### CSS Classes

| Class | Meaning | Default Styling |
|---|---|---|
| `up-to-date` | System is current | none — no visual feedback intended |
| `has-updates` | Updates available | red background (`rgba(255, 0, 0, 0.8)`) |

Styling can be customized in `waybar-arch-updates.css`.

### Manual Refresh

Right-clicking the module sends signal RTMIN+8 to Waybar, triggering an immediate refresh without waiting for the 1-hour interval. Requires `"signal": 8` in the module configuration.

### Auto Refresh After `pacman` Updates (Hook)

To refresh Waybar automatically after a successful `pacman` transaction, add a `PostTransaction` hook:

```bash
sudo ./setup-pacman-hook.sh
```

This installs `/etc/pacman.d/hooks/95-waybar-arch-updates.hook`:

```ini
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Refresh Waybar Arch updates module
When = PostTransaction
Exec = /bin/sh -c 'pkill -RTMIN+8 waybar || true'
```

How it works:

- `When = PostTransaction` runs only after a successful transaction.
- `pkill -RTMIN+8 waybar` triggers the same immediate Waybar refresh as the module right-click action.
- The command is wrapped in `/bin/sh -c '...'` because pacman hooks do not invoke a shell — `||` would otherwise be passed as a literal argument to `pkill`.
- `|| true` prevents the hook from failing when Waybar is not running.

Verify the hook file:

```bash
sudo pacman -Qkk pacman >/dev/null
sudo cat /etc/pacman.d/hooks/95-waybar-arch-updates.hook
```

---

## License

Licensed under [MIT License](LICENSE).

---

*© 2026 Frank Winter | [www.frankwinter.com](https://www.frankwinter.com)*