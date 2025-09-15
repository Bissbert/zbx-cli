#!/usr/bin/env bash
set -euo pipefail

# Generates Bash completions into ./completions/
# Heuristics:
# - Subcommands from `zbx --list`
# - Options parsed from `zbx help <sub>` lines under an "Options:" section
# - Globals always offered: --insecure --cacert --capath
# - search entities completed: hosts hostgroups templates items triggers problems macros

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUT_DIR="$ROOT_DIR/completions"
mkdir -p "$OUT_DIR"

globals=(--insecure --cacert --capath)
readarray -t subs < <(PATH="$ROOT_DIR/bin:$PATH" zbx --list | sort)

declare -A opts_map

for s in "${subs[@]}"; do
  help_out=$(PATH="$ROOT_DIR/bin:$PATH" zbx help "$s" 2>/dev/null || true)
  # Extract lines from Options: block if present
  block=$(awk '/^Options:/{flag=1;next} /^Notes:|^Entities:|^Details:/{if(flag==1) exit} flag{print}' <<<"$help_out" || true)
  tokens=()
  specs=()
  if [ -n "$block" ]; then
    # Per-line parsing to create zsh _arguments specs
    while IFS= read -r line; do
      [ -z "${line// /}" ] && continue
      # Collect option tokens from the line (both short and long)
      read -r -a line_tokens <<<"$(awk '{ for (i=1;i<=NF;i++) if ($i ~ /^-{1,2}[A-Za-z0-9_-]+,?$/) printf("%s ", $i) }' <<<"$line")"
      # Description: everything after options on the line; escape [] and : for zsh
      desc=$(sed -E 's/^\s*-{1,2}[A-Za-z0-9_-]+(,\s*-{1,2}[A-Za-z0-9_-]+)*\s*//; s/\s+$//' <<<"$line" | sed -E 's/[][()]/ /g; s/:/\\:/g')
      # Detect argument placeholder (uppercase token) or explicit choices in {...}
      arg_name=$(grep -oE ' [A-Z][A-Z0-9_]*' <<<"$line" | head -n1 | tr -d ' ' || true)
      choices_raw=$(grep -oE '\{[^}]+\}' <<<"$line" | head -n1 || true)
      choices=""
      if [ -n "$choices_raw" ]; then
        choices=$(sed -E 's/[{}]//g; s/[|,]/ /g' <<<"$choices_raw")
      fi
      for t in "${line_tokens[@]:-}"; do
        t="${t%,}"
        [[ "$t" = -* ]] || continue
        # Collect token list (for bash minimal)
        case " ${tokens[*]} " in *" $t "*) :;; *) tokens+=("$t");; esac
        # Build zsh _arguments spec, e.g.: --format[desc]:format:(tsv csv json)
        spec="$t[$desc]"
        if [ -n "$choices" ]; then
          spec+="}:${arg_name:-value}:($choices)"
        elif [ -n "$arg_name" ]; then
          spec+="}:${arg_name}"
        fi
        specs+=("$spec")
      done
    done <<<"$block"
  fi
  # Always add --help
  tokens+=(--help)
  # Store as space-joined
  opts_map["$s"]="${tokens[*]}"
done

# Bash completion
{
  printf '%s\n' "# bash completion for zbx (auto-generated)"
  cat <<'HB'
_zbx()
{
  local cur prev words cword
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  words=("${COMP_WORDS[@]}")
  cword=${COMP_CWORD}

HB
  printf '  local globals="%s"\n' "${globals[*]}"
  cat <<'HB'
  # Complete subcommand at position 1
  if [[ $cword -eq 1 ]]; then
HB
  printf '    local subs="%s"\n' "${subs[*]}"
  cat <<'HB'
    COMPREPLY=( $(compgen -W "$globals $subs" -- "$cur") )
    return
  fi

  local sub="${words[1]}"
  case "$sub" in
    search)
      # entity at position 2
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=( $(compgen -W "hosts hostgroups templates items triggers problems macros" -- "$cur") )
        return
      fi
      ;;
HB
  for s in "${subs[@]}"; do
    [ "$s" = "search" ] && continue
    opts=${opts_map[$s]:-}
    printf '    %s) COMPREPLY=( $(compgen -W "$globals %s" -- "$cur") ) ;;\n' "$s" "$opts"
  done
  cat <<'HB'
    *) COMPREPLY=( $(compgen -W "$globals" -- "$cur") ) ;;
  esac
}

complete -F _zbx zbx
HB
} >"$OUT_DIR/zbx.bash"

echo "Generated: $OUT_DIR/zbx.bash"
