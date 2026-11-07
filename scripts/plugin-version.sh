#!/usr/bin/env bash
# Version one plugin on its own (semver, independent of the GitMaster app).
#
#   scripts/plugin-version.sh <plugin> show
#   scripts/plugin-version.sh <plugin> <patch|minor|major|X.Y.Z> [--min-gitmaster X.Y.Z]
#
# Writes the new version into the plugin's native manifest (the single source of the version),
# optionally raises the minimum GitMaster version it needs in plugins.json, runs the check,
# commits "chore(<plugin>): release X.Y.Z" and creates the tag "<plugin>-vX.Y.Z".
# Nothing is pushed: `git push origin main <tag>` is the maintainer's step.
set -euo pipefail
cd "$(dirname "$0")/.."

plugin=${1:?usage: plugin-version.sh <plugin> <show|patch|minor|major|X.Y.Z> [--min-gitmaster X.Y.Z]}
action=${2:?missing action}
shift 2
min=""
if [ "${1:-}" = "--min-gitmaster" ]; then min=${2:?missing version}; fi

manifest=$(jq -er --arg id "$plugin" '.plugins[$id].manifest' plugins.json) \
  || { echo "unknown plugin '$plugin' (see plugins.json)" >&2; exit 2; }
current=$(jq -er '.version' "$manifest")

if [ "$action" = show ]; then
  echo "$plugin $current (needs gitmaster >= $(jq -r --arg id "$plugin" '.plugins[$id].min_gitmaster' plugins.json))"
  exit 0
fi

IFS=. read -r major minor patch <<<"$current"
case "$action" in
  patch) next="$major.$minor.$((patch + 1))" ;;
  minor) next="$major.$((minor + 1)).0" ;;
  major) next="$((major + 1)).0.0" ;;
  *) next=$action ;;
esac
[[ $next =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "'$action' is not patch, minor, major or X.Y.Z" >&2; exit 2; }
[ "$next" != "$current" ] || { echo "$plugin is already at $current" >&2; exit 2; }

tag="$plugin-v$next"
git diff --quiet && git diff --cached --quiet || { echo "working tree is not clean" >&2; exit 2; }
! git rev-parse -q --verify "refs/tags/$tag" >/dev/null || { echo "tag $tag exists" >&2; exit 2; }

jq --arg v "$next" '.version = $v' "$manifest" >"$manifest.tmp" && mv "$manifest.tmp" "$manifest"
if [ -n "$min" ]; then
  jq --arg id "$plugin" --arg v "$min" '.plugins[$id].min_gitmaster = $v' plugins.json >plugins.json.tmp \
    && mv plugins.json.tmp plugins.json
fi
scripts/check.sh

git add "$manifest" plugins.json
git commit -q -m "chore($plugin): release $next"
git tag -a "$tag" -m "$plugin $next"
echo "$plugin $current -> $next, tagged $tag; push with: git push origin main $tag"
