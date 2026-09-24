#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"

pass=0 fail=0 skip=0

for t in tests/test_*.sh; do
  # Integration tests need a live Zabbix API; skip them unless one is set.
  case "$t" in
    tests/test_integration_*)
      if [ -z "${ZABBIX_URL:-}" ]; then
        printf 'SKIP %s (ZABBIX_URL not set)\n\n' "$t"
        skip=$((skip+1))
        continue
      fi ;;
  esac
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

printf 'Summary: %s passed, %s failed, %s skipped\n' "$pass" "$fail" "$skip"
exit $([ "$fail" -eq 0 ] && echo 0 || echo 1)

