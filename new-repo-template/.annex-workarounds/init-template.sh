#!/bin/bash

if ! [[ -d ".annex-workarounds" ]]; then
 echo "This script needs to be run from the root of the new repository"
 exit 1
fi

source ".annex-workarounds/bin/annex-common-functions.sh"

git init

read -p "Name of this Repo: " name
git annex init "$name"
git annex wanted . "exclude=archive/* and (present or metadata=tag=wanted-$(git config annex.uuid) or include=*/dotgit/*)"

read -p "Should we initialize and use a gnupg home inside this repo? [Yn] " OVERRIDE_GNUPGHOME

if ! is_false "$OVERRIDE_GNUPGHOME"; then

 cat >> ".annex-workarounds/annex.conf" <<EOF
OVERRIDE_GNUPGHOME=Y
EOF

 killall -KILL gpg-agent
 export GNUPGHOME=".annex-workarounds/gnupg"
 gpg --full-generate-key
 killall -KILL gpg-agent

 git config gcrypt.gpg-args "--no-permission-warning"
 git config annex.gnupg-options "--no-permission-warning"

 unset -v GNUPGHOME
else
  cat >> ".annex-workarounds/annex.conf" <<EOF
OVERRIDE_GNUPGHOME=N
EOF
fi

.annex-workarounds/bin/annex-sync
