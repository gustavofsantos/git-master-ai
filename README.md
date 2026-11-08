# GitMaster AI Plugins

Plugins that connect AI coding agents to [GitMaster](https://github.com/gustavofsantos/git-master). One directory per agent harness under `plugins/`, each in the format that harness expects. They need the `gitmaster` command on `PATH`.

| Plugin | Harness | Directory |
|---|---|---|
| `claude-code` | Claude Code | `plugins/claude-code/` |

The Claude Code plugin ships the skills `propose-memories`, `prepare` and `inbox`, which use GitMaster memories and review comments.

Codex, Cursor and Antigravity plugins are added here as their formats are verified.

## Install (Claude Code)

```sh
claude plugin marketplace add gustavofsantos/git-master-ai
claude plugin install gitmaster@gitmaster
```

The marketplace is `.claude-plugin/marketplace.json`; its name is `gitmaster`.

## Versioning

Each plugin has its own semantic version, independent of the GitMaster app. The version lives once, in the plugin's native manifest (for Claude Code, `plugins/claude-code/.claude-plugin/plugin.json`). `plugins.json` lists the plugins and the minimum GitMaster version each one needs (`min_gitmaster`).

```sh
scripts/plugin-version.sh claude-code show
scripts/plugin-version.sh claude-code minor --min-gitmaster 0.3.0
git push origin main claude-code-v0.2.0
```

The script bumps the manifest, runs `scripts/check.sh`, commits and tags `<plugin>-vX.Y.Z`. It never pushes. Raise `min_gitmaster` when a plugin starts to rely on a hook or MCP tool that only newer GitMaster versions have.

## Use in the GitMaster repository

GitMaster includes this repository as a submodule at `ai/` so the plugins and the app can change together in one workspace, cloud sessions included. The app repository pins the commit it was tested with.

## Checks

`scripts/check.sh` validates every JSON file, the plugin registry and the marketplace paths. CI runs it on every push.
