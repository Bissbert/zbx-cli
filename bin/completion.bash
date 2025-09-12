# Bash completion for zbx (git-style dispatcher)

# Returns space-separated list of zbx subcommands by scanning PATH
_zbx_subcommands() {
  compgen -c | grep -E '^zbx-' | sed 's/^zbx-//' | sort -u
}

# Static option sets
_zbx_search_entities="hosts hostgroups templates items triggers problems macros"
_zbx_search_opts="--host --like --regex --key --limit --json --help -h"
_zbx_config_subs="list get set unset edit path init help -h --help"
_zbx_config_opts_common="--scope"
_zbx_config_scopes="auto project user system"
_zbx_known_vars="ZABBIX_URL ZABBIX_USER ZABBIX_PASS ZABBIX_API_TOKEN ZABBIX_VERIFY_TLS ZABBIX_CURL_TIMEOUT ZABBIX_TOKEN_FILE"

_zbx_complete() {
  local cur prev words cword
  COMPREPLY=()
  _get_comp_words_by_ref -n =: cur prev words cword

  # Position 1: complete subcommands (zbx <sub>)
  if [[ $cword -eq 1 ]]; then
    COMPREPLY=( $(compgen -W "$(_zbx_subcommands)" -- "$cur") )
    return 0
  fi

  # Detect chosen subcommand
  local sub="${words[1]}"

  case "$sub" in
    # ---- zbx search <entity> <pattern> [options] ----
    search)
      # word 2: entity
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=( $(compgen -W "$_zbx_search_entities" -- "$cur") ); return 0
      fi
      # word 3: pattern (free text) -> then options
      if [[ $cword -ge 3 ]]; then
        COMPREPLY=( $(compgen -W "$_zbx_search_opts" -- "$cur") ); return 0
      fi
      ;;

    # ---- zbx config <sub> ... ----
    config)
      # word 2: config subcommand
      if [[ $cword -eq 2 ]]; then
        COMPREPLY=( $(compgen -W "$_zbx_config_subs" -- "$cur") ); return 0
      fi
      local cfgsub="${words[2]}"
      case "$cfgsub" in
        get)
          # zbx config get VAR [--raw]
          if [[ $cword -eq 3 ]]; then
            COMPREPLY=( $(compgen -W "$_zbx_known_vars" -- "$cur") ); return 0
          fi
          if [[ $cword -eq 4 ]]; then
            COMPREPLY=( $(compgen -W "--raw" -- "$cur") ); return 0
          fi
          ;;
        set)
          # zbx config set VAR VALUE [--scope {...}]
          if [[ $cword -eq 3 ]]; then
            COMPREPLY=( $(compgen -W "$_zbx_known_vars" -- "$cur") ); return 0
          fi
          # value is free text; next we might see --scope
          if [[ $cur == --scope* || ${words[$cword-1]} == --scope ]]; then
            if [[ $cur == --scope* && $cur == *=* ]]; then
              local val="${cur#*=}"
              COMPREPLY=( $(compgen -W "$_zbx_config_scopes" -- "$val") )
              # Reattach prefix
              COMPREPLY=( "${COMPREPLY[@]/#/"--scope="}" )
            else
              COMPREPLY=( $(compgen -W "--scope" -- "$cur") )
            fi
            return 0
          fi
          ;;
        unset)
          # zbx config unset VAR [--scope {...}]
          if [[ $cword -eq 3 ]]; then
            COMPREPLY=( $(compgen -W "$_zbx_known_vars" -- "$cur") ); return 0
          fi
          if [[ $cur == --scope* || ${words[$cword-1]} == --scope ]]; then
            if [[ $cur == --scope* && $cur == *=* ]]; then
              local val="${cur#*=}"
              COMPREPLY=( $(compgen -W "$_zbx_config_scopes" -- "$val") )
              COMPREPLY=( "${COMPREPLY[@]/#/"--scope="}" )
            else
              COMPREPLY=( $(compgen -W "--scope" -- "$cur") )
            fi
            return 0
          fi
          ;;
        init)
          # zbx config init [--scope {...}]
          if [[ $cur == --scope* || ${words[$cword-1]} == --scope ]]; then
            if [[ $cur == --scope* && $cur == *=* ]]; then
              local val="${cur#*=}"
              COMPREPLY=( $(compgen -W "$_zbx_config_scopes" -- "$val") )
              COMPREPLY=( "${COMPREPLY[@]/#/"--scope="}" )
            else
              COMPREPLY( $(compgen -W "--scope" -- "$cur") )
            fi
            return 0
          fi
          ;;
        edit|path|list|help|-h|--help)
          # no extra completion
          ;;
        *)
          # fallback to subcommand list if unknown
          COMPREPLY=( $(compgen -W "$_zbx_config_subs" -- "$cur") ); return 0
          ;;
      esac
      ;;

    # ---- generic fallback: offer discovered subcommands ----
    *)
      COMPREPLY=( $(compgen -W "$(_zbx_subcommands)" -- "$cur") )
      ;;
  esac
}

# Register completion (requires bash-completion package for _get_comp_words_by_ref)
# If _get_comp_words_by_ref is not present, define a minimal fallback
type _get_comp_words_by_ref >/dev/null 2>&1 || _get_comp_words_by_ref() { cur="${COMP_WORDS[COMP_CWORD]}"; }

complete -F _zbx_complete zbx
