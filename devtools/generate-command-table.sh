#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

group_for() {
  case "$1" in
    login|ping|version|doctor) printf '%s' 'Auth & health' ;;
    host-*|hosts-list) printf '%s' 'Hosts' ;;
    template-*) printf '%s' 'Templates' ;;
    macro-*) printf '%s' 'Macros' ;;
    ack|problems|trigger-*|triggers) printf '%s' 'Problems & triggers' ;;
    maint-*) printf '%s' 'Maintenance' ;;
    item-*|history|trends) printf '%s' 'Items, history & trends' ;;
    discovery|inventory) printf '%s' 'Discovery & inventory' ;;
    search) printf '%s' 'Search' ;;
    config) printf '%s' 'Configuration' ;;
    call) printf '%s' 'Low-level' ;;
    *) printf '%s' 'Other' ;;
  esac
}

one_line_description() {
  awk '
    /^Usage:/ { seen_usage=1; next }
    !seen_usage || /^[[:space:]]*$/ || /^Details:/ { next }
    /^[[:space:]]+(Options|Entities|Notes|Examples|Subcommands):/ { exit }
    { sub(/^[[:space:]]+/, ""); print; exit }
  ' "$1"
}

escape_cell() {
  printf '%s' "$1" | sed 's/|/\\|/g'
}

printf '%s\n\n' '# Command surface'
printf '%s\n\n' '[← back to the overview](../README.md)'
printf '%s\n\n' 'This table is generated from the `Usage:` and description blocks in `bin/zbx-*` source files by [`devtools/generate-command-table.sh`](../devtools/generate-command-table.sh).'
printf '%s\n' '| Group | Command | Source | Usage | Description |'
printf '%s\n' '|---|---|---|---|---|'

for source in "$ROOT_DIR"/bin/zbx-*; do
  [ -f "$source" ] || continue
  base="${source##*/}"
  command="${base#zbx-}"
  [ "$command" = 'lib' ] && continue
  usage="$(awk '/^Usage:/ {sub(/^Usage: /, ""); print; exit}' "$source")"
  description="$(one_line_description "$source")"
  group="$(group_for "$command")"
  printf '| %s | `%s` | [`%s`](../bin/%s) | `%s` | %s |\n' \
    "$(escape_cell "$group")" \
    "$command" \
    "$base" \
    "$base" \
    "$(escape_cell "$usage")" \
    "$(escape_cell "$description")"
done
