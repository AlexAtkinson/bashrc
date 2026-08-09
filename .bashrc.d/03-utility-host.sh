# shellcheck shell=bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Display a host hardware and operating system profile.
# Notes:
#   - Aggregates host, OS, CPU, memory, storage, and controller data.
#   - Run with sudo to include firmware-backed DMI memory and CPU details.
# Outputs:
#   A formatted multi-section host profile report.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
host-profile() {
  local root_source root_device root_disk root_fs root_mount
  local root_size root_used root_available memory_total swap_total
  local cpu_model cpu_cores cpu_threads cpu_max_speed virtualization
  local os_name kernel architecture uptime
  local dmi_memory dmi_cpu
  local lscpu_output free_output df_root_output

  _host_profile_section() {
    printf '\n\033[1;36m%s\033[0m\n' "$1"
    printf '%*s\n' 78 '' | tr ' ' '-'
  }

  _host_profile_value() {
    printf '  \033[1m%-22s\033[0m %s\n' "$1:" "${2:-unknown}"
  }

  _host_profile_section 'Host'
  _host_profile_value 'Hostname' "$(hostnamectl --static 2>/dev/null || hostname)"
  _host_profile_value 'Manufacturer' "$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || printf 'unknown')"
  _host_profile_value 'Model' "$(cat /sys/class/dmi/id/product_name 2>/dev/null || printf 'unknown')"
  _host_profile_value 'BIOS version' "$(cat /sys/class/dmi/id/bios_version 2>/dev/null || printf 'unknown')"

  os_name=$(
    if [[ -r /etc/os-release ]]; then
      awk -F= '$1 == "PRETTY_NAME" { gsub(/"/, "", $2); print $2; exit }' /etc/os-release
    fi
  )
  kernel=$(uname -r)
  architecture=$(uname -m)
  uptime=$(uptime -p 2>/dev/null || printf 'unknown')

  _host_profile_section 'Operating System'
  _host_profile_value 'OS' "$os_name"
  _host_profile_value 'Kernel' "$kernel"
  _host_profile_value 'Architecture' "$architecture"
  _host_profile_value 'Boot mode' "$([[ -d /sys/firmware/efi ]] && printf 'UEFI' || printf 'Legacy BIOS')"
  _host_profile_value 'Uptime' "$uptime"

  lscpu_output=$(lscpu 2>/dev/null)
  cpu_model=$(awk -F: '/Model name:/ { sub(/^[ \t]+/, "", $2); print $2; exit }' <<< "$lscpu_output")
  cpu_cores=$(awk -F: '/^Core\(s\) per socket:/ { gsub(/ /, "", $2); cores = $2 } /^Socket\(s\):/ { gsub(/ /, "", $2); sockets = $2 } END { if (cores && sockets) print cores * sockets }' <<< "$lscpu_output")
  cpu_threads=$(getconf _NPROCESSORS_ONLN 2>/dev/null)
  cpu_max_speed=$(awk -F: '/CPU max MHz:/ { gsub(/^[ \t]+/, "", $2); printf "%.2f GHz", $2 / 1000; exit }' <<< "$lscpu_output")
  virtualization=$(awk -F: '/Virtualization:/ { sub(/^[ \t]+/, "", $2); print $2; exit }' <<< "$lscpu_output")

  _host_profile_section 'Processor'
  _host_profile_value 'CPU' "$cpu_model"
  _host_profile_value 'Physical cores' "$cpu_cores"
  _host_profile_value 'Logical CPUs' "$cpu_threads"
  _host_profile_value 'Maximum speed' "$cpu_max_speed"
  _host_profile_value 'Virtualization' "$virtualization"

  free_output=$(free -h 2>/dev/null)
  memory_total=$(awk '/^Mem:/ { print $2 }' <<< "$free_output")
  swap_total=$(awk '/^Swap:/ { print $2 }' <<< "$free_output")

  _host_profile_section 'Memory'
  _host_profile_value 'Installed RAM' "$memory_total"
  _host_profile_value 'Configured swap' "$swap_total"

  if [[ $EUID -eq 0 ]] && command -v dmidecode >/dev/null 2>&1; then
    dmi_memory=$(dmidecode -t memory 2>/dev/null | awk '
      /Memory Device$/ { size = speed = configured = type = manufacturer = part = "" }
      /^[[:space:]]*Size:/ && $0 !~ /No Module Installed/ { sub(/^[[:space:]]*Size:[[:space:]]*/, ""); size = $0 }
      /^[[:space:]]*Type:/ { sub(/^[[:space:]]*Type:[[:space:]]*/, ""); type = $0 }
      /^[[:space:]]*Speed:/ { sub(/^[[:space:]]*Speed:[[:space:]]*/, ""); speed = $0 }
      /^[[:space:]]*Configured Memory Speed:/ { sub(/^[[:space:]]*Configured Memory Speed:[[:space:]]*/, ""); configured = $0 }
      /^[[:space:]]*Manufacturer:/ { sub(/^[[:space:]]*Manufacturer:[[:space:]]*/, ""); manufacturer = $0 }
      /^[[:space:]]*Part Number:/ {
        sub(/^[[:space:]]*Part Number:[[:space:]]*/, "")
        part = $0
        if (size != "") printf "    %s %s, rated %s, configured %s, %s %s\n", size, type, speed, configured, manufacturer, part
      }
    ')

    _host_profile_value 'Memory module data' 'Available'
    [[ -n $dmi_memory ]] && printf '%s\n' "$dmi_memory" || printf '    Firmware did not expose DIMM details.\n'

    dmi_cpu=$(dmidecode -t processor 2>/dev/null | awk '
      /^[[:space:]]*External Clock:/ { sub(/^[[:space:]]*External Clock:[[:space:]]*/, ""); print; exit }
    ')
    _host_profile_value 'CPU external clock' "${dmi_cpu:-not reported by firmware}"
  else
    _host_profile_value 'RAM speed / DIMMs' 'Run sudo host-profile for DMI details'
    _host_profile_value 'CPU external clock' 'Run sudo host-profile for firmware data'
  fi

  root_source=$(findmnt -n -o SOURCE / 2>/dev/null)
  root_fs=$(findmnt -n -o FSTYPE / 2>/dev/null)
  root_mount=$(findmnt -n -o TARGET / 2>/dev/null)
  root_device=$(readlink -f "$root_source" 2>/dev/null || printf '%s' "$root_source")
  if [[ -n $root_device ]] && command -v lsblk >/dev/null 2>&1; then
    root_disk=$(lsblk -no PKNAME "$root_device" 2>/dev/null | head -n1)
  fi
  df_root_output=$(df -hP / 2>/dev/null | awk 'NR == 2')
  root_size=$(awk '{ print $2 }' <<< "$df_root_output")
  root_used=$(awk '{ print $3 " (" $5 ")" }' <<< "$df_root_output")
  root_available=$(awk '{ print $4 }' <<< "$df_root_output")

  _host_profile_section 'Operating System Storage'
  _host_profile_value 'Root mount' "$root_mount"
  _host_profile_value 'Root source' "$root_source"
  _host_profile_value 'Filesystem' "$root_fs"
  _host_profile_value 'OS disk' "${root_disk:-unable to determine}"
  _host_profile_value 'Root capacity' "$root_size"
  _host_profile_value 'Root used' "$root_used"
  _host_profile_value 'Root available' "$root_available"

  _host_profile_section 'Block Devices And Partitions'
  if command -v lsblk >/dev/null 2>&1; then
    lsblk -o NAME,TYPE,SIZE,FSTYPE,FSVER,MOUNTPOINTS,MODEL,TRAN
  else
    printf '  lsblk is not installed.\n'
  fi

  _host_profile_section 'Graphics And Network Controllers'
  if command -v lspci >/dev/null 2>&1; then
    lspci -Dnn | grep -iE 'VGA compatible controller|3D controller|Display controller|Network controller|Ethernet controller' \
      || printf '  No matching PCI controllers found.\n'
  else
    printf '  lspci is not installed.\n'
  fi

  unset -f _host_profile_section _host_profile_value
  printf '\n'
}