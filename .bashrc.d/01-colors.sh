# shellcheck shell=bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FILE                : 01-colors.sh
# DESCRIPTION         : ANSI color and style variable definitions
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
# Color Helper Vars
# Notes:
#   - Foreground assumed -- BG denotes Background.
#   - ANSI Code Implementation
#     - Codes are not positional
#     - Codes may be layered
#     - Not all codes are compatible
#     - 1-9 turn ON a style, 21-29 turn OFF a style
#   - ASCII Extras
#     - 10-19: Font
# WARNING:
#   - User terminal display settings affect these.
# Usage:
#   - echo -e "${_C_BL}${_C_YELLOW}${_C_B}${_C_BG_CYAN}HELLO${_C}"
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_C='\e[0m'                   # Reset
_C_RESET='\e[0m'
# Styles ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_C_B='\e[1m'                 # Bold
_C_D='\e[2m'                 # Dim
_C_I='\e[3m'                 # Italic
_C_U='\e[4m'                 # Underline
_C_BL='\e[5m'                # Blink
_C_BLS='\e[5m'               # Blink Slow
_C_BLF='\e[6m'               # Blink Fast                  Support varies by OS
_C_REV='\e[7m'               # Reverse FG/BG Colors
_C_CON='\e[8m'               # Conceal                     Support varies by OS
_C_ST='\e[9m'                # Strike-through
# Note: 11-20 are alternative fonts.
_C_N_B='\e[21m'              # NOT Bold
_C_N_D='\e[22m'              # NOT Dim
_C_N_I='\e[23m'              # NOT Italic
_C_N_U='\e[24m'              # NOT Underline
_C_N_BL='\e[25m'             # NOT Blink
_C_N_BLS='\e[25m'            # NOT Blink Slow
_C_N_BLF='\e[26m'            # NOT Blink Fast              Support varies by OS
_C_N_REV='\e[27m'            # NOT Reverse FG/BG Colors
_C_N_CON='\e[28m'            # NOT Conceal                 Support varies by OS
_C_N_ST='\e[29m'             # NOT Strike-through          Support varies by OS
# Colors ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_C_BLACK='\e[30m'
_C_RED='\e[31m'
_C_GREEN='\e[32m'
_C_YELLOW='\e[33m'
_C_BLUE='\e[34m'
_C_PURPLE='\e[35m'
_C_CYAN='\e[36m'
_C_WHITE='\e[37m'
_C_256='\e[38;5;164m'        # 38;2;<ascii code>
_C_RGB='\e[38;2;3;252;7m'    # 38;2;r;g;b        # RGB support only in true-color terminals.
# Background ~~~~~~~~~~~~~~~~~~~~~~~~~~~
_C_BG='\e[40m'
_C_BG_BLACK='\e[40m'
_C_BG_RED='\e[41m'
_C_BG_GREEN='\e[42m'
_C_BG_YELLOW='\e[43m'
_C_BG_BLUE='\e[44m'
_C_BG_PURPLE='\e[45m'
_C_BG_CYAN='\e[46m'
_C_BG_WHITE='\e[47m'
_C_BG_256='\e[48;164m'       # 48;2;<ascii code>
_C_BG_RGB='\e[48;2;3;252;7m' # 48;2;r;g;b        # RGB support only in true-color terminals.
# High Intensity Foreground ~~~~~~~~~~~~
_C_HI_BLACK='\e[90m'
_C_HI_RED='\e[91m'
_C_HI_GREEN='\e[92m'
_C_HI_YELLOW='\e[93m'
_C_HI_BLUE='\e[94m'
_C_HI_PURPLE='\e[95m'
_C_HI_CYAN='\e[96m'
_C_HI_WHITE='\e[97m'
# High Intensity Background ~~~~~~~~~~~~
_C_HIBG_BLACK='\e[100m'
_C_HIBG_RED='\e[101m'
_C_HIBG_GREEN='\e[102m'
_C_HIBG_YELLOW='\e[103m'
_C_HIBG_BLUE='\e[104m'
_C_HIBG_PURPLE='\e[105m'
_C_HIBG_CYAN='\e[106m'
_C_HIBG_WHITE='\e[107m'
# Custom Combos ~~~~~~~~~~~~~~~~~~~~~~~~
# Error Codes
_C_EMERGENCY='\e[01;30;41m'
_C_ALERT='\e[01;31;43m'
_C_CRITICAL='\e[01;97;41m'
_C_ERROR='\e[01;31m'
_C_WARNING='\e[01;33m'
_C_NOTICE='\e[01;30;107m'
_C_INFO='\e[01;39m'
_C_DEBUG='\e[01;97;46m'
_C_SUCCESS='\e[01;32m'
