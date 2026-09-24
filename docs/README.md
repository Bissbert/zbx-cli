# Documentation

[← back to the overview](../README.md)

| Topic | What it covers |
|---|---|
| [Architecture](architecture.md) | Dispatcher, shared library, request path, and extension model. |
| [Command surface](commands.md) | Complete table generated from `bin/zbx-*` source. |
| [Configuration and authentication](configuration.md) | Config precedence, variables, token modes, and session cache. |
| [Failure modes](failure-modes.md) | Auth, transport, JSON, API-error, and version behavior. |
| [Bugs found](BUGS-FOUND.md) | Seven fixed bugs with their commits and one rejected report. |
| [Measurement and provenance](measurement.md) | The Linux container run behind every number. |

The repository also contains the older [architecture notes](../ARCHITECTURE.md)
and [optimization notes](../OPTIMISATIONS.md).

The measurement scripts, the table generator and the Linux run are in
[`devtools/`](../devtools/); [`tools/`](../tools/) holds the repository's
completion generator.
