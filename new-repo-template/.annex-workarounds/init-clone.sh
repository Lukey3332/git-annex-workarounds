#!/bin/bash

if ! [[ -d ".annex-workarounds" ]]; then
 echo "This Script needs to be run from the root of the Repo"
 exit 1
fi

read -p "Name of this Repo: " name
git annex init "$name"

echo "Execute the following on the source repo: git remote add <this-repo>"

git annex wanted . "exclude=archive/* and (present or metadata=tag=wanted-$(git config annex.uuid) or include=*/dotgit/*)"

source ".annex-workarounds/bin/annex-common-functions.sh"
root="$(annex-find-root)" || exit $?
annex-post "$root"

source "${root}/.annex-workarounds/annex.conf"

if is_true "$OVERRIDE_GNUPGHOME"; then
 git config gcrypt.gpg-args "--no-permission-warning"
 git config annex.gnupg-options "--no-permission-warning"
fi
