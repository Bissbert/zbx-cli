#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"

pass=0 fail=0

for t in tests/test_*.sh; do
  printf 'RUN %s\n' "$t"
  if bash "$t"; then
    printf 'PASS %s\n\n' "$t"
    pass=$((pass+1))
  else
    code=$?
    printf 'FAIL %s (exit %s)\n\n' "$t" "$code"
    fail=$((fail+1))
  fi
done

printf 'Summary: %s passed, %s failed\n' "$pass" "$fail"
exit $([ "$fail" -eq 0 ] && echo 0 || echo 1)

