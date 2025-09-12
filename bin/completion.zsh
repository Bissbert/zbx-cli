# zsh completion for zbx (git-style dispatcher)

#compdef zbx

# Discover subcommands dynamically from PATH
_zbx_subcommands() {
  compgen -c | grep -E '^zbx-' | sed 's/^zbx-//' | sort -u
}

local -a _zbx_search_entities
_zbx_search_entities=(hosts hostgroups templates items triggers problems macros)

local -a _zbx_config_subs
_zbx_config_subs=(list get set unset edit path init help -h --help)

local -a _zbx_config_scopes
_zbx_config_scopes=(auto project user system)

local -a _zbx_known_vars
_zbx_known_vars=(ZABBIX_URL ZABBIX_USER ZABBIX_PASS ZABBIX_API_TOKEN ZABBIX_VERIFY_TLS ZABBIX_CURL_TIMEOUT ZABBIX_TOKEN_FILE)

_arguments -C \
  '1:subcommand:->sub' \
  '*::args:->args'

case $state in
  sub)
    local -a subs; subs=(${(f)$(_zbx_subcommands)})
    _describe 'zbx commands' subs
    return
  ;;
  args)
    local subcmd=${words[2]}
    case $subcmd in
      search)
        if (( CURRENT == 3 )); then
          _describe 'search entity' _zbx_search_entities
          return
        else
          _values 'search options' --host --like --regex --key --limit --json --help -h
          return
        fi
      ;;
      config)
        if (( CURRENT == 3 )); then
          _describe 'config subcommand' _zbx_config_subs
          return
        fi
        local cfgsub=${words[3]}
        case $cfgsub in
          get)
            if (( CURRENT == 4 )); then
              _describe 'variable' _zbx_known_vars
            else
              _values 'flags' --raw
            fi
            return
          ;;
          set)
            # word 4 is VAR, word 5+ is VALUE; then --scope
            if (( CURRENT == 4 )); then
              _describe 'variable' _zbx_known_vars
              return
            fi
            _values 'options' --scope auto project user system
            return
          ;;
          unset)
            if (( CURRENT == 4 )); then
              _describe 'variable' _zbx_known_vars
              return
            fi
            _values 'options' --scope auto project user system
            return
          ;;
          init)
            _values 'options' --scope auto project user system
            return
          ;;
          edit|path|list|help|-h|--help)
            return
          ;;
          *)
            _describe 'config subcommand' _zbx_config_subs
            return
          ;;
        esac
      ;;
      *)
        # Fallback to discovered subcommands
        local -a subs; subs=(${(f)$(_zbx_subcommands)})
        _describe 'zbx commands' subs
        return
      ;;
    esac
  ;;
esac
