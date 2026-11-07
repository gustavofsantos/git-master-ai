#!/usr/bin/env bash
# Consistency check for the repository: every JSON file parses, every plugin in plugins.json has
# a manifest with a semver version and a minimum GitMaster version, and the Claude Code
# marketplace points at plugin directories that exist. Run by CI and before a release.
set -euo pipefail
cd "$(dirname "$0")/.."

semver='^[0-9]+\.[0-9]+\.[0-9]+$'
fail=0
err() { echo "error: $*" >&2; fail=1; }

while IFS= read -r file; do
  jq empty "$file" 2>/dev/null || err "$file is not valid JSON"
done < <(find . -name '*.json' -not -path './.git/*')

for id in $(jq -r '.plugins | keys[]' plugins.json); do
  manifest=$(jq -r --arg id "$id" '.plugins[$id].manifest' plugins.json)
  min=$(jq -r --arg id "$id" '.plugins[$id].min_gitmaster // empty' plugins.json)
  [ -f "$manifest" ] || { err "$id: manifest $manifest is missing"; continue; }
  version=$(jq -r '.version // empty' "$manifest")
  [[ $version =~ $semver ]] || err "$id: version '$version' in $manifest is not x.y.z"
  [[ $min =~ $semver ]] || err "$id: min_gitmaster '$min' in plugins.json is not x.y.z"
  [ -d "plugins/$id" ] || err "$id: plugins/$id is missing"
done

for source in $(jq -r '.plugins[].source' .claude-plugin/marketplace.json); do
  [ -d "$source" ] || err "marketplace source $source is missing"
done

exit $fail
