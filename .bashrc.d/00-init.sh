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
# Check remote version of this file for updates.
# - Rate limited to once every 10 seconds.
# - Caches result to ensure meaningful content on every exec.
# - Does not auto-update. User must update with
#   __update_bashrc
# Cyclomatic Complexity: 7
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__check_bashrc_update() {
  local CADENCE_FILE LOCAL_VERSION LOCAL_FILE REMOTE_VERSION REMOTE_FILE_URL CACHED_RESULT_FILE
  LOCAL_FILE="$HOME/.bashrc.yaml"
  REMOTE_FILE_URL="https://raw.githubusercontent.com/AlexAtkinson/bashrc/refs/heads/main/.bashrc.yaml"
  CADENCE_FILE="/tmp/${USER}_bashrc_version_check_timer"
  [[ ! -f "$CADENCE_FILE" ]] && touch "$CADENCE_FILE"
  CACHED_RESULT_FILE="/tmp/${USER}_bashrc_version_cached_result"
  [[ ! -f "$CACHED_RESULT_FILE" ]] && echo 'init' > "$CACHED_RESULT_FILE"
  # Rate limiting
  # Exit if within cadence period and cached result was false
  [[ $(( $(date +%s) - $(stat "$CADENCE_FILE" -c %Y) )) -le 10 ]] && [[ ! -s "$CACHED_RESULT_FILE" ]] && return 0
  if [[ $(( $(date +%s) - $(stat "$CADENCE_FILE" -c %Y) )) -le 10 ]] && [[ -s "$CACHED_RESULT_FILE" ]]; then
    loggerx ERROR "${FUNCNAME[*]}: Rate limit exceeded. Using cached result.
                   Limit resets in: $(( 10 - ($(date +%s) - $(stat "$CADENCE_FILE" -c %Y)) )) seconds."
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
__check_bashrc_update

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
HISTFILE="$HOME/.history/history.$(date --utc +'%Y-%m-%dT%H-%M-%SZ').$$.hist"
touch "$HISTFILE"
HISTTIMEFORMAT="%FT%T "
HISTFILESIZE=20480
HISTSIZE=2048

# Load 30 history files from last 30 days
while read -r histfile; do
  history -r "$histfile"
done <<< "$(find ~/.history/ -type f -name "*.hist" -mtime -30)"

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
# Helper definition guards
# - Avoid defining local helpers when an executable with the
#   same name is already on PATH or a function already exists.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__bashrc_has_helper() {
  type -P "$1" >/dev/null 2>&1 || declare -F "$1" >/dev/null 2>&1
}



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
if ! __bashrc_has_helper dts; then
  function dts() {
    case "$1" in
      '-f') date --utc +'%Y-%m-%dT%H-%M-%SZ' ;;
      '-s') date --utc +'%FT%TZ' ;;
       *) date --utc +'%FT%T.%3NZ' ;;
    esac
  }
fi

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Syslog-style exit code handling with colors to improve DX.
# Notes:
#   - User friendly way of achieving consistent log and
#     script output.
#   - Named loggerx to avoid clobbering logger if present.
#   - There is no 9th severity level in RFC5424.
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
if ! __bashrc_has_helper loggerx; then
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
    MSG=$(printf '%b' "$(dts) ${!C}${1}\e[0m: $(sed 's/^ \+//g'<<<"${*:2}")")
    LOG=$(sed -z 's/\n$//g'<<<"${MSG}" | sed -z "s/\n/\n${S}/g")
    RAW="$THIS_SCRIPT ${1}: $(sed 's/  */ /g'<<<"${*:2}")"
    # Main Operation
    if [[ "$LOG_TO_FILE" == "true" ]]; then
      echo "$LOG" | tee -a "$LOG_FILE"
    else
      echo "$LOG"
    fi
    echo "$RAW" | logger
  }
fi

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 'et' (echo task) and 'rc' (result check) provide a simple
# and consistent method of exit code validation and logging.
# Arguments:
#   $TASK
# Depends On:
#   - function: loggerx
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
et() { loggerx INFO "START: $TASK..."; }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 'et' (echo task) and 'rc' (result check) provide a simple
# and consistent method of exit code validation and logging.
# Arguments:
#   - $1    The expected exit code.
#   - $2    If KILL is passed then exit with passed exit
#           code.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rc() {
  local EXIT_CODE=$?
  if [[ "$1" -eq "$EXIT_CODE" ]] ; then
    loggerx SUCCESS "$TASK."
  else
    loggerx ERROR "$TASK (exit code: $EXIT_CODE -- expected code: $1)"
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
        loggerx WARNING "Permissions for '$(eval echo \""$i"\")' ($(stat -c "%a" "$(eval echo \""$i"\")")) are incorrect. Recommended: ${permissions_dict[$i]}."
      fi
    fi
  done
}
__permissions_checks

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# bashrc.d VARS initialization
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Ensure bashrc.d/00-VARS.sh exists
[[ ! -f "$HOME/.bashrc.d/00-VARS.sh" ]] && touch "$HOME/.bashrc.d/00-VARS.sh"
# shellcheck source=/dev/null
source "$HOME/.bashrc.d/00-VARS.sh"

if [[ -z ${GIT_USERNAME+x} ]]; then
  loggerx NOTICE "Variable 'GIT_USERNAME' not found. Adding it to 00-VARS.sh."
  read -rp "Press [ENTER] to use '$USER', or enter a new value: " GIT_USERNAME
  # If GIT_USERNAME is blank, use USER
  [[ -z "$GIT_USERNAME" ]] && GIT_USERNAME="$USER"
  echo "export GIT_USERNAME='$GIT_USERNAME'" >> "$HOME/.bashrc.d/00-VARS.sh"
  export GIT_USERNAME="$GIT_USERNAME"
fi

# Don't clobber GIT_DIR
if [[ -z ${GIT_USERDIR+x} ]]; then
  loggerx NOTICE "Variable 'GIT_USERDIR' not found. Adding it to 00-VARS.sh."
  read -rp "Press [ENTER] to use '$HOME/git/$GIT_USERNAME', or enter a new value: " GIT_USERDIR
  # If GIT_USERDIR is blank, use default
  [[ -z "$GIT_USERDIR" ]] && GIT_USERDIR="$HOME/git/$GIT_USERNAME"
  echo "export GIT_USERDIR='$GIT_USERDIR'" >> "$HOME/.bashrc.d/00-VARS.sh"
  export GIT_USERDIR="$GIT_USERDIR"
fi

# Location for the htop weather overlay (see 03-utility.sh)
if [[ -z ${WEATHER_LOCALE+x} ]]; then
  loggerx NOTICE "Variable 'WEATHER_LOCALE' not found. Adding it to 00-VARS.sh."
  read -rp "Press [ENTER] to use 'Toronto', or enter a new value: " WEATHER_LOCALE
  # If WEATHER_LOCALE is blank, use default
  [[ -z "$WEATHER_LOCALE" ]] && WEATHER_LOCALE="Toronto"
  echo "export WEATHER_LOCALE='$WEATHER_LOCALE'" >> "$HOME/.bashrc.d/00-VARS.sh"
  export WEATHER_LOCALE="$WEATHER_LOCALE"
fi

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Directory Assurance
# - Ensures required directories exist.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__directory_assurance() {
  local DIRS=(
    "$HOME/.iptables"
    "$GIT_USERDIR"
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
