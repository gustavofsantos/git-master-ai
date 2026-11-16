#!/usr/bin/env bash
# Install a plugin from this checkout into the agent's local plugin folder, or remove it.
#
#   scripts/install-local.sh cursor [--dir DIR] [--force]
#   scripts/install-local.sh cursor --uninstall [--dir DIR]
#
# Cursor loads local plugins from ~/.cursor/plugins/local/<name>/ and skips a symlink that points
# outside that folder, so the plugin is copied, not linked. Run it again after `git pull` to
# update the copy. The copy replaces the folder whole; a folder that is not this plugin is left
# alone unless --force is given. Claude Code needs no script: it installs with `claude plugin`.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)

usage() {
  echo "usage: install-local.sh cursor [--uninstall] [--dir DIR] [--force]" >&2
  exit 2
}

plugin=${1:-}
[ -n "$plugin" ] || usage
shift
case "$plugin" in
  cursor) ;;
  claude-code)
    echo "claude-code installs with: claude plugin marketplace add gustavofsantos/git-master-ai && claude plugin install gitmaster@gitmaster" >&2
    exit 2
    ;;
  *)
    echo "unknown plugin '$plugin': this script installs cursor" >&2
    exit 2
    ;;
esac

uninstall=0
force=0
dir=""
while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall) uninstall=1 ;;
    --force) force=1 ;;
    --dir)
      [ $# -ge 2 ] || usage
      dir=$2
      shift
      ;;
    *) usage ;;
  esac
  shift
done

command -v jq >/dev/null || { echo "install-local.sh needs jq" >&2; exit 1; }

source_dir="$root/plugins/$plugin"
manifest="$source_dir/.cursor-plugin/plugin.json"
[ -f "$manifest" ] || { echo "$manifest is missing" >&2; exit 1; }
name=$(jq -er '.name' "$manifest")
version=$(jq -er '.version' "$manifest")
min=$(jq -r --arg id "$plugin" '.plugins[$id].min_gitmaster // "0.0.0"' "$root/plugins.json")

local_dir=${dir:-"${CURSOR_HOME:-$HOME/.cursor}/plugins/local"}
target="$local_dir/$name"

# True when $1 holds this plugin (a Cursor manifest with the same name), so it may be replaced.
ours() {
  [ -f "$1/.cursor-plugin/plugin.json" ] \
    && [ "$(jq -r '.name // empty' "$1/.cursor-plugin/plugin.json" 2>/dev/null)" = "$name" ]
}

if [ -e "$target" ] || [ -L "$target" ]; then
  if ! ours "$target" && [ "$force" -ne 1 ]; then
    echo "$target exists and is not the $name plugin; pass --force to replace it" >&2
    exit 1
  fi
fi

if [ "$uninstall" -eq 1 ]; then
  if [ -e "$target" ] || [ -L "$target" ]; then
    rm -rf "$target"
    echo "removed $target"
    echo "Reload Cursor (Developer: Reload Window) to unload it. Stored threads stay in GitMaster."
  else
    echo "$name is not installed in $local_dir"
  fi
  exit 0
fi

# Copy beside the target, then swap, so a failed copy never leaves half a plugin behind.
mkdir -p "$local_dir"
staging=$(mktemp -d "$local_dir/.$name.XXXXXX")
trap 'rm -rf "$staging"' EXIT
cp -R "$source_dir/." "$staging/"
chmod 755 "$staging"
rm -rf "$target"
mv "$staging" "$target"
trap - EXIT
echo "installed $name $version (cursor) in $target"

# The plugin calls `gitmaster` from PATH; say so now rather than when the first hook runs.
if ! command -v gitmaster >/dev/null; then
  echo "warning: gitmaster is not on PATH; the hooks and the MCP server need it" >&2
else
  have=$(gitmaster --version 2>/dev/null | awk 'NR == 1 { print $2 }')
  lowest=$(printf '%s\n%s\n' "$min" "${have%%-*}" | sort -t. -k1,1n -k2,2n -k3,3n | head -n1)
  if [ -n "$have" ] && [ "$lowest" != "$min" ]; then
    echo "warning: the plugin needs gitmaster $min or newer, this is $have" >&2
  fi
fi
echo "Reload Cursor (Developer: Reload Window), then open Customize to see the gitmaster skills, agents, hooks and MCP server."
