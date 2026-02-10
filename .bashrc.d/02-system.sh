# shellcheck shell=bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FILE                : 02-system.sh
# DESCRIPTION         : System-related functions and aliases
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
# Misc : System
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
alias __system_update='source <(curl -s https://gist.githubusercontent.com/AlexAtkinson/27b12f4dfda31b1b74fcab3fc9a6d192/raw/init.sh)'
alias __update_system='__system_update'                                            # Alias for __system_update
alias __sysctl_update='sudo sysctl --system'                                       # Apply _all_ sysctl config changes
alias __reload_daemons='sudo systemctl daemon-reload'                              # Reload systemd manager configuration
alias __list_services='systemctl list-units --type=service --all'                  # List all services
alias __list_active_services='systemctl list-units --type=service --state=active'  # List active services
alias __list_failed_services='systemctl --failed --type=service'                   # List failed services
alias __journalctl_follow='sudo journalctl -f --no-pager'                          # Follow journalctl logs
alias __journalctl_boot='sudo journalctl -b --no-pager'                            # Show journalctl logs for current boot
alias __journalctl_boot_all='sudo journalctl -b -1 --no-pager'                     # Show journalctl logs for previous boot
alias __list_timers='systemctl list-timers --all'                                  # List all systemd timers
alias __check_disk_health='sudo smartctl -a /dev/sda'                              # Check disk health (adjust /dev/sda as needed)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Update .bashrc_user_gist from remote gist
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__update_bashrc() {
  local LOCAL_FILE REMOTE_FILE_URL
  LOCAL_FILE="$HOME/.bashrc_user_gist"
  REMOTE_FILE_URL="https://gist.githubusercontent.com/AlexAtkinson/bc765a0c143ab2bba69a738955d90abd/raw/.bashrc"
  TASK="Retrieve remote .bashrc_user_gist"
  curl -sS "$REMOTE_FILE_URL" -o "$LOCAL_FILE.new"; rc 0 KILL
  TASK="Update local .bashrc_user_gist"
  mv "$LOCAL_FILE.new" "$LOCAL_FILE"; rc 0 KILL
  loggerx SUCCESS ".bashrc_user_gist updated. Run 'source ~/.bashrc_user_gist', or 'urc' to apply."
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Kill processes with a command matching input string(s).
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
alias __kill_by_name='pkill -f'                                              # Kill process by name
__kill_by_command_match() {
  [[ $# -eq 0 ]] && { echo "Usage: __kill_by_command_match <command match>"; return 1; }
  pgrep -u ${UID} "$@" | \
  grep post-commit | \
  grep -v grep | \
  awk '{print $2}' | \
  xargs kill -9 --
}