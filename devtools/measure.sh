#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

command_files=()
for source in "$ROOT_DIR"/bin/zbx-*; do
  [ -f "$source" ] || continue
  [ "${source##*/}" = 'zbx-lib' ] && continue
  command_files+=("$source")
done

sum_bytes() {
  wc -c "$@" | awk 'END { print $1 }'
}

sum_lines() {
  wc -l "$@" | awk 'END { print $1 }'
}

printf 'command_files=%s\n' "${#command_files[@]}"
printf 'command_bytes=%s\n' "$(sum_bytes "${command_files[@]}")"
printf 'command_lines=%s\n' "$(sum_lines "${command_files[@]}")"
printf 'bin_bytes=%s\n' "$(sum_bytes "$ROOT_DIR"/bin/*)"
printf 'bin_lines=%s\n' "$(sum_lines "$ROOT_DIR"/bin/*)"
printf 'test_files=%s\n' "$(find "$ROOT_DIR/tests" -maxdepth 1 -type f -name 'test_*.sh' | wc -l | tr -d ' ')"
printf 'readme_bytes=%s\n' "$(wc -c < "$ROOT_DIR/README.md" | tr -d ' ')"
printf 'readme_lines=%s\n' "$(wc -l < "$ROOT_DIR/README.md" | tr -d ' ')"
