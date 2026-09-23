# Documentation

[← back to the overview](../README.md)

| Topic | What it covers |
|---|---|
| [Architecture](architecture.md) | Dispatcher, shared library, request path, and extension model. |
| [Command surface](commands.md) | Complete table generated from `bin/zbx-*` source. |
| [Configuration and authentication](configuration.md) | Config precedence, variables, token modes, and session cache. |
| [Failure modes](failure-modes.md) | Auth, transport, JSON, API-error, and version behavior. |
| [Bugs found](BUGS-FOUND.md) | Observed implementation bugs, reproductions, and proposed fixes; no code changes. |
| [Measurement and provenance](measurement.md) | How the repository counts and test boundaries were established. |

The repository also contains the older [architecture notes](../ARCHITECTURE.md)
and [optimization notes](../OPTIMISATIONS.md).

The pass-specific measurement and table generators are in [`devtools/`](../devtools/);
the existing [`tools/`](../tools/) directory remains unchanged.
