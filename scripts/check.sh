#!/usr/bin/env bash
# Consistency check for the repository: every JSON file parses, every plugin in plugins.json has
# a manifest with a semver version and a minimum GitMaster version, and the Claude Code
# and Cursor marketplaces point at plugin directories that exist, and the Cursor skills and agents
# are named after their files. Run by CI and before a release.
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

for marketplace in .claude-plugin/marketplace.json .cursor-plugin/marketplace.json; do
  for source in $(jq -r '.plugins[].source' "$marketplace"); do
    [ -d "$source" ] || err "$marketplace: source $source is missing"
  done
done

# Cursor loads a skill only when its name matches its folder, and an agent by its name.
for skill in plugins/cursor/skills/*/SKILL.md; do
  folder=$(basename "$(dirname "$skill")")
  grep -qx "name: $folder" "$skill" || err "$skill: name is not $folder"
done
for agent in plugins/cursor/agents/*.md; do
  grep -qx "name: $(basename "$agent" .md)" "$agent" || err "$agent: name is not its file name"
done

exit $fail
