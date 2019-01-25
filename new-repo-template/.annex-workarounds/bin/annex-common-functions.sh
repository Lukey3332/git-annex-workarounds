# Functions is_true and is_fals below are borrowed from Relax-and-Recover

is_true() {
 # The argument is usually the value of a variable which needs to be tested
 # only if there is explicitly a 'true' value then is_true returns true
 # so that an unset variable or an empty value is not true
 # and also for any other value that is not recognized as a 'true' value
 # by the is_true function the is_true function results false:
 case "$1" in
  ([tT] | [yY] | [yY][eE][sS] | [tT][rR][uU][eE] | 1)
  return 0 ;;
 esac
 return 1
}

is_false() {
 # The argument is usually the value of a variable which needs to be tested
 # only if there is explicitly a 'false' value then is_false returns true
 # so that an unset variable or an empty value is not false
 # (caution: for unset or empty variables is_false is false)
 # and also for any other value that is not recognized as a 'false' value
 # by the is_false function the is_false function results false:
 case "$1" in
  ([fF] | [nN] | [nN][oO] | [fF][aA][lL][sS][eE] | 0)
  return 0 ;;
 esac
 return 1
}

annex-find-root() {
 local root
 local curdir="$(pwd)"
 root="$curdir"
 # First find out annex root (ignore non-annex git repos)
 while ! [ -d "${root}/.git/annex" ]; do
  root="$(dirname "$root")"
  if [[ "$root" == "/" ]]; then
   echo "Unable to find git-annex repository" >&2
   exit 1
  fi
 done
 cd "$curdir"
 echo -n "$root"
}

# Rename .git to dotgit
annex-mask-git() {
 local root="$1"
 if ! [[ -f "${root}/.annex-workarounds/git-repos.conf" ]]; then
  echo "Error: Can't access .annex-workarounds/git-repos.conf" >&2
  echo "Try getting it manually using \"git annex get .annex-workarounds/git-repos.conf\"" >&2
  exit 1
 fi
 shopt -s nullglob
 cat "${root}/.annex-workarounds/git-repos.conf" | \
 while read line; do
  # Is this line a Comment or empty?
  ( [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]] ) && continue
  for n in "${root}/"$line; do
   [[ -d "$n/.git" ]] || continue
   mv "$n/.git" "$n/dotgit" || exit 1
  done
 done
 shopt -u nullglob
}

# Rename dotgit back to .git
annex-unmask-git() {
 local root="$1"
 if ! [[ -f "${root}/.annex-workarounds/git-repos.conf" ]]; then
  echo "Error: Can't access .annex-workarounds/git-repos.conf" >&2
  echo "Try getting it manually using \"git annex get .annex-workarounds/git-repos.conf\"" >&2
  exit 1
 fi
 shopt -s nullglob
 cat "${root}/.annex-workarounds/git-repos.conf" | \
 while read line; do
  # Is this line a Comment or empty?
  ( [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]] ) && continue
  for n in "${root}/"$line; do
   [[ -d "$n/.git" ]] || continue
   mv "$n/dotgit" "$n/.git" || exit 1
  done
 done
 shopt -u nullglob
}

annex-pre() {
 local root="$1"
 source "${root}/.annex-workarounds/annex.conf"
 
 if is_true "$OVERRIDE_GNUPGHOME"; then
  killall -KILL gpg-agent
  export GNUPGHOME="${root}/.annex-workarounds/gnupg"
 fi
 
 annex-mask-git "$root"
}

annex-post() {
 local root="$1"
 source "${root}/.annex-workarounds/annex.conf"
 
 if is_true "$OVERRIDE_GNUPGHOME"; then
  killall -KILL gpg-agent
  unset -v GNUPGHOME
 fi
 
  annex-unmask-git "$root"
}
