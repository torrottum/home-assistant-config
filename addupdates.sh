#!/bin/bash

status=$(git status --porcelain)

if grep '^A' <<< "$status" > /dev/null; then
  echo "Uncommmited changes staged, exiting ..."
  exit 1
fi

grep '^\(\(??\| M\) custom_components\| M .HA_VERSION\)' <<< "$status" | sed 's#^..##' \
| while read -r f; do
  name=$(echo "$f" | cut -d/ -f2)
  git add "$f"
  if [ "$name" == ".HA_VERSION" ]; then
    version=$(cat < "$f")
    git commit --author="Tor Røttum <tor@torrottum.no>" -m "update HA to $version"
  else
    git commit --author="Tor Røttum <tor@torrottum.no>" -m "update \"$name\" via HACS"
  fi
done