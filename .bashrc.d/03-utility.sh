# shellcheck shell=bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FILE                : 03-utility.sh
# DESCRIPTION         : General utility functions and aliases
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
# Unicode Browser and Search
# Launches an fzf-based Unicode character browser.
# Dependencies:
#   - fzf
# Notes:
#   - Uses Variation Selectors to display characters.
#     See: https://en.wikipedia.org/wiki/Variation_Selectors
#   - Use left/right arrow keys to change Variation Selector.
#   - NOTICE: Search is by hex codepoint.
# Codes:
#   - 0028: braille pattern dots-1-2-3-4-5-6-7-8
#   - FE00..FE0F:
# Credit: https://stackoverflow.com/a/76256737/2676075
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
unicode_browser() {
  local mod tmpfile res aList
  showU8 () {
    local _i _a _f _e _t
    printf -v _f '%*s' 16 ''
    _t=${_f// /--}  _f="${_f// / %b}"
    printf -v _t '%s  %s  %s\n' "${_t::6}" "${_t:1}"{,}
    printf -v _e '\\U%X' $(($1>16?$1+917743:$1+65023))
    _e="${_f//b/b$_e}"
    printf 'Show UTF8 table using: VARIATION SELECTOR-%d (U+%X)\n' \
        "$1" $(($1>16?$1+917743:$1+65023))
    shift
    for _a; do
      printf "U%03Xyx $_f $_e\n%s" 0x"${_a}" {,}{{0..9},{A..F}} "$_t"
      for _i in {0..9} {A..F}; do
        (( 16#$_a == 0 )) && (( ( 16#$_i & 7 )  < 2 )) &&
          printf 'U%04Xx%68s\n' 0x"$_a$_i" '' && continue
        printf "U%04Xx $_f $_e\n"  0x"$_a$_i" \
          "\\U$_a$_i"{,}{{0..9},{A..F}}
      done
    done
  }
  tmpfile=$(mktemp) ; echo "${mod:-16}" >"$tmpfile"
  aList=( {0..215} {249..282} {284..293} {303..308} {324..326} {360..363} \
          {366..367} {392..396} {431..434} {444..444} {463..474} {479..482} {487..489}\
          {492..494} {496..507} {512..747} {760..762} {768..787} {3584..3585} )
  res="$(
    fzf --no-mouse -m < <(printf '%04X\n' "${aList[@]}") --preview \
      "$(declare -f showU8);showU8 \$(<$tmpfile) {}" --preview-window 74 \
      --bind "left:execute| mod=\$(<$tmpfile) ; echo > $tmpfile \$(( \
        mod > 1 ? mod - 1 : 256 ))|+refresh-preview" \
      --bind "right:execute| echo > $tmpfile \$(( mod=\$(<$tmpfile), \
        mod < 256 ? mod + 1 : 1 ))|+refresh-preview" )"
  showU8 "$(<"$tmpfile")" "$res"
  rm "$tmpfile"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Unicode Search
# Searches Unicode characters by name.
# Arguments:
#   - $1    Search term (case insensitive)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
unicode_search() {
  python3  -c $'from unicodedata import name
for i in range(0x10FFFF):
  try:
    var = name(chr(i))
  except:
    var = None
  finally:
    if var:
      print("\\\\U%06X: \47%s\47 %s" % (i,chr(i),var))' | \
        grep -i --color=auto "$1"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Working Indicator
# Displays an animated working indicator in the terminal.
# Arguments:
#   - $@            Array of symbols to use for animation.
#                   If none provided, defaults to a set of
#                   five symbols.
#   - spinner       If 'spinner' is provided as an argument,
#                   the symbols will spin in a circular
#                   manner.
# Usage:
#   __working ⚪ 🟡 🟠 🟢 🟤
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__working() {
  local args="$*"
  # shellcheck disable=SC2206
  local symbols=( ${args} )
  [[ "$args" =~ "spinner" ]] && local spin='true'
  # shellcheck disable=2206
  [[ "$args" =~ "spinner" ]] && local symbols=( ${args//spinner/} )
  [[ $# -le 1 ]] && declare -a symbols=("𝍠" "𝍡" "𝍢" "𝍣" "𝍤")
  local direction='up'
  while true; do
    for ((s=0; s<${#symbols[@]}; s++)); do
      printf "\r%s  Working..." "${symbols[$s]}"
      sleep 0.2
      if [[ ! "$spin" == "true" ]]; then
        [[ "$s" -eq $((${#symbols[@]} - 1)) && "$direction" == "up" ]] && direction='down'
        [[ "$s" -eq 0 && "$direction" == "down" ]] && direction='up'
        [[ "$direction" == "down" ]] && s=$((s - 2))
      fi
    done
  done
  printf "\r%s Done!     \n" "✅"
}

# Aliases for common working indicators
alias __working_suits='__working ♣️ ♦️ ♠️ ♥️ spinner'
alias __working_colors='__working ⚪ 🟡 🟠 🟢 🟤 🔴 🔵 🟣 ⚫'
alias __working_colors_square='__working ⬜ 🟨 🟧 🟩 🟫 🟥 🟦 🟪 ⬛'
alias __working_moon_phases='__working 🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘 spinner'
alias __working_dots='__working ⣾ ⣽ ⣻ ⢿ ⡿ ⣟ ⣯ ⣷ spinner'
alias __working_clocks='__working 🕐 🕑 🕒 🕓 🕔 🕕 🕖 🕗 🕘 🕙 🕚 🕛 spinner'
alias __working_breath='__working 🞅 🞆 🞇 🞈 🞉'

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Helper: Context Helper
# Identifies current operating context.
# Outputs:
#   Prints one of the following:
#     - terminal
#     - ssh
#     - sudo
#     - script
#     - function
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__context() {
  local results=()
  [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]] && results+=("ssh")
  [[ "$SUDO_USER" && "$SUDO_USER" != "$USER" ]] && results+=("sudo")
  [[ -n "$PS1" ]] && results+=("terminal")
  [[ "${BASH_SOURCE[1]}" == "$0" ]] && results+=("script")
  [[ -n "${FUNCNAME[1]}" ]] && results+=("function")
  echo "${results[@]}" | tr ' ' ','
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Helper: Data Type
# Arguments:
#   $1             Variable Name
# Outputs:
#   Prints the data type of the variable.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__data_type() {
  [[ -z "$1" ]] && { loggerx ERROR "Data is required." >&2; return 1; }
  local data="$*"
  local result="string"
  grep -qE "$REGEX_INTEGER"<<<"$data" && result="integer"
  grep -qE "$REGEX_FLOAT"<<<"$data" && result="float"
  grep -qE "$REGEX_SEMVER"<<<"$data" && result="semver"
  grep -qE "$REGEX_URL"<<<"$data" && result="url"
  grep -qE "$REGEX_IPV4"<<<"$data" && result="ipv4"
  grep -qE "$REGEX_IPV6"<<<"$data" && result="ipv6"
  grep -qE "$REGEX_IP_PRIVATE"<<<"$data" && result="ip_private"
  grep -qE "$REGEX_EMAIL"<<<"$data" && result="email"
  echo "$result"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Helper: Variable Type
# Arguments:
#   $1             Variable Name
# Outputs:
#   Prints the type of the variable.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__variable_type() {
  [[ -z "$1" ]] && { loggerx ERROR "Variable name is required." >&2; return 1; }
  local var_name="$1"
  local result
  local var_type
  result=$(declare -p "$var_name" 2>&1)
  case "$result" in
    declare\ -a*) var_type="array"             ;;
    declare\ -A*) var_type="associative array" ;;
    declare\ -i*) var_type="integer"           ;;
    declare\ -r*) var_type="readonly"          ;;
    declare\ -x*) var_type="exported"          ;;
    declare\ --*) var_type="string"            ;;
    *not\ found*) var_type="undefined"        ;;
    *)            var_type="unknown"           ;;
  esac
  echo "$var_type"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Sanity: Is SUDO
# Notes:
#   - Exits script if not run with sudo.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__is_sudo() {
  local term_cmd
  __context | grep -qE 'terminal' && term_cmd='return 1' || term_cmd='exit 1'
  [[ "$EUID" -ne 0 && "$1" == "KILL" ]] && { loggerx CRITICAL "This script MUST be run with sudo. Exiting."; $term_cmd; }
  [[ "$EUID" -ne 0 ]] && { loggerx WARNING "This script should be run with sudo."; }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DX friendly user prompts.
# Arguments:
#   $1              Quoted prompt. IE: "Proceed?"
#   $2              Default Option. IE: Y
# Outputs:
#   Exit Code matching response.
# Examples:
#   - ask "Proceed?" Y
#   - while ask "Continue? " Y; do echo fail ; done
#   - if ask "$(echo -e 'Whazzzzzzup?'\\\n'1) woot'\\\n'2) rawr'\\\n'3) grrr'\\\n'0) quit'\\\n\\\n'Enter Response')" Range 0-3; then
#         answer="$reply"
#     else
#         answer="no"
#     fi
#     echo $answer
#   - if ask "Confirm: Stuff?" N; then
#         answer="yes"
#     else
#         answer="no"
#     fi
#     echo $answer
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ask() {
    while true; do
        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        elif [ "${2:-}" = "Range" ]; then
            prompt="${3:-}"
            default=0
        else
            prompt="y/n"
            default=
        fi
        read -rp $"$1 [$prompt]: " reply
        if [ -z "$reply" ]; then
            reply=$default
        fi
        case "$reply" in
            Y*|y*|^[1-9][0-9]*$) return 0 ;;
            N*|n*|0*) return 1 ;;
        esac
    done
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEMO: Execute sudo with an rc file.
# Try: __sudo_say_hi
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__sudo_user_do() {
  command sudo /bin/bash --rcfile /usr/local/share/sudo/bashrc -ci "$*"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# True Color Demo
# Cyclomatic Complexity: 10
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# shellcheck disable=SC2183
color_demo_truecolor() {
  # shellcheck disable=SC2183
  local TXT FG COLUMN COLUMNS FILL_L FILL_R R G B
  TXT="This will be a smooth gradient if truecolor is supported."
  COLUMNS="${COLUMNS:-$(tput cols || 120)}"
  FILL_L="$(printf '%*s' "$(((COLUMNS - ${#TXT}) / 2))")"
  FILL_R="$(printf '%*s' "$(((COLUMNS - ${#TXT}) / 2))")"
  [[ $((${#TXT}%2)) -eq 1 ]] && FILL_R="$(printf '%*s' "$((((COLUMNS - ${#TXT}) / 2) +1 ))")"
  FG=$(printf '%s' "$FILL_L"; printf '%s' "$TXT"; printf '%s' "$FILL_R")
  for ((COLUMN=0; COLUMN<COLUMNS; COLUMN++)); do
    # Iterate RGB values                  ; Ensure int stays within range 0..255
    ((R=255-(COLUMN*255/COLUMNS))); ((R<0))&&((R=255-(R+255))); ((R>255))&&((R=R-(R-255)))
    ((G=COLUMN*510/COLUMNS))      ; ((G<0))&&((G=255-(G+255))); ((G>255))&&((G=G-(G-255)))
    ((B=COLUMN*255/COLUMNS))      ; ((B<0))&&((B=255-(B+255))); ((B>255))&&((B=B-(B-255)))
    printf "\e[48;2;%d;%d;%dm" $R $G $B  # BG
    printf "\e[38;2;%d;%d;%d;1m" $R 0 $B # FG Color
    printf "%s\e[0m" "${FG:${COLUMN}:1}" # FG Content
    #printf "%s\e[0m" " "                # No FG Content
  done
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Color Demo
#   Iterates a range of 8-bit colors for demo purposes.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__color_demo() {
  [[ $# -eq 0 ]] && NUM_COLORS=8 || NUM_COLORS="$1"
  [[ $NUM_COLORS -gt 256 ]] && loggerx WARNING "Max colors: 256"
  for i in $(seq 1 "$NUM_COLORS"); do
    printf '\e[48;5;%sm  %03d  \e[0m' "$i" "$i"
    ! (( i % 8 )) && printf '\n'
  done
  (( i % 8 )) && printf '\n'
  unset i
}
alias color_demo_256_bit='__color_demo 256'

color_ansi_demo() {
  local STYLES=(
    "0:None" "1:Bold" "2:Dim" "3:Italic" "4:Underline"
    "5:Blink" "7:Inverse" "8:Hidden" "9:Strike"
  )
  local FGS=(
    "30:Black" "31:Red" "32:Green" "33:Yellow"
    "34:Blue" "35:Magenta" "36:Cyan" "37:White"
    "90:Bright Black" "91:Bright Red" "92:Bright Green" "93:Bright Yellow"
    "94:Bright Blue" "95:Bright Magenta" "96:Bright Cyan" "97:Bright White"
  )
  local BGS=(
    "40:Black" "41:Red" "42:Green" "43:Yellow"
    "44:Blue" "45:Magenta" "46:Cyan" "47:White"
    "100:Bright Black" "101:Bright Red" "102:Bright Green" "103:Bright Yellow"
    "104:Bright Blue" "105:Bright Magenta" "106:Bright Cyan" "107:Bright White"
  )

  printf "\nANSI Attribute / Foreground / Background Demo\n"

  local STYLE FG BG STYLE_CODE STYLE_NAME FG_CODE FG_NAME BG_CODE
  for STYLE in "${STYLES[@]}"; do
    IFS=: read -r STYLE_CODE STYLE_NAME <<< "$STYLE"
    printf "\n[%s] %s\n" "$STYLE_CODE" "$STYLE_NAME"
    for FG in "${FGS[@]}"; do
      IFS=: read -r FG_CODE FG_NAME <<< "$FG"
      printf "  FG %3s %-14s" "$FG_CODE" "$FG_NAME"
      for BG in "${BGS[@]}"; do
        IFS=: read -r BG_CODE _ <<< "$BG"
        printf "\e[%s;%s;%sm %s \e[0m" "$STYLE_CODE" "$FG_CODE" "$BG_CODE" "asdf"
      done
      printf "\e[0m\n"
    done
  done
  printf "\n"
}

# Common colorization helper
# Describes for accessibility & terminal color drift
color_helper() {
  printf '%b\n' "\nColorized Severity (rfc5424 - https://hackmd.io/@njjack/syslogformat)"   ;\
  printf '%b\n' "\e[01;30;41mEMERGENCY\e[0m        \\\e[01;30;41mEMERGENCY\\\e[0m     : 0 - Bold BLACK text, RED background"     ;\
  printf '%b\n' "\e[01;31;43mALERT\e[0m            \\\e[01;31;43mALERT\\\e[0m         : 1 - Bold RED text, YELLOW background"    ;\
  printf '%b\n' "\e[01;97;41mCRITICAL\e[0m         \\\e[01;97;41mCRITICAL\\\e[0m      : 2 - Bold WHITE text, RED background"     ;\
  printf '%b\n' "\e[01;31mERROR\e[0m            \\\e[01;31mERROR\\\e[0m            : 3 - Bold RED text"                       ;\
  printf '%b\n' "\e[01;33mWARNING\e[0m          \\\e[01;33mWARNING\\\e[0m          : 4 - Bold YELLOW text"                    ;\
  printf '%b\n' "\e[01;30;107mNOTICE\e[0m           \\\e[01;30;107mNOTICE\\\e[0m       : 5 - Bold BLACK text, WHITE background"   ;\
  printf '%b\n' "\e[01;39mINFORMATIONAL\e[0m    \\\e[01;39mINFORMATIONAL\\\e[0m    : 6 - Bold WHITE text"                     ;\
  printf '%b\n' "\e[01;97;46mDEBUG\e[0m            \\\e[01;97;46mDEBUG\\\e[0m         : 7 - Bold WHITE text, CYAN background"    ;\
  printf '%b\n' "\e[01;32mSUCCESS\e[0m          \\\e[01;32mSUCCESS\\\e[0m          : 9 - Bold GREEN text (non-rfc5424)\n"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Timer: Start, Stop, Duration
# Usage:
#  timer-start          # Start timer
#  timer-duration       # Get duration in milliseconds (4 decimals)
#  timer-duration ns    # Get duration in nanoseconds
#  timer-duration us    # Get duration in microseconds (3 decimals)
#  timer-duration ms    # Get duration in milliseconds (4 decimals)
#  timer-duration s     # Get duration in seconds (9 decimals)
#  timer-duration 8601  # Get duration in hh:mm:ss.ffff format
#  timer-stop           # Stop timer and get duration in milliseconds (integer)
#  timer-stop <mode>    # Modes: ns, us, ms, s, 8601
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
timer-handler() {
  local mode timer_now_ns timer_duration_s timer_duration_rem_ns
  local timer_duration_us timer_duration_ms
  local days hours minutes seconds
  mode="${1:-ms}"

  if [[ -n ${timer_start_ns+x} ]]; then
    timer_now_ns=$(date +'%s%N')
    timer_duration_ns=$(( timer_now_ns - timer_start_ns ))
  else
    echo "timer not started"
    return 1
  fi

  timer_duration_s=$(( timer_duration_ns / 1000000000 ))
  timer_duration_rem_ns=$(( timer_duration_ns % 1000000000 ))
  timer_duration_us=$(( timer_duration_ns / 1000 ))
  timer_duration_ms=$(( timer_duration_ns / 1000000 ))

  case "$mode" in
    ns)
      timer_output="$timer_duration_ns"
      ;;
    us)
      printf -v timer_output '%d.%03d' "$timer_duration_us" $(( (timer_duration_ns % 1000) ))
      ;;
    ms)
      printf -v timer_output '%d.%04d' "$timer_duration_ms" $(( (timer_duration_ns % 1000000) / 100 ))
      ;;
    s)
      printf -v timer_output '%d.%09d' "$timer_duration_s" "$timer_duration_rem_ns"
      ;;
    8601)
      days=$(( timer_duration_s / 86400 ))
      hours=$(( (timer_duration_s % 86400) / 3600 ))
      minutes=$(( (timer_duration_s % 3600) / 60 ))
      seconds=$(( timer_duration_s % 60 ))
      if (( days > 0 )); then
        printf -v timer_output '%d:%02d:%02d:%02d.%04d' "$days" "$hours" "$minutes" "$seconds" $(( timer_duration_rem_ns / 100000 ))
      else
        printf -v timer_output '%02d:%02d:%02d.%04d' "$hours" "$minutes" "$seconds" $(( timer_duration_rem_ns / 100000 ))
      fi
      ;;
    *)
      loggerx ERROR "Mode must be one of: ns, us, ms, s, 8601"
      return 1
      ;;
  esac
}

timer-start() {
  if [[ -n ${timer_start_ns+x} ]]; then
    loggerx ERROR "Timer already started."
    return 1
  fi
  timer_start_ns=$(date +'%s%N')
}

timer-duration() {
  timer-handler "$1" || return 1
  echo "$timer_output"
}

timer-stop() {
  local mode
  mode="${1:-ms}"

  if [[ "$1" == "-h" ]]; then
    echo "Returns duration in milliseconds (integer) by default. Numeric modes include units. Modes: ns, us, ms, s, 8601."
    return 1
  fi

  timer-handler "$mode" || return 1
  case "$mode" in
    ns)   echo "${timer_output} ns" ;;
    us)   echo "${timer_output} us" ;;
    ms)   [[ -z "$1" ]] && echo "${timer_output%%.*} ms" || echo "${timer_output} ms" ;;
    s)    echo "${timer_output} s" ;;
    8601) echo "$timer_output" ;;
  esac
  unset timer_start_ns
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Continue in... (countdown helper)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__continue_in() {
  count=$1
  for i in $(seq 1 "$count"); do
    printf "\r%s" "Continuing in $(( (count+1) - i ))..."
    sleep 1
  done
  echo ''
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Detect processes that are maintaining many open files
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
detect_file_hogs() {
  local tmp line open_files pid proc_name proc_hard_limit output_lines
  output_lines=10
  [[ $1 =~ ^[0-9]+$ ]] && output_lines=$1
  tmp=$(mktemp)
  echo PID OPEN_FILES PROC_HARD_LIMIT PROC-NAME >> "$tmp"
  while read -r line; do
    open_files=$(echo "$line" | cut -f1 -d' ')
    pid=$(echo "$line" | cut -f2 -d' ')
    proc_name=$(ps -p "$pid" -o comm= 2>/dev/null)
    proc_hard_limit=$(awk '/files/ {print $5; exit}' "/proc/$pid/limits" 2>/dev/null || echo -n "")
    echo "$pid $open_files $proc_hard_limit $proc_name" >> "$tmp"
  done <<< "$(lsof 2>/dev/null | awk '{print $2}' | sort | uniq -c | sort -rn | head -n "$output_lines")"
  column -t "$tmp"
  rm -f "$tmp"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Daily Notes
# Usage:
#   Add entry:
#     dnote Did some thing
#   Show todays notes
#     dnote
#   Show yesterdays notes
#     dnote -y
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
daily_notes() {
  local DAILY_NOTES_FILE DATE
  if [[ $# -eq 0 ]]; then
    if [[ $(awk "/## ${DATE}/,/^$/" "$DAILY_NOTES_FILE" | wc -l) -eq 0 ]]; then
      printf '%s\n' 'No entries yet for today. Here are yesterdays notes.'
      awk "/## $(date --utc -d "yesterday" +'%Y-%m-%d')/,/^$/" "$DAILY_NOTES_FILE"
      return
    else
      awk "/## $(date --utc +'%Y-%m-%d')/,/^$/" "$DAILY_NOTES_FILE"
      return
    fi
  fi
  if [[ $1 == '-y' ]]; then
    awk "/## $(date --utc -d "yesterday" +'%Y-%m-%d')/,/^$/" "$DAILY_NOTES_FILE"
    return
  fi
  DAILY_NOTES_FILE="/home/$USER/DailyNotes.md"
  DATE=$(date --utc +'%Y-%m-%d')
  [[ ! -f "$DAILY_NOTES_FILE" ]] && printf '%s\n' '# Daily Notes' > "$DAILY_NOTES_FILE"
  if ! grep -q "$DATE"<<<"$(head -n 20 "$DAILY_NOTES_FILE")"; then
    sed -i "1 a \#\# $DATE\n" "$DAILY_NOTES_FILE"
    sed -ie "0,/^$/ s/^$/- $*\n/" "$DAILY_NOTES_FILE"
  else
    sed -ie "0,/^$/ s/^$/- $*\n/" "$DAILY_NOTES_FILE"
  fi
}
alias dnote='daily_notes'

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Misc : TUX (Terminal User Experience)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
alias urc='source ~/.bashrc'                                # Update rc in current terminal
alias c='clear'                                             # keystrokes -- the clicky killer
alias e='exit'                                              # Exit terminal -- engage LAZY MODE
command -v batcat >/dev/null 2>&1 && alias bat='batcat'     # Bat alias for Debian-based systems
                                                              # NOTE pager behavior of batcat. Use --paging=never (or -P) to disable.
command -v bat >/dev/null 2>&1 && alias cat='bat -p'        # Cat alias to use bat if available
batcat_langcolor_help() {
  printf "%s\n" "Loop though supported languages to discover which may work for your use case."
  printf "%s\n" "This example shows iptables rules colorized."
  # shellcheck disable=2016
  printf "%s\n" '
    for lang in $(cat --list-languages | cut -d: -f2- | awk -F'\'','\'' '\''{print $1}'\''); do
      printSectionHeader "$lang"
      iptables -S | cat -l "$lang"
      sleep 2
    done' | cat -P -l bash --paging=never --color=always 2>/dev/null
}

alias less='less -R'                                        # Colorize less
command -v eza >/dev/null 2>&1 && alias ls='eza --icons --group-directories-first'
alias l1='ls -1'
alias watch='watch --color'                                 # Colorize watch
alias ls='eza                             \
            --icons                       \
            --group                       \
            --group-directories-first     \
            --time-style '+%FT%TZ''            # Show long ISO time format

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Clipboard helpers
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
alias clipc="xclip -selection c"
alias clipp="xclip -selection c -o"
alias clipv="xclip | less"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Tmux Control
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
alias tmuxn='tmux new-session -s'
alias tmuxk='tmux kill-session -t'
alias tmuxa='tmux attach-session -t'
alias tmuxl='tmux ls'
tmuxwhereami() {
  if [[ -n $TMUX ]]; then
    printf '%b\n' "\e[01;39mINFO\e[0m: Current TMUX session: $(tmux display-message -p '#S')"
  else
    printf '%b\n' "\e[01;31mERROR\e[0m: Not in a TMUX session."
  fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Show the age of a file.
# Outputs
#   - The age of a file in d,h,m,s.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file_age() {
  [[ ! -f $1 ]] && return 1
  local _file b s
  _file="$1"
  b="$(date --date="$(stat "$_file" | awk '/Birth:/ {print $2"T"$3}' | cut -d. -f1)" +%s)"
  s=$(($(date +%s) - b))
  printf '%dd,%dh,%dm,%ds\n' \
          $((s/86400))       \
          $((s%86400/3600))  \
          $((s%3600/60))     \
          $((s%60))
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# List 10 largest directories for a given path.
# Arguments:
#   - PATH
# Outputs:
#   - List of 10 largest directories in descending order
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
find-large-dirs() {
  if [[ $# -ne 1 || $1 == "-h" ]]; then
    loggerx ERROR "Exactly one argument required: path (eg: / or /tmp/)"
      return 1
  fi
  du -hsx "$1*" 2> >(grep -v '^du: cannot \(access\|read\)' >&2) | sort -rh | head -10
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Updates libffmpeg.so
# Notes:
#   - This is handled by the system updater now.
# Cyclomatic Complexity: 7
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
update-ffmpeg() {
    local INSTALL_DIRS=( '/usr/local/bin/ffmpeg' '/usr/lib/chromium-browser' '/usr/lib/x86_64-linux-gnu/opera')
    local FORCE
    [[ "$1" == "-f" ]] && FORCE='true'
    for dir in "${INSTALL_DIRS[@]}"; do
      [[ ! -f "$dir/libffmpeg.so" ]] && local FORCE='true'
      if [[ ! -d "$dir" ]]; then
        et
        sudo mkdir -p "$dir"
        rc 0 KILL
        TASK="Create $dir"; rc 0
      fi
    done
    TASK="Detect installed version"
    local LOCAL_VERSION OS_TYPE LATEST_VERSION ASSET TEMP_DIR
    LOCAL_VERSION="$(< "${INSTALL_DIRS[0]}/ffmpeg.version")"; rc 0
    TASK="Detect latest release version"
    LATEST_VERSION=$(git-latest-release-version nwjs-ffmpeg-prebuilt nwjs-ffmpeg-prebuilt); rc 0
    if [[ "$LOCAL_VERSION" == "$LATEST_VERSION" ]] && [[ "$FORCE" != 'true' ]]; then
      loggerx INFO "Latest version of ffmpeg ($LATEST_VERSION) is already installed."
      return 0
    fi
    TASK="Update from $LOCAL_VERSION to $LATEST_VERSION"; et
    OS_TYPE=$(_check_os_type)
    ASSET=$(git-latest-release-assets nwjs-ffmpeg-prebuilt nwjs-ffmpeg-prebuilt \
            | grep -i "$OS_TYPE" \
            | grep -i "$ARCH"); rc 0 KILL
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR" || true
    TASK="Retrieve $ASSET"; et
    wget -q "https://github.com/nwjs-ffmpeg-prebuilt/nwjs-ffmpeg-prebuilt/releases/download/${LATEST_VERSION}/${ASSET}"; rc 0 KILL
    TASK="Unpack $ASSET"; et
    unzip -q "$ASSET"; rc 0 KILL
    for dir in "${INSTALL_DIRS[@]}"; do
      TASK="Install libffmpeg.so to $dir"; et
      sudo cp libffmpeg.so "$dir"; rc 0
      TASK="Update ${dir}/ffmpeg.version"; et
      sudo rm "${dir}/ffmpeg.version";
      echo "$LATEST_VERSION" | sudo tee "${dir}/ffmpeg.version" > /dev/null; rc 0
    done
    cd - >/dev/null 2>&1 || true
    TASK="Update ffmpeg from $LOCAL_VERSION to $LATEST_VERSION"; rc 0
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Convert spaces to tabs.
# Arguments:
#   2,4        The size of the space-tab to convert
#   FILE       The file to handle.
#              Not compatible with STRINGS
#   STRINGS    The strings to handle.
#              Not compatible with FILE
# Outputs:
#   The converted text (to stdout)
# Usage:
#    spaces_to_tabs 4 File > F.tmp; mv F.tmp File
#    WARNING: Don't truncate our original file.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# shellcheck disable=2001
spaces_to_tabs() {
  if [[ $1 -ne 2 ]] && [[ $1 -ne 4 ]]; then
    loggerx ERROR "First argument must be one of: (2,4)"
    return 1
  fi
  if [[ ! -f $2 ]]; then
    [[ $1 -eq 4 ]] && sed 's/^\s\s\s\s/\t/g'<<<"${@:2}"
    [[ $1 -eq 2 ]] && sed 's/^\s\s/\t/g'<<<"${@:2}"
  else
    [[ $1 -eq 4 ]] && sed 's/^\s\s\s\s/\t/g' "$2"
    [[ $1 -eq 2 ]] && sed 's/^\s\s/\t/g' "$2"
  fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Convert all string characters to lower, or upper.
# Usage:
#   Pipe to function. IE: echo HI | lower
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
lower() { tr '[:upper:]' '[:lower:]' ; }
upper() { tr '[:lower:]' '[:upper:]' ; }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Escape string for bash usage.
# Usage:
#   Pipe to function. IE: escape_string <<< "Hello World!"
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
escape_string() { sed -e 's/[^a-zA-Z0-9,._+@%/-]/\\&/g; 1{$s/^$/""/}; 1!s/^/"/; $!s/$/"/'; }

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Prints a basic title.
# Arguments:
#   STRING(s)            Title Text
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# shellcheck disable=2183,2059
printTitle() {
  local txt
  txt="$*"
  printf '%*s' "$((COLUMNS-(COLUMNS-$(wc -c<<<"$txt")-3)))" | tr ' ' \#
  printf "\n\e[01m# ${txt} #\e[0m"
  printf '\n%*s' "$((COLUMNS-(COLUMNS-$(wc -c<<<"$txt")-3)))" | tr ' ' \#
  printf '\n'
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Prints a basic section header.
# Arguments:
#   STRING(s)            Header Text
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
printSectionHeader_v1 () {
    local txt
    txt="$*"
    printf "\n\e[01m%s\e[0m" "$txt"
    # shellcheck disable=2183
    printf '\n%*s' "$(tr -d '\n'<<<"$txt" | wc -c)" | tr ' ' -
    printf '\n'
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Prints a basic section header (v2).
# Arguments:
#   STRING(s)            Header Text
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
printSectionHeader ()
{
    local txt wrap
    txt="$*"
    # shellcheck disable=2183
    wrap="$(printf '%*s' "$(tr -d '\n'<<<"$txt" | wc -c)" | tr ' ' \~)"
    printf "\n"
    printf "\e[01m%s\e[0m\n" "# $wrap"
    printf "\e[01m%s\e[0m\n" "# $txt"
    printf "\e[01m%s\e[0m\n" "# $wrap"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Figlet Favs
# Arguments:
#   STRING(s)            Text to render
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
figlet_fav_ansi_shadow() {
  /usr/bin/figlet -t -f ANSI_Shadow "$*"  | sed '/^[[:space:]]*$/d'
}
alias printFigletHeader='figlet_fav_ansi_shadow'

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Prints a fancy section header.
# See help menu for details.
# WARN: Cyclomatic Complexity = 21
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test with:
#   for opt in " " "-e"; do for i in 0 $(($(tput cols) / 8)) $(($(tput cols) / 8 +1)) $(($(tput cols) / 2)) $(($(tput cols) +10)); do for t in "H" "XX"; do printFancyHeader -w $i -g -t "$t" "$opt" ; done; done; done
#   for opt in " " "-e"; do printFancyHeader -t "$(printf '%*s' "$(( $(tput cols) +10 ))" | sed "s/ /X/g")" "$opt"; done
function printFancyHeader() {
  help() {
    cat << EOF
Print a fancy heading.
Use: ${0##*/} [-w <int>] [-f <bool>] [-v <char>] [-h <char>] [-i <char>] [-t <string(s)>]
    -w    INT     The width of the header        Default: Full Screen
                                                 Minimum: Title + 8
                                                 Note: If odd, this program will subtract 1.
    -v    CHAR    Vertical border character      Default: \#
    -h    CHAR    Horizontal border character    Default: =
    -i    CHAR    Internal fill character        Default: -
    -t    TITLE   "Title Text" (double quoted)   Default: Hello World!
    -f            Fill                           Default: true
    -g            Gutters                        Default: false
    -e            Emoji Mode                     Default: Disabled
                                                 Fullwidth/thick (DOUBLE SPACE) emoji's only.
                                                 Auto-transforms:
                                                   [a-zA-Z0-9]( :;<>?!#$&()*+-_~|{}@[]^)
                                                   Some characters require escapes(\).
                                                   🛸 https://www.amp-what.com/unicode/search/fullwidth 🛸
NOTE: Some characters require escaping.
Examples:
    printFancyHeader -w 20 -t Cool Title
    printFancyHeader -w 60 -v \* -h \~ -i . -t "Cool Title" -f false
    printFancyHeader -v 🐵 -h 🛻 -i 🌭 -t "Monkey Business" -e -g -w $(($(tput cols)/2))
    printFancyHeader -t "[ Hello World ]" -e -w 44
EOF
  }

  visual_width() {
    local str width char char_bytes
    str="$1"
    if width=$(echo -n "$str" | wc -L 2>/dev/null); then
      echo "$width"
      return
    fi
    local width=0
    local i
    for ((i=0; i<${#str}; i++)); do
      char="${str:$i:1}"
      char_bytes=$(echo -n "$char" | wc -c)
      if (( char_bytes > 1 )); then # Emoji
        ((width += 2))
      else # ASCII
        ((width += 1))
      fi
    done
    echo "$width"
  }

  repeat_to_width() {
    local char target_width current_width result char_width count i max_iterations iterations space_char
    char="$1"
    target_width="$2"
    space_char="$3"
    result=""
    char_width=$(visual_width "$space_char")

    (( char_width == 0 )) && char_width=1
    if (( target_width <= 0 )); then
      echo ""
      return
    fi

    (( count = target_width / char_width ))
    for ((i=0; i<count; i++)); do
      result+="$char"
    done

    current_width=$(visual_width "$result")
    max_iterations=10
    iterations=0
    while (( current_width < target_width && iterations < max_iterations )); do
      result+="$space_char"
      current_width=$(visual_width "$result")
      ((iterations++))
    done

    while (( current_width > target_width && ${#result} > 0 )); do
      result="${result::-$char_width}"
      current_width=$(visual_width "$result")
    done

    echo "$result"
  }
  # Emoji Character Dictionary
  declare -rA e_c=(
    ["a"]="ａ" ["b"]="ｂ" ["c"]="ｃ" ["d"]="ｄ" ["e"]="ｅ" ["f"]="ｆ" ["g"]="ｇ"
    ["h"]="ｈ" ["i"]="ｉ" ["j"]="ｊ" ["k"]="ｋ" ["l"]="ｌ" ["m"]="ｍ"
    ["n"]="ｎ" ["o"]="ｏ" ["p"]="ｐ" ["q"]="ｑ" ["r"]="ｒ" ["s"]="ｓ" ["t"]="ｔ"
    ["u"]="ｕ" ["v"]="ｖ" ["w"]="ｗ" ["x"]="ｘ" ["y"]="ｙ" ["z"]="ｚ"
    ["A"]="Ａ" ["B"]="Ｂ" ["C"]="Ｃ" ["D"]="Ｄ" ["E"]="Ｅ" ["F"]="Ｆ" ["G"]="Ｇ"
    ["H"]="Ｈ" ["I"]="Ｉ" ["J"]="Ｊ" ["K"]="Ｋ" ["L"]="Ｌ" ["M"]="Ｍ"
    ["N"]="Ｎ" ["O"]="Ｏ" ["P"]="Ｐ" ["Q"]="Ｑ" ["R"]="Ｒ" ["S"]="Ｓ" ["T"]="Ｔ"
    ["U"]="Ｕ" ["V"]="Ｖ" ["W"]="Ｗ" ["X"]="Ｘ" ["Y"]="Ｙ" ["Z"]="Ｚ"
    ["0"]="０" ["1"]="１" ["2"]="２" ["3"]="３" ["4"]="４"
    ["5"]="５" ["6"]="６" ["7"]="７" ["8"]="８" ["9"]="９"
    [" "]="  " [":"]="：" [";"]="；" ["<"]="＜" [">"]="＞" ["?"]="？" ["!"]="！"
    ["#"]="＃" ["$"]="＄" ["&"]="＆" ["("]="（" [")"]="）" ["*"]="＊" ["-"]="－"
    ["+"]="＋" ["_"]="＿" ["~"]="～" ["|"]="｜" ["{"]="｛" ["}"]="｝" ["@"]="＠"
    ["["]="［" ["]"]="］" ["^"]="＾" ["."]=". "
  )
  local txt width min_width max_width target_width \
        vert_c horz_c intr_c ogut_c igut_c space_c \
        vert_width ogut_width igut_width space_width \
        fill gut emoji \
        title_text title_visual_width \
        border_width content_width fill_width_l fill_width_r \
        horz_border_fill intr_fill intr_half_fill_l intr_half_fill_r \
        c char_width padding max_title_width truncated current_width

  txt=()
  OPTIND=1
  while getopts "w:v:h:i:fget:" OPT; do
    case "$OPT" in
      w) width="$OPTARG"                              ;;
      v) vert_c="$OPTARG"                             ;;
      h) horz_c="$OPTARG"                             ;;
      i) intr_c="$OPTARG"                             ;;
      f) fill="false"                                 ;;
      g) gut="true"                                   ;;
      e) emoji="true"                                 ;;
      t) set -f
         IFS=' '
         # shellcheck disable=2206
         txt=($OPTARG)                                ;;
      :) echo "ERROR: -$OPTARG requires an argument."
         help; return 1                               ;;
      *) help; return 1                               ;;
    esac
  done
  shift $((OPTIND-1))
  set +f

  max_width=$(tput cols)                                                        # Maximum box width (terminal width)
  width="${width:-$max_width}"                                                  # Title box width

  # Title Text Control
  # shellcheck disable=2206
  txt=(${txt[@]:-Hello World\!})                                                # Title text
  if [[ "$emoji" == "true" ]]; then                                             # Emoji Transform
    c="${txt[*]}"
    # shellcheck disable=2207
    txt=($(for ((i=0; i<${#c}; i++)); do
      printf "%s" "${e_c["${c:$i:1}"]}"
    done))
  fi

  title_text="${txt[*]}"
  title_visual_width=$(visual_width "$title_text")

  if [[ "$emoji" != "true" ]]; then                                             # Default characters
    [[ "$fill" == "false" ]] && intr_c=' '
    vert_c="${vert_c:-#}"
    horz_c="${horz_c:-=}"
    intr_c="${intr_c:--}"
    space_c=" "
    ogut_c=" "
    igut_c=" "
  else
    [[ "$fill" == "false" ]] && intr_c="${e_c[" "]}"
    vert_c="${vert_c:-🛸}"
    horz_c="${horz_c:-🛸}"
    intr_c="${intr_c:-👽}"
    space_c="${e_c[" "]}"
    ogut_c="${e_c[" "]}"
    igut_c="${e_c[" "]}"
  fi

  if [[ "$gut" == "false" ]]; then                                              # Gutter
    ogut_c="$horz_c"
    igut_c="$intr_c"
  fi

  vert_width=$(visual_width "$vert_c")                                          # Element widths
  ogut_width=$(visual_width "$ogut_c")
  igut_width=$(visual_width "$igut_c")
  space_width=$(visual_width "$space_c")

  local min_fill_char_width                                                     # Minimum fill
  min_fill_char_width=$(visual_width "$intr_c")
  padding=$((2 * vert_width + 2 * igut_width + 2 * space_width + 2 * min_fill_char_width))

  max_title_width=$((max_width - padding - 3))                                  # 3 for ellipses. Truncate if too long
  if (( title_visual_width > max_title_width )); then
    # Truncate and add ellipses
    truncated=""
    current_width=0
    for ((i=0; i<${#title_text}; i++)); do
      char="${title_text:$i:1}"
      char_width=$(visual_width "$char")
      if (( current_width + char_width + 3 > max_title_width )); then
        break
      fi
      truncated+="$char"
      ((current_width += char_width))
    done
    [[ "$emoji" == "true" ]] || title_text="${truncated}..."
    [[ "$emoji" == "true" ]] && title_text="${truncated}. . . "
    title_visual_width=$(visual_width "$title_text")
  fi

  min_width=$((title_visual_width + padding))                                   # Box Width
  (( width < min_width )) && width=$min_width
  (( width > max_width )) && width=$max_width
  border_width=$((width - 2 * vert_width - 2 * ogut_width))                     # Border Width
  content_width=$((width - 2 * vert_width - 2 * igut_width))                    # Content row
  title_with_spaces_width=$((2 * space_width + title_visual_width))             # Title row
  total_fill_width=$((content_width - title_with_spaces_width))

  # Ensure minimum width
  if (( total_fill_width < 0 )); then
    content_width=$((title_with_spaces_width + 2))
    width=$((content_width + 2 * vert_width + 2 * igut_width))
    border_width=$((width - 2 * vert_width - 2 * ogut_width))
    total_fill_width=2
  fi

  fill_width_l=$((total_fill_width / 2))
  fill_width_r=$((total_fill_width - fill_width_l)) # Observes odd widths

  # Ensure minimum fill of 1
  (( fill_width_l < 1 )) && fill_width_l=1
  (( fill_width_r < 1 )) && fill_width_r=1
  # Width offset for emoji mode
  if [[ "$emoji" == "true" ]]; then
    (( content_width%2 )) || (( fill_width_r++ ))
    if (( content_width > min_width )); then
      (( fill_width_l > 2 )) && (( fill_width_l-- ))
      (( fill_width_l > 2 )) && (( fill_width_r++ ))
    fi
  fi
  horz_border_fill=$(repeat_to_width "$horz_c" "$border_width" "$space_c")
  intr_fill=$(repeat_to_width "$intr_c" "$content_width" "$space_c")
  intr_half_fill_l=$(repeat_to_width "$intr_c" "$fill_width_l" "$space_c")
  intr_half_fill_r=$(repeat_to_width "$intr_c" "$fill_width_r" "$space_c")

  printf '%s\n' "${vert_c}${ogut_c}${horz_border_fill}${ogut_c}${vert_c}"
  printf '%s\n' "${vert_c}${igut_c}${intr_fill}${igut_c}${vert_c}"
  printf '%s' "${vert_c}${igut_c}${intr_half_fill_l}"
  printf "%b" "\e[01;39m${space_c}${title_text}${space_c}\e[0m"
  printf '%s\n' "${intr_half_fill_r}${igut_c}${vert_c}"
  printf '%s\n' "${vert_c}${igut_c}${intr_fill}${igut_c}${vert_c}"
  printf '%s\n' "${vert_c}${ogut_c}${horz_border_fill}${ogut_c}${vert_c}"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Data conversion helpers.
# Arguments:
#   Numeric Value        Amount of bits or bytes
# Outputs:
#   Converted Value      In bytes or bits
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_bits_to_bytes() {
  if [[ -n "$1" ]] && [[ "$1" =~ ^[0-9]+$ ]]; then
      result=$(( $1 / 8 ))
      [[ $(( $1 % 8 )) -ne 0 ]] && result=$(( result + 1 ))
      echo $result
  else
      loggerx ERROR "First argument must be an integer."
      return 1
  fi
}
_bytes_to_bits() {
  if [[ -n "$1" ]] && [[ "$1" =~ ^[0-9]+$ ]]; then
      echo $(( $1 * 8 ))
  else
      loggerx ERROR "First argument must be an integer."
      return 1
  fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Convert bits to human readable format.
# Arguments:
#   bits           IE: '10000' will return 10.00 Kb
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# shellcheck disable=2120
bitsToHumanReadableBits() {
  local input i d s S
  if test -n "$1"; then
      input="$*"
  elif test ! -t 0; then
      input="$(</dev/stdin)"
  fi
  i=${input:-0} d="" s=0 S=("bits" "Kb" "Mib" "Gib" "Tib" "Pib" "Eib" "Yib" "Zib")
  while ((i > 1000 && s < ${#S[@]}-1)); do
      printf -v d ".%02d" $((i % 1000 * 100 / 1000))
      i=$((i / 1000))
      s=$((s + 1))
  done
  echo "$i$d ${S[$s]}"
}
alias b2H='bitsToHumanReadableBits'

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Convert bytes to human readable format automatically.
# Arguments:
#   bytes           IE: '10240' will return 10.00 KB
# Cyclomatic Complexity: 6
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# shellcheck disable=2120
bytesToHumanReadable() {
  local input i d s S
  if [[ -n "$1" ]]; then
      input="$*"
  elif [[ ! -t 0 ]]; then
      input="$(</dev/stdin)"
  fi
  i=${input:-0} d="" s=0 S=("Bytes" "KB" "MiB" "GiB" "TiB" "PiB" "EiB" "YiB" "ZiB")
  while ((i > 1024 && s < ${#S[@]}-1)); do
      printf -v d ".%02d" $((i % 1024 * 100 / 1024))
      i=$((i / 1024))
      s=$((s + 1))
  done
  echo "$i$d ${S[$s]}"
}
alias B2H='bytesToHumanReadable'

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Convert bits or bytes to human readable format in the
# specified units.
#
# Arguments:
#   input_units              Input Units
#                              "bits"  "Kb" "Mib" "Gib" "Tib" "Pib" "Eib" "Yib" "Zib"
#                              "Bytes" "KB" "MiB" "GiB" "TiB" "PiB" "EiB" "YiB" "ZiB
#   value                    Amount of units
#   output_units (optional)  Output unit ('bits' or 'bytes')
# Outputs:
#   Converted value
# Notes:
#   - Uses 1000 base for bits, 1024 base for bytes.
#   - Rounds to 2 decimal places.
#   - If output_units is not specified, will return in
#     optimal human readable format.
# Cyclomatic Complexity: 10
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
data_unit_converter() {
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
      cat << EOF
Convert bits or bytes to human readable format.
    Usage: data_unit_converter <input_units> <value> <output_units>

Examples:
  data_unit_converter bits 10000 bytes
  data_unit_converter bytes 10240 bits
EOF
      return 0
    fi
    local input_units value output_units i d s S multiplier
    if [[ -n "$1" ]] && [[ "$1" =~ ^(bits|bytes)$ ]]; then
        input_units="$1"
    else
        loggerx ERROR "First argument must be one of: bits, bytes"
        return 1
    fi
    if [[ -n "$2" ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
        value="$2"
    else
        loggerx ERROR "Second argument must be a numeric value."
        return 1
    fi
    if [[ -n "$3" ]] && [[ "$3" =~ ^(bits|bytes)$ ]]; then
        output_units="$3"
    else
        loggerx ERROR "Third argument must be one of: bits, bytes"
        return 1
    fi
    i=${value:-0} d="" s=0
    if [[ "$input_units" == "bits" ]]; then
      S=("bits" "Kb" "Mib" "Gib" "Tib" "Pib" "Eib" "Yib" "Zib")
      multiplier=1000
    else
      S=("Bytes" "KB" "MiB" "GiB" "TiB" "PiB" "EiB" "YiB" "ZiB")
      multiplier=1024
    fi
    while ((i > multiplier && s < ${#S[@]}-1)); do
      printf -v d ".%02d" $((i % multiplier * 100 / multiplier))
      i=$((i / multiplier))
      s=$((s + 1))
    done
    # Convert to desired output units if needed
    if [[ "$input_units" != "$output_units" ]]; then
      if [[ "$output_units" == "bits" ]]; then
        i=$((i * 8))
      else
        i=$((i / 8))
      fi
      d=""
      s=0
      if [[ "$output_units" == "bits" ]]; then
        S=("bits" "Kb" "Mib" "Gib" "Tib" "Pib" "Eib" "Yib" "Zib")
        multiplier=1000
      else
        S=("Bytes" "KB" "MiB" "GiB" "TiB" "PiB" "EiB" "YiB" "ZiB")
        multiplier=1024
      fi
      while ((i > multiplier && s < ${#S[@]}-1)); do
        printf -v d ".%02d" $((i % multiplier * 100 / multiplier))
        i=$((i / multiplier))
        s=$((s + 1))
      done
    fi
    echo "$i$d ${S[$s]}"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Convert bytes to human readable format in a unit defined
#   by user input.
# Arguments:
#   bytes           IE: '10240'
#   unit            IE: "KB" "MiB" "GiB" "TiB" "PiB" "EiB" "YiB" "ZiB" "MB" "GB" "TB" "PB" "EB" "YB" "ZB"
# Outputs:
#   Converted value
# Cyclomatic Complexity: 6
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
bytesTo() {
    local input unit i d s decimal_S decimal_S_multiplier binary_S binary_S_multiplier index system multiplier
    binary_S=("Bytes" "KiB" "MiB" "GiB" "TiB" "PiB" "EiB" "YiB" "ZiB")
    binary_S_multiplier=(0 1024 1048576 1073741824 1099511627776 1125899906842624 1152921504606846976 1180591620717411303424)
    decimal_S=("Bytes" "KB" "MB" "GB" "TB" "PB" "EB" "YB" "ZB")
    decimal_S_multiplier=(0 1000 1000000 1000000000 1000000000000 1000000000000000 1000000000000000000 1000000000000000000000)
    if [[ -n "$1" ]] && [[ "$1" =~ ^[0-9]+$ ]]; then
        bytes="$1"
    elif [[ ! -t 0 ]]; then
        bytes="$(</dev/stdin)"
    fi
    if [[ -n "$2" ]] && [[ " ${binary_S[*]} " == *" $2 "* ]]; then
        unit="$2"
    elif [[ -n "$2" ]] && [[ " ${decimal_S[*]} " == *" $2 "* ]]; then
        unit="$2"
    elif [[ ! "$1" =~ ^[0-9]+$ ]] && [[ -z "$unit" ]]; then
        unit="$1"
    elif [[ -z "$unit" ]]; then
        unit="Bytes"
    fi
    i=${bytes:-0}
    d=""
    s=0
    if [[ " ${binary_S[*]} " == *" $unit "* ]]; then
      S=("${binary_S[@]}")
      system="binary"
    elif [[ " ${decimal_S[*]} " == *" $unit "* ]]; then
      S=("${decimal_S[@]}")
      system="decimal"
    else
      loggerx ERROR "Unit must be one of: ${binary_S[*]}, ${decimal_S[*]}"
      return 1
    fi
    for index in "${!S[@]}"; do
      if [[ "${S[$index]}" == "$unit" ]]; then
        s=$index
        if [[ "$system" == "binary" ]]; then
          multiplier=${binary_S_multiplier[$index]}
        else
          multiplier=${decimal_S_multiplier[$index]}
        fi
        i=$(( i / multiplier ))
        break
      fi
    done
    echo "$i$d ${S[$s]}"
}
