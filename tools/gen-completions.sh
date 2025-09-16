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
declare -A choices_map

for s in "${subs[@]}"; do
  help_out=$(PATH="$ROOT_DIR/bin:$PATH" zbx help "$s" 2>/dev/null || true)
  # Extract lines from Options: block if present
  block=$(awk '/^Options:/{flag=1;next} /^Notes:|^Entities:|^Details:/{if(flag==1) exit} flag{print}' <<<"$help_out" || true)
  tokens=()
  specs=()
  choices_specs=()
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
        # Record choices for bash completion
        if [[ "$t" == --* ]] && [ -n "$choices" ]; then
          choices_specs+=("$t:$choices")
        fi
      done
    done <<<"$block"
  fi
  # Always add --help
  tokens+=(--help)
  # Store as space-joined
  opts_map["$s"]="${tokens[*]}"
  choices_map["$s"]="${choices_specs[*]:-}"
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

  # Caches for dynamic value completion (persist across invocations)
  __zbx_get_hosts() {
    if [[ -z "${__zbx_hosts_cache-}" ]]; then
      __zbx_hosts_cache=$(zbx hosts-list 2>/dev/null | awk -F$'\t' '{print $2}' | tr '\n' ' ')
    fi
    printf '%s' "$__zbx_hosts_cache"
  }
  __zbx_get_templates() {
    if [[ -z "${__zbx_templates_cache-}" ]]; then
      __zbx_templates_cache=$(zbx template-list 2>/dev/null | awk -F$'\t' '{print $2}' | tr '\n' ' ')
    fi
    printf '%s' "$__zbx_templates_cache"
  }

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
  # Global option value completions
  if [[ "$prev" == "--cacert" ]]; then
    COMPREPLY=( $(compgen -f -- "$cur") )
    return
  fi
  if [[ "$prev" == "--capath" ]]; then
    COMPREPLY=( $(compgen -d -- "$cur") )
    return
  fi
  # Common format value completion
  if [[ "$prev" == "--format" ]]; then
    COMPREPLY=( $(compgen -W "tsv csv json" -- "$cur") )
    return
  fi
  case "$sub" in
    search)
      # entity at position 2
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=( $(compgen -W "hosts hostgroups templates items triggers problems macros" -- "$cur") )
        return
      fi
      # entity provided: suggest entity-specific options and value completions
      ent="${words[2]:-}"
      # Complete hostnames after --host for relevant entities
      if [[ "$prev" == "--host" ]]; then
        # Complete hosts from cache
        local _hosts
        _hosts=$(__zbx_get_hosts)
        COMPREPLY=( $(compgen -W "$_hosts" -- "$cur") )
        return
      fi
      # Complete --format option values
      if [[ "$prev" == "--format" ]]; then
        COMPREPLY=( $(compgen -W "tsv csv json" -- "$cur") )
        return
      fi
      # Offer entity-specific option words
      case "$ent" in
        items)
          COMPREPLY=( $(compgen -W "--host --key --like --regex --limit --format --headers --json $globals" -- "$cur") )
          return ;;
        triggers|macros)
          COMPREPLY=( $(compgen -W "--host --like --regex --limit --format --headers --json $globals" -- "$cur") )
          return ;;
        hosts|hostgroups|templates|problems)
          COMPREPLY=( $(compgen -W "--like --regex --limit --format --headers --json $globals" -- "$cur") )
          return ;;
      esac
      ;;
    host-get|host-del|host-enable|host-disable|discovery|macro-get|macro-del|macro-set|item-find|triggers|maint-create)
      # Complete host argument at position 2
      if [[ $cword -eq 2 ]]; then
        local _hosts
        _hosts=$(__zbx_get_hosts)
        COMPREPLY=( $(compgen -W "$_hosts" -- "$cur") )
        return
      fi
      ;;
    template-link|template-unlink)
      # host at pos 2, template name at pos 3
      if [[ $cword -eq 2 ]]; then
        local _hosts
        _hosts=$(__zbx_get_hosts)
        COMPREPLY=( $(compgen -W "$_hosts" -- "$cur") )
        return
      elif [[ $cword -eq 3 ]]; then
        local _tpls
        _tpls=$(__zbx_get_templates)
        COMPREPLY=( $(compgen -W "$_tpls" -- "$cur") )
        return
      fi
      ;;
HB
  for s in "${subs[@]}"; do
    [ "$s" = "search" ] && continue
    opts=${opts_map[$s]:-}
    # Subcommand option value completions (choices)
    ch_line=${choices_map[$s]:-}
    if [ -n "$ch_line" ]; then
      printf '    if [[ "$sub" == "%s" ]]; then\n' "$s"
      printf '      case "$prev" in\n'
      IFS=$'\n' read -r -d '' -a ch_arr < <(printf '%s\n' "$ch_line" && printf '\0')
      for spec in "${ch_arr[@]}"; do
        opt="${spec%%:*}"; vals="${spec#*:}"
        printf '        %s) COMPREPLY=( $(compgen -W "%s" -- "$cur") ) ; return ;;\n' "$opt" "$vals"
      done
      printf '      esac\n'
      printf '    fi\n'
    fi
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
