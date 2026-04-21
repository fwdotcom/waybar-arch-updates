#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# waybar-arch-updates
# https://github.com/fwdotcom/waybar-arch-updates
# Frank Winter — https://www.frankwinter.com
#
# See README.md for usage, configuration and output format.

# Exit immediately on error; propagate pipe failures.
set -eo pipefail

# --- Collect pending updates ---------------------------------------------------
#
# pacman -Qu lists packages for which a newer version is available in the local
# sync DB. It does NOT trigger a network sync — the result reflects the state of
# the last `pacman -Sy` (or equivalent). Stderr is suppressed because pacman
# writes "there is nothing to do" to stderr when the system is up to date.
#
# yay -Qua queries the AUR for out-of-date VCS and regular AUR packages.
# The `command -v` guard skips AUR checks silently when yay is not installed.
#
# Both variables are intentionally left empty (not unset) when there is nothing
# to report, so the subsequent line-count logic can treat them uniformly.
pacman_list=$(pacman -Qu 2>/dev/null || true)
aur_list=$(command -v yay &>/dev/null && timeout 15 yay -Qua 2>/dev/null || true)

# --- Count updates ------------------------------------------------------------
#
# `grep -c .` counts non-empty lines. Passing the string through printf rather
# than using a here-string avoids a trailing newline that would inflate the
# count by one when the list is non-empty. The `|| true` prevents the pipeline
# from aborting via `set -e` when grep finds zero matches (exit code 1).
pacman_count=$(printf '%s' "$pacman_list" | grep -c . || true)
aur_count=$(printf '%s' "$aur_list"    | grep -c . || true)
total=$((pacman_count + aur_count))

# --- JSON escape helper -------------------------------------------------------
#
# Waybar embeds the tooltip value directly inside a JSON string literal, so any
# characters that are special in JSON must be escaped before output:
#   1. Backslashes are doubled first to avoid double-processing in step 2.
#   2. Double quotes are escaped so the JSON string is not terminated early.
#   3. Literal newlines are replaced with the two-character sequence \n using
#      awk, which processes the input line by line and inserts the separator
#      between lines (ORS="" suppresses awk's own newline after each record).
escape() {
    printf '%s' "$1" \
        | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' \
        | awk 'BEGIN{ORS=""} {if(NR>1) print "\\n"; print}'
}

# --- Output -------------------------------------------------------------------
#
# When the system is fully up to date, emit a minimal JSON object and exit.
# The icon 󰣇 (nf-md-arch) serves as a neutral "all good" indicator.
if [ "$total" -eq 0 ]; then
    printf '{"text":"󰣇","tooltip":"System up to date","class":"up-to-date","alt":"up-to-date"}\n'
    exit 0
fi

# Build the tooltip string:
#   Line 1 — summary counts for pacman and AUR.
#   Block 2 — full pacman package list (appended only when non-empty).
#   Block 3 — AUR package list prefixed with a header (appended only when non-empty).
tooltip="Pacman: ${pacman_count} · AUR: ${aur_count}"
[ -n "$pacman_list" ] && tooltip+=$'\n\n'"$pacman_list"
[ -n "$aur_list" ]    && tooltip+=$'\n\nAUR:\n'"$aur_list"

# Emit the final JSON object. The icon 󰏕 (nf-md-package_up) signals pending
# updates. The tooltip is passed through escape() before embedding.
printf '{"text":"󰏕 %d","tooltip":"%s","class":"has-updates","alt":"has-updates"}\n' \
    "$total" "$(escape "$tooltip")"
