# Covenant Homebrew tap

Homebrew formulae for [Covenant](https://opencovenant.org), on macOS and Linux.

```sh
brew install open-covenant/tap/covenant-compute
```

| Formula | What it installs |
| --- | --- |
| `covenant-compute` | The [Covenant Compute](https://opencovenant.org/compute) command-line tools: `covenant-compute`, `covenant-compute-mcp`, `covenant-compute-node` and `covenant-compute-stake`. |

Each formula installs a signed build from the
[Covenant releases](https://github.com/open-covenant/covenant/releases) and
checks it against the checksum pinned in the formula. The
[Compute guide](https://docs.opencovenant.org/compute) covers what to do next.

## Local Knowledge

Version 0.5.2 also installs the Knowledge guide, source examples and license notices
under `$(brew --prefix covenant-compute)/share/covenant-compute`.

```sh
cp -R "$(brew --prefix covenant-compute)/share/covenant-compute/examples/knowledge" ./knowledge-example
cd knowledge-example
covenant-compute knowledge setup . --query calculate_total --json
covenant-compute knowledge query calculate_total
```

Setup compiles the example, verifies a source citation and prints project-bound
MCP configuration. Copy that configuration into your MCP client; setup does not
edit its settings. Status and the viewer report whether saved source is current,
stale or unavailable. Recompile explicitly after source changes.

These commands run locally without a wallet, daemon or model key. The guide is
`$(brew --prefix covenant-compute)/share/covenant-compute/docs/compute-knowledge.md`.
`brew test covenant-compute` checks the installed versions, guided setup,
source citations, snapshot verification, source freshness and project-bound
read-only MCP tools.
