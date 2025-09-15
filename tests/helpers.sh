#!/usr/bin/env bash
set -euo pipefail

assert_eq() {
  local exp="$1" got="$2" msg="${3:-}"
  if [ "$exp" != "$got" ]; then
    printf 'ASSERT_EQ failed: %s\n  expected: %s\n  got:      %s\n' "${msg:-}" "$exp" "$got" >&2
    return 1
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" msg="${3:-}"
  if ! grep -qF -- "$needle" <<<"$haystack"; then
    printf 'ASSERT_CONTAINS failed: %s\n  needle: %s\n  haystack:\n%s\n' "${msg:-}" "$needle" "$haystack" >&2
    return 1
  fi
}

run_cmd() {
  # Usage: run_cmd <outvar> <errvar> <exitvar> cmd args...
  local __out="$1" __err="$2" __code="$3"; shift 3
  local out_f err_f status
  out_f=$(mktemp); err_f=$(mktemp)
  if "$@" >"$out_f" 2>"$err_f"; then status=0; else status=$?; fi
  printf -v "$__out" '%s' "$(cat "$out_f")"
  printf -v "$__err" '%s' "$(cat "$err_f")"
  printf -v "$__code" '%s' "$status"
  rm -f "$out_f" "$err_f"
}
