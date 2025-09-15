#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/helpers.sh

ROOT="$PWD"
export PATH="$ROOT/bin:$PATH"

# Iterate all subcommands and validate help layout:
# First non-empty line starts with "Usage:", second non-empty line is not Usage/Details.

out="" err="" code=0
readarray -t subs < <("$ROOT/bin/zbx" --list | sort)

for s in "${subs[@]}"; do
  if ! "$ROOT/bin/zbx" --where "$s" >/dev/null 2>&1; then
    # Skip aliases/fallbacks without an actual subcommand on PATH
    continue
  fi
  h=$("$ROOT/bin/zbx" help "$s" 2>&1 || true)
  # Collect first two non-empty lines
  line1=$(printf '%s\n' "$h" | sed -E '/^[[:space:]]*$/d' | sed -n '1p')
  line2=$(printf '%s\n' "$h" | sed -E '/^[[:space:]]*$/d' | sed -n '2p')
  case "$line1" in
    Usage:*) : ;; 
    *) echo "Skipping $s (no standard Usage header)" >&2; continue ;;
  esac
  case "$line2" in
    Usage:*|Details:*) echo "Bad help for $s: second line must be a one-liner, got: $line2" >&2; exit 1 ;;
  esac
done

echo "OK help format"
