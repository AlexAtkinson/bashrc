# shellcheck shell=bash disable=SC2129
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FILE                : 40-database.sh
# DESCRIPTION         : Database-related functions and aliases
# REPO                : https://gist.github.com/AlexAtkinson/bc765a0c143ab2bba69a738955d90abd
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
# MEMCACHED
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# RUN a local memcached with docker. Use either memcached or bitnami/memcached.
#   docker run --name memcached -p 11211:11211 memcached
#   docker run --name bitnami-memcached -p 11211:11211 bitnami/memcached

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Set a key in memcached
# Arguments:
#   [KEY] [VAL] (TIMEOUT) (HOST) (PORT)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
memcached_set() {
  local HOST PORT T S K V
  if [[ $# -lt 2 ]]; then
    loggerx ERROR "At least 2 arguments required: ${FUNCNAME[0]} [KEY] [VAL] (TIMEOUT) (HOST) (PORT)"
    return 1
  fi
  # key flags exptime bytes noreply(optional) value
  K=$1
  V=$2
  T=${3:-300}
  S=${#V}
  HOST=${4:-localhost}
  PORT=${5:-11211}
  printf '%b' "set $K 0 $T $S\r\n$V\r" | nc -q 0 "$HOST" "$PORT"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Set multiple junk items in memcached
# Arguments:
#   (Number Of Junk Items To Make - DEFAULT: 5) (TIMEOUT) (HOST) (PORT)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
memcached_set_n_junk() {
  if [[ "$1" == "-h" ]]; then
    loggerx ERROR "No arguments required: ${FUNCNAME[0]} (Number Of Junk Items To Make - DEFAULT: 5) (TIMEOUT) (HOST) (PORT)"
    return 1
  fi
  local NO_JUNK=${1:-5}
  local T=${2:-300}
  for i in $(seq -w 0001 "$NO_JUNK"); do
    echo "SETTING KEY: JUNK_$i"
    memcached_set JUNK_"$i" JUNK_VAL "$T"
  done
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Replace a key in memcached
# Arguments:
#   [KEY] [VAL] (TIMEOUT) (HOST) (PORT)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
memcached_replace() {
  local HOST PORT T S K V
  if [[ $# -lt 2 ]]; then
    loggerx ERROR "At least 2 arguments required: ${FUNCNAME[0]} [KEY] [VAL] (TIMEOUT) (HOST) (PORT)"
    return 1
  fi
  K=$1
  V=$2
  T=${3:-300}
  S=${#V}
  HOST=${4:-localhost}
  PORT=${5:-11211}
  printf '%b' "replace $K 0 $T $S\r\n$V\r" | nc -q 0 "$HOST" "$PORT"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get a key from memcached
# Arguments:
#   [KEY] (HOST) (PORT)
# Outputs:
#   KEY VAL
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
memcached_get() {
  local HOST PORT K IFS_BAK IFS r KEY VAL
  if [[ $# -lt 1 ]]; then
    loggerx ERROR "At least 1 argument required: ${FUNCNAME[0]} [KEY] (HOST) (PORT)"
    return 1
  fi
  K=$1
  HOST=${2:-localhost}
  PORT=${3:-11211}
  IFS_BAK=$IFS
  IFS=$'\r'
  r=$(echo get "$K" | nc -q 0 "$HOST" "$PORT")
  [[ $(wc -l <<< "$r") -lt 3 ]] && return 1
  KEY=$(echo "$r" | head -n 1 | cut -d' ' -f2)
  VAL=$(echo "$r" | head -n -1 | tail -n -1)
  IFS=$IFS_BAK
  echo "$KEY $VAL"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Delete a key from memcached
# Arguments:
#   [KEY] (HOST) (PORT)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
memcached_delete() {
  local HOST PORT K
  if [[ $# -lt 2 ]]; then
    loggerx ERROR "At least 1 arguments required: ${FUNCNAME[0]} [KEY] (HOST) (PORT)"
    return 1
  fi
  K=$1
  HOST=${2:-localhost}
  PORT=${3:-11211}
  echo delete "$K" | nc -q 0 "$HOST" "$PORT"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Flush all keys from memcached
# Arguments:
#   (HOST) (PORT)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
memcached_flush() {
  local HOST PORT
  if [[ "$1" == "-h" ]]; then
    loggerx ERROR "Flushes memcached. No arguments required: ${FUNCNAME[0]} (HOST) (PORT)"
    return 1
  fi
  HOST=${1:-localhost}
  PORT=${2:-11211}
  echo "flush_all" | nc -q 0 "$HOST" "$PORT"
}

memcached_dump() {
  local HOST PORT
  # NOTE: stats cachedump doesn't return COLD items.
  if [[ "$1" == "-h" ]]; then
    loggerx ERROR "Flushes memcached. No arguments required: ${FUNCNAME[0]} (HOST) (PORT)"
    return 1
  fi
  HOST=${1:-localhost}
  PORT=${2:-11211}
  for key in                        \
      $(for slab_stat in            \
          $(echo "stats items"      \
          | nc -q 0 "$HOST" "$PORT" \
          | grep ':number '         \
          | cut -d':' -f2); do
              echo "lru_crawler metadump $slab_stat" \
              | nc -q 0 "$HOST" "$PORT"              \
              | cut -d' ' -f1                        \
              | cut -d'=' -f2                        \
              | head -n -1
      done); do
      memcached_get "$key"
  done
}
