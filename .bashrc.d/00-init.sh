# shellcheck shell=bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FILE                : 00-init.sh
# DESCRIPTION         : Core initialization and foundational functions
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
# Initial Sanities
# - Ensure interactive session
# - Ensure NOT sh (POSIX Defiance)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[[ "$-" =~ i ]] || return                       # Interactive
[[ -z ${PS1+x} ]] && return                     # Interactive
[[ "$(cat /proc/$$/comm)" == "sh" ]] && return  # NOT sh (POSIX Defiance)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Helper for `date`.
# Arguments:
#   -s       Optionally format short -- without nano.
#   -f       Optionally format output for filenames.
#            This option excludes nano component.
#            IE: 1970-01-01T00-00-00Z
# Outputs:
#   - Date format compliant with ISO8601 + nano to the third
#     place in UTC. IE: 1970-01-01T00:00:00.000Z.
#   - Others as described in above arguments.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# shellcheck disable=2120
function dts() {
  case "$1" in
    '-f') date --utc +'%Y-%m-%dT%H-%M-%SZ' ;;
    '-s') date --utc +'%FT%TZ' ;;
     *) date --utc +'%FT%T.%3NZ' ;;
  esac
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Syslog-style exit code handling with colors to improve DX.
# Notes:
#   - User friendly way of achieving consistent log and
#     script output.
#   - Named loggerx to avoid clobbering logger if present.
#   - There is no 9th severity level in RFC5424.
#   - Delimiter sequence: space-hyphen-space ( - )
#   - Accepts multi-line logging.
#     IE: loggerx INFO "This is a
#                       multi-line
#                       log entry"
#   - Includes inline color dict for portability
# Globals:
#   LOG_TO_FILE
#   LOG_FILE
# Arguments:
#   - $1    Log Level
#   - $2-   Message
# Depends On:
#   - function: dts
# Cyclomatic Complexity: 10
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# shellcheck disable=2034,2001
loggerx() {
  local MSG LOG RAW S C C_EMERGENCY C_ALERT C_CRITICAL \
        C_ERROR C_WARNING C_NOTICE C_INFO C_DEBUG C_SUCCESS
  # Reverse lookup dict
  C_EMERGENCY='\e[01;30;41m' # EMERGENCY
  C_ALERT='\e[01;31;43m'     # ALERT
  C_CRITICAL='\e[01;97;41m'  # CRITICAL
  C_ERROR='\e[01;31m'        # ERROR
  C_WARNING='\e[01;33m'      # WARNING
  C_NOTICE='\e[01;30;107m'   # NOTICE
  C_INFO='\e[01;39m'         # INFO
  C_DEBUG='\e[01;97;46m'     # DEBUG
  C_SUCCESS='\e[01;32m'      # SUCCESS
  # Color lookup & spacing
  case $1 in
    "EMERGENCY") C="C_${1}"; S=$(printf "%-39s" '') ;;
    "ALERT")     C="C_${1}"; S=$(printf "%-35s" '') ;;
    "CRITICAL")  C="C_${1}"; S=$(printf "%-38s" '') ;;
    "ERROR")     C="C_${1}"; S=$(printf "%-35s" '') ;;
    "WARNING")   C="C_${1}"; S=$(printf "%-37s" '') ;;
    "NOTICE")    C="C_${1}"; S=$(printf "%-36s" '') ;;
    "INFO")      C="C_${1}"; S=$(printf "%-34s" '') ;;
    "DEBUG")     C="C_${1}"; S=$(printf "%-35s" '') ;;
    "SUCCESS")   C="C_${1}"; S=$(printf "%-37s" '') ;;
    *)           loggerx ERROR "Invalid log level: '$1'!"
                 return 1 ;;
  esac
  # Final formatting
  MSG=$(printf '%b' "$(dts) - ${!C}${1}\e[0m - $(sed 's/^ \+//g'<<<"${*:2}")")
  LOG=$(sed -z 's/\n$//g'<<<"${MSG}" | sed -z "s/\n/\n${S}/g")
  RAW="$THIS_SCRIPT - $1 - $(sed 's/  */ /g'<<<"${*:2}")"
  # Main Operation
  if [[ "$LOG_TO_FILE" == "true" ]]; then
    echo "$LOG" | tee -a "$LOG_FILE"
  else
    echo "$LOG"
  fi
  echo "$RAW" | logger
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 'et' (echo task) and 'rc' (result check) provide a simple
# and consistent method of exit code validation and logging.
# Arguments:
#   $TASK
# Depends On:
#   - function: loggerx
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
et() { loggerx INFO "TASK START: $TASK..."; }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 'et' (echo task) and 'rc' (result check) provide a simple
# and consistent method of exit code validation and logging.
# Arguments:
#   - $1    The expected exit code.
#   - $2    If KILL is passed then exit with passed exit
#           code.
# Cyclomatic Complexity: 3
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rc() {
  local EXIT_CODE=$?
  if [[ "$1" -eq "$EXIT_CODE" ]] ; then
    loggerx SUCCESS "TASK END: $TASK."
  else
    loggerx ERROR "TASK END: $TASK (exit code: $EXIT_CODE -- expected code: $1)"
    if [[ "$2" == "KILL" ]]; then
      # If function, then return
      if [[ "${FUNCNAME[*]:1}" != "" ]] && [[ "${FUNCNAME[-1]}" != "main" ]]; then
        return "$EXIT_CODE"
      fi
      exit "$EXIT_CODE"
    fi
  fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Check remote version of this file for updates.
# - Rate limited to once every 10 seconds.
# - Caches result to ensure meaningful content on every exec.
# - Does not auto-update. User must update with
#   __update_bashrc
# Cyclomatic Complexity: 7
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__check_for_bashrc_user_gist_update() {
  local CADENCE_FILE LOCAL_VERSION LOCAL_FILE REMOTE_VERSION REMOTE_FILE_URL CACHED_RESULT_FILE
  LOCAL_FILE="$HOME/.bashrc.yaml"
  # TODO: move to user_context.sh
  REMOTE_FILE_URL="https://raw.githubusercontent.com/AlexAtkinson/bashrc/refs/heads/main/.bashrc.yaml"
  CADENCE_FILE="/tmp/${USER}_bashrc_version_check_timer"
  [[ ! -f "$CADENCE_FILE" ]] && touch "$CADENCE_FILE"
  CACHED_RESULT_FILE="/tmp/${USER}_bashrc_version_cached_result"
  [[ ! -f "$CACHED_RESULT_FILE" ]] && echo 'init' > "$CACHED_RESULT_FILE"
  # Rate limiting
  # Exit if within cadence period and cached result was false
  [[ $(( $(date +%s) - $(stat "$CADENCE_FILE" -c %Y) )) -le 10 ]] && [[ ! -s "$CACHED_RESULT_FILE" ]] && return 0
  if [[ $(( $(date +%s) - $(stat "$CADENCE_FILE" -c %Y) )) -le 10 ]] && [[ -s "$CACHED_RESULT_FILE" ]]; then
    loggerx ERROR "Rate limit exceeded. Outputting cached result.
                   Try again in $(( 10 - ($(date +%s) - $(stat "$CADENCE_FILE" -c %Y)) )) seconds."
    cat "$CACHED_RESULT_FILE"
    return 0
  fi
  #LOCAL_VERSION=$(grep -m1 '^# VERSION' "$LOCAL_FILE" | cut -d: -f2-)
  LOCAL_VERSION=$(yq .version "$LOCAL_FILE")
  #REMOTE_VERSION=$(curl -sS -r 0-400 "$REMOTE_FILE_URL" | grep -m1 '^# VERSION' | cut -d: -f2-)
  REMOTE_VERSION=$(curl -sS "$REMOTE_FILE_URL" | yq .version)
  if [[ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]]; then
    loggerx NOTICE ".bashrc_user_gist update available. Local: $LOCAL_VERSION | Remote: $REMOTE_VERSION." | \
    tee "$CACHED_RESULT_FILE"
    touch "$CADENCE_FILE"
    return 0
  fi
  truncate -s 0 "$CACHED_RESULT_FILE"
}
__check_for_bashrc_user_gist_update

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# History
# Notes:
#   - Create a separate history file per session
#   - Load ALL previous history for each new session
#   - Commit each command to history immediately
# Implementation:
#   If introducing this to an existing system, the original
#   HISTFILE can be preserved for use with `history` by
#   copying it to ~/.history/. IE:
#     copy ~/.bash_history ~/.history/history_orig.hist
# TODO:
#   - Add cron to monitor/clean ~/.history
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
shopt -s histappend

[[ -d ~/.history ]] || mkdir --mode=0700 ~/.history
[[ -d ~/.history ]] && chmod 0700 ~/.history
touch "$HOME/.history/history.$(date --utc +'%Y-%m-%dT%H-%M-%SZ').$$.hist"
HISTFILE="$HOME/.history/history.$(date --utc +'%Y-%m-%dT%H-%M-%SZ').$$.hist"
HISTTIMEFORMAT="%FT%T "
HISTFILESIZE=20480
HISTSIZE=2048

# Load all previous history files
# TODO: Optimize to avoid loading huge histories repeatedly.
for HISTFILE in ~/.history/history.*.hist; do
  history -r "$HISTFILE"
done
grep -q 'history -a' <<< "$PROMPT_COMMAND" || export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Prompt - Exit Code Indicator
# REF     : https://www.rubydoc.info/gems/rb-readline/0.5.4/RbReadline
#           243    /* Current implementation:
#           244         \001 (^A) start non-visible characters
#           245         \002 (^B) end non-visible characters
#           246    all characters except \001 and \002 (following a \001) are copied to
#           247    the returned string; all characters except those between \001 and
#           248    \002 are assumed to be `visible'. */
#
# NOTES   : - \[ and \] translate to \001 and \002 in bash
#           - 'uX97w' (random string) is used below as variable key to mitigate risk of collision with user actions.
#           - Escape issues appears to be a bug where $- doesn't contain 'i' as required by /etc/profile.d/vte*.sh
#             Once this bug is resolved, then the 5.3 version can be used.
#             A bug-report has been filed.
#
# WARNING : If you use bash's printf or echo -e, and if your text has \001 or \002
#           immediately before a number, you'll hit a bash bug that causes it to eat
#           one digit too many when processing octal escapes – that is, \00142 will
#           be interpreted as octal 014 (followed by ASCII "2"), instead of the
#           correct octal 01 (followed by ASCII "42"). For this reason, use
#           hexadecimal versions \x01 and \x02 instead.
#
# Chars   : ⛳ 🖵 🎱 🟩 🟥 ☠ 💀 ⟫
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Bash Version < 5.3
# shellcheck disable=2181
__exit_symbol_52() {
    [[ $? == 0 ]] && echo -n "⛳⟫"
    [[ $? != 0 ]] && echo -n "💀⟫"
}
# Bash Version >= 5.3
__exit_symbol_53() {
  local EXIT_CODE PROMPT
  EXIT_CODE="$?"
  PROMPT="X"
  [[ $EXIT_CODE -eq 0 ]] && local PROMPT="🟩"
  [[ $EXIT_CODE -ne 0 ]] && local PROMPT="🟥"
  [[ $HISTCMD -eq $PS1_HISTCMD ]] && local PROMPT="🎱"
  printf "%s" "$PROMPT"
}
# shellcheck disable=2154
if [[ "$color_prompt" = "yes" ]]; then
  # Bash Version < 5.3
  PS1='${debian_chroot:+($debian_chroot)}${uX97w[\#]-$(__exit_symbol_52)}${uX97w[\#]+🎱⟫}${uX97w[\#]=}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
  # Bash Version >= 5.3
  # PS1='$(__exit_symbol_53)${|PS1_HISTCMD=$HISTCMD;}⟫${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

case "$TERM" in
tmux*|xterm*|rxvt*|screen)
  # Bash Version < 5.3
  PS1='${debian_chroot:+($debian_chroot)}${uX97w[\#]-$(__exit_symbol_52)}${uX97w[\#]+🎱⟫}${uX97w[\#]=}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
  # Bash Version >= 5.3 # TODO: Verify escapes >>> It's a bug with $-
  #PS1='$(__exit_symbol_53)${|PS1_HISTCMD=$HISTCMD;}⟫${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '
    ;;
*)
    ;;
esac
PROMPT_DIRTRIM=2

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Node Version Manager
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# shellcheck disable=SC1091
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Go
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# shellcheck disable=SC1090
[[ -s "$HOME/.cargo/env" ]] && . ~/.cargo/env
export GOPATH=$HOME/go
export GOBIN=$HOME/go/bin
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:/home/alex/go/bin"
export PATH="$PATH:/usr/libexec/docker/cli-plugins/"



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Director/File permissions
# TODO: Prompt auto-correct.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__permissions_checks() {
  # shellcheck disable=SC2016
  declare -rA permissions_dict=(
    ['$HOME/.ssh']="700"                  # rwx------
    ['$HOME/.ssh/id_*.pub']="644"         # rw-r--r--
    ['$HOME/.ssh/id_*[!.pub]']="600"      # rw-------
    ['$HOME/.ssh/authorized_keys']="600"  # rw-------
    ['$HOME/.ssh/config']="600"           # rw-------
  )
  # shellcheck disable=SC2068
  for i in ${!permissions_dict[@]}; do
    if [[ -e $(eval echo "$i") ]]; then
      if [[ "$(stat -c "%a" "$(eval echo "$i")")" != "${permissions_dict[$i]}" ]]; then
        loggerx WARNING "Permissions for '$(eval echo \"$i\")' ($(stat -c "%a" "$(eval echo \"$i\")")) are incorrect. Recommended: ${permissions_dict[$i]}."
      fi
    fi
  done
}
__permissions_checks

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Directory Assurance
# - Ensures required directories exist.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__directory_assurance() {
  local DIRS=(
    "$HOME/.iptables"
  )
  for DIR in "${DIRS[@]}"; do
    [[ ! -d "$DIR" ]] && mkdir -p "$DIR"
  done
}
__directory_assurance


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Context / Editor / Aliases
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
export SYSTEMD_EDITOR=vim                         # Change default systemctl editor
export EDITOR=vim                                 # Change editor to VIM
alias sudo='sudo '                                # Preserve aliases with sudo
alias visudo='sudo EDITOR=vim visudo'             # Change visudo editor to VIM

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# REGEX
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
export REGEX_INTEGER='^[0-9]+$'
export REGEX_FLOAT='^[0-9]+\.[0-9]+$'
export REGEX_SEMVER="[v]?(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)"
export REGEX_URL='(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)'
export REGEX_IP='((^\s*((([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]))\s*$)|(^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$))'
export REGEX_IPV4='(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
export REGEX_IPV6='(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))'
export REGEX_IPV4_IPV6='((^\s*((([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]))\s*$)|(^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$))'
export REGEX_IP_PRIVATE='10(?:\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}|172\.(?:1[6-9]|2[0-9]|3[01])(?:\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){2}|192\.168(?:\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){2}|127(?:\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}|169\.254(?:\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){2}'
export REGEX_IPV4_PRIVATE='(10|127|169\.254|172\.1[6-9]|172\.2[0-9]|172\.3[0-1]|192\.168)\.'
export REGEX_IPv6_PRIVATE='(^::1$)|(^[fF][cCdD])'
export REGEX_EMAIL='[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
export REGEX_DUPES='(\b\w+\b)(?=.*\b\1\b)'
export REGEX_HEX_COLOR='#?([a-fA-F0-9]{6}|[a-fA-F0-9]{3})\b'
export REGEX_DATE_ISO8601='([0-9]{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])'
export REGEX_TIME_24H='([01][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?'
export REGEX_UUID='[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
export REGEX_MAC_ADDRESS='([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})'
export REGEX_US_PHONE='\(?\b[2-9][0-9]{2}\)?[-.\s]?[2-9][0-9]{2}[-.\s]?[0-9]{4}\b'
export REGEX_CREDIT_CARD='\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|6(?:011|5[0-9]{2})[0-9]{12}|(?:2131|1800|35\d{3})\d{11})\b'
export REGEX_POSTAL_CODE_US='\b\d{5}(-\d{4})?\b'
export REGEX_POSTAL_CODE_CA='\b[ABCEGHJ-NPRSTVXY]\d[ABCEGHJ-NPRSTV-Z] ?\d[ABCEGHJ-NPRSTV-Z]\d\b'
export REGEX_POSTAL_CODE_UK='\b([A-Z]{1,2}\d[A-Z\d]? \d[ABD-HJLNP-UW-Z]{2}|GIR 0AA)\b'
export REGEX_HTML_TAG='<([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>(.*?)<\/\1>'
