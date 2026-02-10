# shellcheck shell=bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FILE                : 10-git.sh
# DESCRIPTION         : Git-related functions and aliases
# REPO                : https://github.com/AlexAtkinson/bashrc
# LICENSE             : GPLv3
# COPYRIGHT           : Copyright © 2026 Alex Atkinson. All Rights Reserved.
#
# AUTHOR              : Alex Atkinson
# AUTHOR_EMAIL        :
# AUTHOR_GITHUB       : https://github.com/AlexAtkinson
# AUTHOR_SPONSORSHIP  : https://github.com/sponsors/AlexAtkinson
# AUTHOR_LINKEDIN     : https://www.linkedin.com/in/alex--atkinson
#
# LANG                : bash
# LANG_VERSION        : ~5.2
# LANG_NOTICE         : 5.3 - bugs prevent adoption.
# PLATFORM            : Linux (MacOS with necessary linuxifications)
#
# Artificial Intelligence (AI) Notice
#   This file MUST NOT be used for training artificial intelligence models.
#   The content herein is protected by copyright and licensed under GPLv3.
#   Unauthorized use of this material for AI training purposes is strictly prohibited.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Check SSH Authentication to Github
# Notes:
#   - As a function to facilitate use with `while`
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
check_ssh_authentication_to_github() {
  TASK="Test SSH Authentication to GitHub"; et
  ssh -o "StrictHostKeyChecking accept-new" -T git@github.com 2>&1 | grep -q 'successfully authenticated'
  rc 0
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Check SSH Authentication to CONFIG_REPO
# Notes:
#   - As a function to facilitate use with `while`
# Arguments:
#   $CONFIG_REPO
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
check_ssh_authentication_to_config_repo() {
  TASK="Test SSH Authentication to Private Config Repo"; et
  git ls-remote "$CONFIG_REPO" >/dev/null 2>&1
  rc 0
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FORCE_JIRA_ID variable and git-c-prefix function
# Notes:
#   - Controls whether Jira ID is required in commit messages
# Cyclomatic Complexity: 6
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FORCE_JIRA_ID=false
git-c-prefix() {
  # shellcheck disable=2001,2013
  if [[ $FORCE_JIRA_ID == "true" ]]; then
    unset branch
    unset c_message
    unset branch_pass
    unset c_message_pass
    branch=$(git rev-parse --abbrev-ref HEAD)
    c_message=$*
    reg='[A-Z]{2,10}-[0-9]{1,7}'
  #c_prefix='DEVOPS-00: ' # Always insert a valid issue ID...
    [[ $branch =~ $reg ]] && branch_pass='true'
    if [[ $branch =~ $reg ]] && ! [[ $c_message =~ $reg ]]; then
      jira_id=$(sed 's/,$//' <<< "$(for i in $(grep -Eo "$reg" <<< "$branch"); do printf "%s" "$i,"; done)")
      c_message="${jira_id}: ${c_message}"
    fi
    [[ $c_message =~ $reg ]] && c_message_pass="true"
    if [[ $branch_pass != "true" ]] && [[ $c_message_pass != "true" ]] ; then
      loggerx ERROR "No Jira Issue ID Found!"
      read -rp "Enter Jira ID: " jira_id
      if [[ $jira_id =~ $reg ]]; then
        c_message="${jira_id}: ${c_message}"
      else
        loggerx ERROR "PEBCAK DETECTED! Quitting!"
        return 1
      fi
    fi
    export c_message
  else
    c_message=$*
    export c_message
  fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Git Push Handler
# Notes:
#   - Automatically sets upstream if not already set
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
git_push_handler() {
  result=$(git push 2>&1)
  if grep -q "no upstream branch" <<<  "$result" ; then
    cmd=$(tail -n 1 <<< "$result")
    cmd="${cmd#"${cmd%%[![:space:]]*}"}"
    loggerx WARNING "Pushing to new remote upstream"
    eval "$cmd"
  else
    echo "$result"
  fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Git Aliases
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
alias gitsuno='git status -uno'
alias gitsu='git status -u'
alias gits='git status .'
gitrhard() { git reset --hard HEAD^; }
gitrohard() { git reset --hard origin/"$(git rev-parse --abbrev-ref HEAD)"; }
gitc() { git-c-prefix "$@" && git commit -m "$c_message"; }
gitcp() { git-c-prefix "$@" && git commit -m "$c_message"; git_push_handler; }
gitce() { git-c-prefix "$@" && git commit --allow-empty -m "$c_message"; }
gitcep() { git-c-prefix "$@" && git commit --allow-empty -m "$c_message"; git_push_handler; }
gitdb() { git branch -d "$1"; git push -d origin "$1"; }
alias git-commit-tree='git log --graph --pretty=oneline --abbrev-commit'
git-commit-grep() { git log --oneline | grep "$1" ;}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Git Diff
# Notes:
#   - Uses pygmentize for syntax highlighting
# Arguments:
#   $1      File to diff
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#alias git-diff='git difftool -y -x sdiff HEAD^ $1 | pygmentize | less -R'
git-diff() {
  git difftool -y -x sdiff HEAD^ "$1" | \
    pygmentize | \
    less -R
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Git Search File History
# Notes:
#   - Searches all commits for a string in a specific file
# Arguments:
#   $1      File path
#   $2      Search string
# Usage:
#   git-search-file-history 'path/to/file.txt' 'fooString'
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# shellcheck disable=2013
git-search-file-history () {
  local file string
  if [[ $# -ne 2 ]]; then
    echo "ERROR: Must provide exatly two arguments: <file> <search_string>. Eg:";
    echo "           ${FUNCNAME[0]} 'path/to/file.txt' 'fooString'"
    return 1;
  fi;
  file=$1;
  string=$2;
  for i in $(cut -d: -f1 <<< "$(git grep "$string" "$(git rev-list --all -- "${file}")" -- "${file}")");
  do
    git log -n1 "$i";
  done
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get version of latest release.
# Notes:
#   - This function strips leading '[vV]'.
# Arguments:
#   $1      Github username/organization
#   $2      Repository name
# Outputs:
#   Version of latest release.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
git-latest-release-version() {
  USER="$1"
  REPO="$2"
  local VERSION
  VERSION=$(curl -Ss "https://api.github.com/repos/${USER}/${REPO}/tags" \
  | jq -r '.[].name' \
  | grep -E "$REGEX_SEMVER" \
  | head -n 1)
  [[ "$VERSION" =~ ^[vV]* ]] && VERSION=${VERSION//^[vV]/""/}
  echo "$VERSION"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get asset names of latest release.
# Notes:
#   Simply reports the asset list as many projects diverge
#   from standard OS, ARCH inclusive asset naming schemes.
#   Implement selection downstream.
# Arguments:
#   $1      Github username/organization
#   $2      Repository name
# Outputs:
#   Version of latest release.
# Depends On:
#   - git-latest-release-version
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
git-latest-release-assets() {
  local USER="$1"
  local REPO="$2"
  local VERSION
  VERSION=$(git-latest-release-version "$USER" "$REPO")
  curl -Ss "https://api.github.com/repos/${USER}/${REPO}/releases" \
  | jq -r --arg version "${VERSION}" '.[] | select (.tag_name == $version) | .assets[].name'
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# This is a constant SHA across all repos used for various operations.
# It will always return '4b825dc642cb6eb9a060e54bf8d69288fbee4904'.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
alias git_find_the_empty_tree='git hash-object -t tree /dev/null'

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Clone a gist
# Notes:
#   - Clones gist to ~/git/alexatkinson/gists/<gist_id>
#   - Creates symbolic link in ~/git/alexatkinson/gist_<link_name>
#   - Prompts for link name
#   - Requires rc and et functions
# Arguments:
#   <gist_id>
# Usage:
#   git-clone-gist <gist_id>
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
git_clone_gist () {
    local GIST_ID LINK_NAME OWD GIT_DIR GIST_DIR
    GIST_ID="$1"
    [[ -n "$2" ]] && LINK_NAME="$2"
    OWD="$PWD"
    GIT_DIR="$HOME/git/alexatkinson"
    GIST_DIR="$GIT_DIR/gists"
    TASK="CD to $GIST_DIR"
    cd "$GIST_DIR" || false ; rc 0 KILL
    TASK="Cloning Gist $GIST_ID"
    git clone "git@gist.github.com:${GIST_ID}.git"; rc 0 KILL
    TASK="CD to $GIT_DIR"
    cd "$GIT_DIR" || false ; rc 0 KILL
    [[ -z "$LINK_NAME" ]] && read -rp "Enter a name for the symbolic link: " LINK_NAME
    TASK="Creating symbolic link gist_${LINK_NAME} -> $GIST_DIR/$GIST_ID"
    ln -s "$GIST_DIR/$GIST_ID" "gist_${LINK_NAME}"; rc 0
    cd "$OWD" || false; rc 0
}
