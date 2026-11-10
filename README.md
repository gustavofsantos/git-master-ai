# GitMaster AI Plugins

Plugins that connect AI coding agents to [GitMaster](https://github.com/gustavofsantos/git-master). One directory per agent harness under `plugins/`, each in the format that harness expects. They need the `gitmaster` command on `PATH`.

| Plugin | Harness | Directory |
|---|---|---|
| `claude-code` | Claude Code | `plugins/claude-code/` |

The Claude Code plugin ships the skills `propose-memories`, `consolidate`, `prepare`, `inbox` and `write-reviewer`, which use GitMaster memories, review comments and review workflows. The sub-agents `memory-proposer` and `memory-consolidator` run only when a skill starts them, and only propose.

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
scripts/plugin-version.sh claude-code minor
git push origin main claude-code-v0.5.0
```

The script bumps the manifest, runs `scripts/check.sh`, commits and tags `<plugin>-vX.Y.Z`. It never pushes. Raise `min_gitmaster` (add `--min-gitmaster X.Y.Z`) when a plugin starts to rely on a hook or MCP tool that only newer GitMaster versions have.

### Changes

- **0.6.0**: memories belong to contexts, areas of knowledge such as `Finance / Payments`, and repositories are bound to them. The `prepare` skill searches the bound contexts (`scope` `bound`) and names a context the task asks for even when the repository is not bound to it. The `consolidate` skill and the `memory-consolidator` agent work on the contexts the repository is bound to, or on a focus that names any context. The `propose-memories` skill and the `memory-proposer` agent call `contexts_list` and file each memory in the narrowest context it holds for.
- **0.5.0**: review workflows replace reviewer sub-agent files. The `write-reviewer` skill (`/gitmaster:write-reviewer`) writes one Lua workflow for a review of every change or of one task; the `create-reviewer` skill, which wrote a sub-agent file, is removed. The `gitmaster` and `inbox` skills say that a comment can carry a label and decorations, and that a scorecard's comments come from `scorecard_publish`.
- **0.4.0**: the `prepare` skill marks the memories it used at the end of the work (`memory_mark`, `useful` or `wrong` with a reason) and shows a memory with a `wrong` mark as unverified. The `gitmaster` skill explains how to mark honestly and that a mark can be revised. The `memory-consolidator` agent and the `consolidate` skill check memories with a `wrong` mark first, and a disagreement between marks is a reason to check. The consolidator does not mark memories.
- **0.3.0**: the `memory-consolidator` agent and the `consolidate` skill (`/gitmaster:consolidate`); `prepare` caps its brief at 10 memories and about 2,000 characters.

## Use in the GitMaster repository

GitMaster includes this repository as a submodule at `ai/` so the plugins and the app can change together in one workspace, cloud sessions included. The app repository pins the commit it was tested with.

## Checks

`scripts/check.sh` validates every JSON file, the plugin registry and the marketplace paths. CI runs it on every push.
