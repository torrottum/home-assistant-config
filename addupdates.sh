#!/bin/bash

if git status --porcelain | grep '^\(A\|M\)' > /dev/null; then
  echo "Uncommmited changes staged, exiting ..."
  exit 1
fi

# Add component updates
components=$(git status --porcelain \
  | grep "^\(??\| M\) custom_components" | cut -d/ -f2 | sort | uniq)
while read -r component; do
  component_path="custom_components/$component"
  manifest_path="$component_path/manifest.json"
  if [ ! -f "$manifest_path" ]; then
    continue;
  fi

  new_version=$(jq -r '.version' "$manifest_path")
  if git status --porcelain "$manifest_path" | grep "^??"; then
    echo "Add '$component' version $new_version"
    git commit --author="Tor Røttum <tor@torrottum.no>" \
      -m "add '$component' version $new_version [auto-commit]"
  else
    old_version=$(git show "HEAD:$manifest_path" | jq -r '.version')
    echo "Update $component from $old_version to $new_version"
    git commit --author="Tor Røttum <tor@torrottum.no>" \
      -m "update $component from $old_version to $new_version [auto-commit]"
  fi
done <<< "$components"

# Add HA updates
if git status --porcelain | grep "^ M .HA_VERSION" > /dev/null; then
  old_version=$(git show "HEAD:.HA_VERSION")
  new_version=$(cat .HA_VERSION)
  echo "update Home Assistant from $old_version to $new_version"
  git add .HA_VERSION
  git commit --author="Tor Røttum <tor@torrottum.no>" \
    -m "update Home Assistant from $old_version to $new_version [auto-commit]"
fi