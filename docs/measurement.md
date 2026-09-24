# Measurement and provenance

[← back to the overview](../README.md)

Every number in this documentation comes from one script run in a Linux
container:

```sh
sh devtools/linux-run.sh > docs/captures/linux-run.txt
```

[`devtools/linux-run.sh`](../devtools/linux-run.sh) starts
`python:3.12-slim-bookworm`, installs curl, jq, make and git, and runs
`git clone` on the read-only mounted repository, so the file modes are the
committed ones. No Zabbix endpoint is contacted. The full output is
[`captures/linux-run.txt`](captures/linux-run.txt); every block below is taken
from it.

```mermaid
flowchart LR
    A["git clone<br/>(committed modes)"] --> B["devtools/measure.sh"]
    A --> C["generate-command-table.sh"]
    A --> D["make test"]
    A --> E["behaviour checks"]
    B --> F["README results"]
    C --> G["docs/commands.md"]
    D --> H["measurement.md"]
    E --> H

    style A fill:#1f6feb,stroke:#58a6ff,color:#fff
    style F fill:#238636,stroke:#3fb950,color:#fff
    style G fill:#238636,stroke:#3fb950,color:#fff
    style H fill:#8250df,stroke:#bc8cff,color:#fff
```

## Environment

| | |
|---|---|
| Kernel | Linux 6.5.11-linuxkit, aarch64 (Docker Desktop VM) |
| Image | `python:3.12-slim-bookworm` (`sha256:392307d2…23564e`) |
| Tools | GNU bash 5.2.15, curl 7.88.1, jq 1.6 |
| Date | 2026-09-24 |

## Repository snapshot

`devtools/measure.sh`:

| Measurement | Value |
|---|---:|
| User-facing command source files | 34 |
| Bytes in those command files | 59,770 |
| Lines in those command files | 1,755 |
| Bytes in all `bin/*` files | 79,103 |
| Lines in all `bin/*` files | 2,351 |
| Shell test files | 18 |

## Command table

`devtools/generate-command-table.sh` reads each `bin/zbx-*` file, skips the
sourced `zbx-lib`, and extracts the first `Usage:` line and description. All
36 table rows it generates are present in [`commands.md`](commands.md).

## Tests

`make test` runs every `tests/test_*.sh`. In a fresh clone:

```
Summary: 16 passed, 0 failed, 2 skipped
```

The two integration tests need `ZABBIX_URL` and a reachable endpoint, and
`tests/run.sh` skips them when it is not set. The mock tests put
`tests/mock-bin` first on `PATH`; its `curl` answers from fixed JSON, refuses
calls without a token or session as Zabbix does, can return an error for one
method (`MOCK_API_ERROR`), and logs each request (`MOCK_CURL_LOG`) so the
tests can check the parameters sent.

To run the integration tests against a server:

```sh
ZABBIX_URL=https://zabbix.example.com/api_jsonrpc.php \
  ZABBIX_API_TOKEN=... make test
```

The integration suite is read-only.

## Behaviour checks

The script also checks behaviour that earlier versions got wrong:

| Check | Result |
|---|---|
| Installed `zbx --list` | `commands listed: 34, lib listed: 0` after `make install` |
| Mock curl | `-rwxr-xr-x`, and `command -v curl` resolves to `tests/mock-bin/curl` |
| Token-mode API error | `zbx-ping` and `zbx-version` exit 1 and log `API error: ...` |
| Doctor against a closed port | prints the network message; no `000000` |
| Executable bit ([#4](https://github.com/Bissbert/zbx-cli/issues/4)) | 38 files at `100755`; `bash bin/zbx config --help` exits 0 |
| No login shells in tests ([#5](https://github.com/Bissbert/zbx-cli/issues/5)) | no login-shell invocations in `tests/` |
| Session login ([#6](https://github.com/Bissbert/zbx-cli/issues/6)) | `zbx login` exits 0, prints `ok`, caches `sess-0123` |

## Not covered

No live Zabbix endpoint was available, so there is no network latency,
throughput, API-compatibility or live command result. The Mermaid diagrams
describe the source; they are not captured program output.
