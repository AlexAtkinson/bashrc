# shellcheck shell=bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FILE                : 04-system-info.sh
# DESCRIPTION         : System information functions
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
# Report the name of the OS distribution.
# Outputs:
#   The NAME field from the /etc/*-release file
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_os_distro() {
  DISTRO=$(awk -F= '$1=="NAME" { gsub(/"/,"",$2); print $2 }' /etc/*-release)
  export DISTRO
  echo "$DISTRO"
}
_check_os_distro >/dev/null >&1

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Report the architecture of the system.
# Outputs:
#   Print the system architecture as defined by `uname -m`
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_os_arch() {
  case $(uname -m) in
    arm64|aarch64) ARCH="ARM64"          ;;
    armhf|armv7*)  ARCH="ARM32_COMPAT"   ;;
    armv8*)        ARCH="ARM64_COMPAT"   ;;
    i*86*)         ARCH="x86"            ;;
    amd64|x86_64*) ARCH="x64"            ;;
    *)             ARCH="unknown: $ARCH" ;;
  esac
  export ARCH
  echo "$ARCH"
}
_check_os_arch >/dev/null >&1

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Report the OS Type
# Outputs:
#   The type of system as defined by the $OSTYPE variable.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_os_type() {
    case "$OSTYPE" in
        solaris*) OS_TYPE="SOLARIS"          ;;
        darwin*)  OS_TYPE="OSX"              ;;
        linux*)   OS_TYPE="LINUX"            ;;
        bsd*)     OS_TYPE="BSD"              ;;
        msys*)    OS_TYPE="WINDOWS"          ;;
        cygwin*)  OS_TYPE="CYGWIN"           ;;
        *)        OS_TYPE="unknown: $OSTYPE" ;;
    esac;
    export OS_TYPE
    echo "$OS_TYPE"
}
_check_os_type >/dev/null >&1

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Report system information from /etc/os-release
# Arguments & Outputs:
#   - See: https://www.freedesktop.org/software/systemd/man/os-release.html"
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_os_info() {
  key="$*"
  function help {
    printf '%s\n' 'Try: NAME, PRETTY_NAME, VERSION_ID, VERSION, ID_LIKE'
    printf '%s\n' 'REF: https://www.freedesktop.org/software/systemd/man/os-release.html'
    return 0
  }
  [[ $key == '-h' ]] && help
  [[ $# -eq 0 ]] && help
  for key in "$@"; do
    sed -ne "s/^$key=//p" /etc/os-release | tr -d '"'
  done
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Report Wireless Interface Name
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_wireless_interface_name() {
  if command -v nmcli >/dev/null 2>&1; then
    nmcli -t -f DEVICE,TYPE device status 2>/dev/null \
      | awk -F: '$2 == "wifi" { print $1; exit }'
  fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Report CPU Information
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_cpu() {
  local LSCPU
  LSCPU=$(lscpu)
  printf "%s\n" "$(grep "Model name" <<< "$LSCPU" | \
                   cut -d: -f2- | \
                   sed -E 's/^[[:space:]]?+//') \
                    ($(( \
                       $(grep "Core(s)" <<< "$LSCPU" | \
                         cut -d: -f2) \
                       * \
                       $(grep "Thread(s)" <<< "$LSCPU" | \
                         cut -d: -f2) \
                    )) \
                    Threads @ ~$(grep "max MHz" <<< "$LSCPU" | \
                                 cut -d: -f2 | \
                                 sed -E 's/^[[:space:]]?+//' | \
                                 cut -d. -f1) \
                    MHz max)" | sed 's/  */ /g'
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Report Memory Information
# Note: Pre-formatting for other use. `free -m` is generally
#       fine.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_memory() {
  local MEMINFO TOTAL_MEM FREE_MEM USED_MEM BUFFERS_CACHED
  MEMINFO=$(grep -E '^MemTotal:|^MemFree:|^Buffers:|^Cached:' /proc/meminfo)
  TOTAL_MEM=$(grep 'MemTotal:' <<< "$MEMINFO" | awk '{print $2}')
  FREE_MEM=$(grep 'MemFree:' <<< "$MEMINFO" | awk '{print $2}')
  BUFFERS_CACHED=$(( $(grep 'Buffers:' <<< "$MEMINFO" | awk '{print $2}') + \
                     $(grep 'Cached:' <<< "$MEMINFO" | awk '{print $2}') ))
  USED_MEM=$(( TOTAL_MEM - FREE_MEM - BUFFERS_CACHED ))
  printf "Total: %d MB\n" $(( TOTAL_MEM / 1024 ))
  printf "Used : %d MB\n"  $(( USED_MEM / 1024 ))
  printf "Free : %d MB\n"  $(( FREE_MEM / 1024 ))
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Report total system memory.
# Outputs:
#   Total system memory in human readable format.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_memory_installed() {
  local TOTAL_MEM
  TOTAL_MEM=$(lsmem -b --summary=only | sed -ne '/online/s/.* //p' | awk '{print $total}')
  # shellcheck disable=2119
  echo "$TOTAL_MEM" | bytesToHumanReadable
}
# Reminder:
#   - IN GB without bytesToHuman...:
#     lsmem -b --summary=only | sed -ne '/online/s/.* //p' | awk '{print $total / 1024 / 1024 / 1024}'

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Report Total Installed Memory in MB
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_memory_installed_mb() {
  local INSTALLED_MEM
  UNIT=$(sudo dmidecode -t memory | grep Size: | grep -v "No Module Installed" | awk 'NR==1 {print $NF; exit}')
  INSTALLED_MEM=$(sudo dmidecode -t memory | grep 'Size:' | grep -v 'No Module Installed' | awk '{sum += $2} END {print sum}')
  printf "%s\n" "$INSTALLED_MEM $UNIT" | \
    awk '{
      if ($2 == "GB") {
        printf "%d\n", $1 * 1024
      } else if ($2 == "MB") {
        printf "%d\n", $1
      } else {
        printf "0\n"
      }
    }'
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Report Total Installed Memory in GB
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_memory_installed_gb() {
  local INSTALLED_MEM
  UNIT=$(sudo dmidecode -t memory | grep Size: | grep -v "No Module Installed" | awk 'NR==1 {print $NF; exit}')
  INSTALLED_MEM=$(sudo dmidecode -t memory | grep 'Size:' | grep -v 'No Module Installed' | awk '{sum += $2} END {print sum}')
  printf "%s\n" "$INSTALLED_MEM $UNIT" | \
    awk '{
      if ($2 == "GB") {
        printf "%d\n", $1
      } else if ($2 == "MB") {
        printf "%d\n", int($1 / 1024)
      } else {
        printf "0\n"
      }
    }'
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Report Total Available Memory in MB
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_memory_total_available_mb() {
  local TOTAL_MEM
  TOTAL_MEM=$(grep 'MemTotal:' /proc/meminfo | awk '{print $2}')
  printf "%d\n" $(( TOTAL_MEM / 1024 ))
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Report Total Available Memory in GB
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_memory_total_available_gb() {
  local TOTAL_MEM
  TOTAL_MEM=$(grep 'MemTotal:' /proc/meminfo | awk '{print $2}')
  printf "%d\n" $(( TOTAL_MEM / 1024 / 1024 ))
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Report GPU Type
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_gpu() {
  lspci -nn | grep 'VGA' | cut -d' ' -f6-
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Report GPU Driver Details
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_gpu_driver() {
  local GPU
  GPU=$(escape_string <<<"$(_check_gpu)")
  lspci -nnk | grep -iE "$GPU" -A3
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Generate System Report
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_system_report() {
  printf "%s\n" "===== SYSTEM REPORT ====="
  printf "%s %s\n" "OS Distro    :" "$(_check_os_distro)"
  printf "%s %s\n" "OS Type      :" "$(_check_os_type)"
  printf "%s %s\n" "Architecture :" "$(_check_os_arch)"
  printf "%s %s\n" "CPU          :" "$(_check_cpu)"
  printf "%s %s\n" "Memory (GB)  :" "$(_check_memory_installed_gb)"
  printf "%s %s\n" "GPU          :" "$(_check_gpu)"
  printf "%s %s\n" "GPU Driver   :" "$(_check_gpu_driver | grep 'Kernel driver in use' | cut -d: -f2 | sed -E 's/^[[:space:]]+//')"
  printf "%s\n" "========================="
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Report Longest IANA TLDs
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_longest_iana_urls() {
  awk '{print length($0), $0; }'<<<"$(curl -sS https://data.iana.org/TLD/tlds-alpha-by-domain.txt)" | \
    grep -v 'XN-' | \
    sort -r -n | \
    head
}
