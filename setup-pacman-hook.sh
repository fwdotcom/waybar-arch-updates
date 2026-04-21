#!/usr/bin/env bash
# Install the pacman hook that refreshes the Waybar arch-updates module
# after every successful pacman transaction.
#
# Usage: sudo ./setup-pacman-hook.sh

set -eo pipefail

HOOK_DIR=/etc/pacman.d/hooks
HOOK_FILE=$HOOK_DIR/95-waybar-arch-updates.hook

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo $0" >&2
    exit 1
fi

mkdir -p "$HOOK_DIR"

cat > "$HOOK_FILE" <<'EOF'
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
EOF

echo "Hook installed: $HOOK_FILE"
