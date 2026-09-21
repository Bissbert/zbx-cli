# Configuration and authentication

[← back to the overview](../README.md)

Configuration is shell syntax loaded by the client. Environment variables can
override values from a file, and `zbx config` writes a managed override block
without rewriting the rest of that file.

```mermaid
flowchart TD
    A["zbx config / zbx subcommand"] --> B{"ZBX_CONFIG set<br/>to an existing file?"}
    B -- yes --> C["explicit config"]
    B -- no --> D["current directory config.sh"]
    D --> E["repo-local config.sh"]
    E --> F["XDG user config"]
    F --> G["/etc/zbx/config.sh"]
    C --> H["source file, then keep<br/>environment overrides"]
    G --> H
    H --> I["effective variables"]

    style A fill:#1f6feb,stroke:#58a6ff,color:#fff
    style I fill:#238636,stroke:#3fb950,color:#fff
```

## Configuration variables

| Variable | Meaning | Default or behavior |
|---|---|---|
| `ZBX_CONFIG` | Explicit config path. | Used when the path exists. |
| `ZABBIX_URL` | JSON-RPC API endpoint. | The config skeleton supplies the example endpoint. |
| `ZABBIX_USER` / `ZABBIX_PASS` | Credentials for session authentication. | Used when `ZABBIX_API_TOKEN` is empty. |
| `ZABBIX_API_TOKEN` | Static API token. | Uses `Authorization: Bearer`; no session file is read or written. |
| `ZABBIX_VERIFY_TLS` | TLS verification switch. | `1` verifies certificates; `0` passes `--insecure` to `curl`. |
| `ZABBIX_CA_CERT` / `ZABBIX_CA_PATH` | Custom certificate file or certificate directory. | Applied while TLS verification is enabled. |
| `ZABBIX_TOKEN_FILE` | Cached session-token JSON file. | Defaults below the XDG state directory. |
| `ZABBIX_SESSION_TTL` | Session-token lifetime in seconds. | The library default is `1800`; expired JSON tokens trigger login. |
| `ZABBIX_CURL_TIMEOUT` | Both connect and maximum request timeout. | The library default is `25` seconds. |
| `LOG_LEVEL` / `LOG_FILE` | Logging verbosity and optional destination. | Logs go to stderr; debug output requires `LOG_LEVEL=debug`. |

The config command supports `list`, `get`, `set`, `unset`, `init`, `edit`, and
`path`. Its `auto` scope writes to the current directory when writable and
otherwise uses the user config directory. `get` and `list` redact the password
and API token unless `--raw` is requested.

## Authentication path

```mermaid
flowchart TD
    A["zbx_call method"] --> B{"API token set?"}
    B -- yes --> C["Bearer header"]
    B -- no --> D{"Fresh cached token?"}
    D -- yes --> E["JSON-RPC auth field"]
    D -- no --> F["user.login with user + password"]
    F --> G["write token + timestamp<br/>with restrictive umask"]
    G --> E
    C --> H["POST JSON-RPC request"]
    E --> H
    H --> I{"Session terminated?"}
    I -- yes, session mode --> F
    I -- no --> J["return response to jq"]

    style C fill:#8250df,stroke:#bc8cff,color:#fff
    style F fill:#d29922,stroke:#9e6a03,color:#fff
    style J fill:#238636,stroke:#3fb950,color:#fff
```

`apiinfo.version` bypasses this decision and is sent without auth. All other
API methods use the token mode or session mode shown above. A session-expired
response causes one re-login and one retry; the command does not loop forever.
