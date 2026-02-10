# shellcheck shell=bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FILE                : 31-security.sh
# DESCRIPTION         : Security-related functions and aliases
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
# AppArmor Profile Search Helper
# Notes:
#   - Searches apparmor profiles for a given pattern.
#   - Prints the header line once followed by matching
#     indented lines.
#   - Usage: aa-search <pattern>
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
apparmor-search() {
  local PATTERN current_header header_printed
  PATTERN="$1"

  if [ -z "$PATTERN" ]; then
    echo "Usage: $0 <pattern>"
    exit 1
  fi

  current_header=""
  header_printed="false"
  # shellcheck disable=2046
  while IFS= read -r line; do
      # Check for header
      if [[ "$line" =~ ^[0-9].*(mode\.|defined\.)$ ]]; then
          current_header="$line"
          header_printed="false"
          continue
      fi
      # Check for an indented line that contains the pattern
      if [[ "$line" =~ ^[[:space:]]+ ]] && [[ "$line" == *"$PATTERN"* ]]; then
          if [ -n "$current_header" ]; then
              if [ "$header_printed" = "false" ]; then
                  echo "$current_header"
                  header_printed="true"
              fi
              echo "$line"
          fi
      fi
  done <<< $(sudo aa-status)
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# JWT Tooling: Create JWT Key/Cert Pair
# Notes:
#   - Creates a 4096 bit RSA keypair.
# IE: For PHP-JWT
# Outputs:
#   - RSA 4096 keypair
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
jwt_create_keycert(){
  read -rp "Output Key File [id.key]: " output_key; output_key=${output_key:-id.key}
  read -rp "Output Cert File [id.cert]: " output_cert; output_cert=${output_crt:-id.cert}
  openssl req \
    -new \
    -newkey rsa:4096 \
    -days 3650 \
    -nodes \
    -x509 \
    -keyout "$output_key" \
    -out "$output_cert"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# JWT Tooling: Create JWT Token
# Arguments:
#   - Expiry offset in seconds  REQUIRED
#   - Subject Key               REQUIRED
#   - Subject Value             REQUIRED
#   - Signature Signal          OPTIONAL
# Outputs:
#   - Multi-segment base64 encoded JWT token
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
jwt_create_token() {
  local HEADER ISSUE_TS EXP PAY SIG JWT SECRET
  function help {
    printf '%s\n' 'Requires at least 3 arguments.'
    printf '%s\n' 'Usage: jwt_create <expiry offset in seconds> <subject key> <subject val>'
    printf '%s\n' '   EG: jwt_create 8600 user_id the_king'
    printf '%s\n' "Supply 'SIGN' as the fourth argument to add a signature"
  }
  if [[ $key == '-h' ]] || [[ $# -eq 0 ]] || [[ $# -lt 3 ]]; then
    help
    return
  fi
  HEADER=$(echo -n '{"alg":"HS256","typ":"JWT"}' | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
  ISSUE_TS=$(date +%s)
  EXP=$((ISSUE_TS + 1))
  PAY=$(echo -n "{\"$2\":\"$3\",\"exp\":\"$EXP\"}" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
  if [[ "$4" == "SIGN" ]]; then
    read -srp "Signature Secret: " SECRET; echo ''
    SIG=$(echo -n "$HEADER.$PAY" | openssl dgst -sha256 -hmac "$SECRET" -binary | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
    JWT="$HEADER.$PAY.$SIG"
    echo "$JWT"
    return
  fi
  JWT="$HEADER.$PAY"
  echo "$JWT"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# JWT Tooling: Decode base64 JWT Token
# Notes:
#   - Correct length with an amount of padding.
# Arguments:
#   - JWT Token (single segment)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
jwt_decode_base64() {
  local len=$((${#1} % 4))
  local result="$1"
  if [ $len -eq 2 ]; then
    result="$1"'=='
  elif [ $len -eq 3 ]; then
    result="$1"'='
  fi
  echo "$result" | tr '_-' '/+' | openssl enc -d -base64
  echo ''
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# JWT Tooling: Decode Segment of a multi-segment JWT token
# Notes:
#   - This is used by the jwt_header, jwt_payload, and
#     jwt_signature helpers below.
# Arguments:
#   - Segment to decode
#   - Multi-segment JWT token
# Cyclomatic Complexity: 7
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
jwt_decode_token() {
  local SECRET SIG
  [[ $( (tr -dc . | wc -c)<<<"$*" ) -eq 0 ]] && jwt_decode_base64 "$2"
  [[ $( (tr -dc . | wc -c)<<<"$*" ) -ge 1 ]] && { [[ "$1" -eq 1 ]] || [[ "$1" -eq 2 ]] ;} && jwt_decode_base64 "$(echo -n "$2" | cut -d "." -f "$1")" | jq .
  if [[ $( (tr -dc . | wc -c)<<<"$*" ) -eq 2 ]] && [[ "$1" -eq 3 ]]; then
    read -srp "Signature Secret: " SECRET; echo ''
    SIG=$(
                  echo -n "$( (cut -d"." -f1)<<<"$2" ).$( (cut -d"." -f2)<<<"$2" )" \
                  | openssl dgst -sha256 -hmac "$SECRET" -binary \
                  | openssl base64 -e -A \
                  | tr '+/' '-_' \
                  | tr -d '=')
    [[ "$SIG" == "$( (cut -d"." -f3)<<<"$2" )" ]] && loggerx SUCCESS "Signature OK"
  fi
}
alias jwt_header="jwt_decode_token 1"     # Decode JWT header
alias jwt_payload="jwt_decode_token 2"    # Decode JWT Payload
alias jwt_signature="jwt_decode_token 3"  # Verify JWT Signature

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# JWT Tooling: Automatically handle whichever length of
#              token may be provided.
# Arguments:
#   - Segment(s) to decode
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
jwt_decoder() {
  [[ $( (tr -dc . | wc -c)<<<"$*" ) -eq 0 ]] && jwt_decode_token 1 "$*"
  if [[ $( (tr -dc . | wc -c)<<<"$*" ) -eq 1 ]]; then
    jwt_decode_token 1 "$*"
    jwt_decode_token 2 "$*"
  fi
  if [[ $( (tr -dc . | wc -c)<<<"$*" ) -eq 2 ]]; then
    jwt_decode_token 1 "$*"
    jwt_decode_token 2 "$*"
    jwt_decode_token 3 "$*"
  fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# PW Generator Fount Function
# Notes:
#   - Used by genpass
#   - This sub-function handles generation of a 20-character
#     component.
# Arguments:
#   -s          Include special characters
# Outputs:
#   - Randomly generated password 20 characters in length
# TODO:
#   - Allow SPEC input to facilitate various tool compliance
#     Previously looped pwgen until a compliant string was
#     produced.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__genpass_fount() {
  local SPEC_SAFE ALPH_NUM ALPH_LEAD RANDUP OUTPUT_TAIL
  [[ "$2" == "-s" ]] && loggerx ERROR "Length must be specified after any arguments." && return 1
  if [[ "$1" == "-s" ]]; then
    SPEC='!@#$%^&*()<>[]{}|_+-='
    SPEC_SAFE="${SPEC:$(( RANDOM % ${#SPEC} )):1}"
    ALPH_NUM=$(openssl rand -base64 128 | tr -dc 'a-zA-Z0-9' | tr -d '\n' | head -c 128)
    ALPH_LEAD=$(openssl rand -base64 128 | tr -dc 'a-zA-Z' | tr -d '\n' | head -c 1)
    RANDUP=$(echo -n "${SPEC}${ALPH_NUM}" | fold -w 1 | shuf | tr -d "\n" | head -c 18 | head -n 1)
    OUTPUT_TAIL=$(echo -n "${RANDUP}${SPEC_SAFE}" | fold -w 1 | shuf | tr -d "\n")
    echo "${ALPH_LEAD}${OUTPUT_TAIL}"
  else
    openssl rand -base64 128 | tr -dc 'a-zA-Z0-9' | head -c 20 | head -n 1
    echo ''
  fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# PW Generator
# Notes:
#   - Same as __genpass_fount
#   - No length limitation
#   - Defaults to 20 characters
# Arguments:
#   - -s           Include special characters
#   - <len> int    Length of the output string
# Outputs:
#   - Randomly generated password of any length.
# Cyclomatic Complexity: 7
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
genpass() {
  [[ "$2" == "-s" ]] && loggerx ERROR "Length must be specified after any arguments." && return 1
  local LEN="20"
  local FOUNT_LEN='20'
  if [[ "$1" == "-s" ]]; then
    { [[ -n $2 ]] && [[ $2 -ne $FOUNT_LEN ]] ; } && local LEN="$2"
    local GEN_RUNS=$(( (LEN / FOUNT_LEN) + 1 ))
    for ((GEN=0; GEN <= GEN_RUNS; GEN++)); do
      __genpass_fount -s | tr -d '\n'
    done | head -c "$LEN"
    echo ''
  else
    { [[ -n $1 ]] && [[ $1 -ne $FOUNT_LEN ]] ;} && local LEN="$1"
    local GEN_RUNS=$(( (LEN / FOUNT_LEN) + 1 ))
    for ((GEN=0; GEN <= GEN_RUNS; GEN++)); do
      __genpass_fount | tr -d '\n'
    done | head -c "$LEN"
    echo ''
  fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Encrypt a password with bcrypt.
# Notes:
#   - Cannot verify with htpasswd without populating an
#     htpasswd file.
#   - Most useful for planned credential roles.
# htpasswd examples
#   - Create htpasswd file for user 'foo'
#     htpasswd -cBC '12' htpasswdfile foo
#   - Verify password
#     htpasswd -v htpasswdfile foo
# Arguments
#   Computing Time <int>     Specify computing time
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
encrypt_pass_bcrypt() {
    read -srp "Password: " password
    echo ''
    local computing_time="$1"
    if [[ -z $computing_time ]]; then
        loggerx WARNING "Computing time not supplied. Using Default: 12."
        local computing_time="12"
    fi
    htpasswd -bnBC "$computing_time" "" "$password" | tr -d ':\n'
    echo ''
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create an encrypted vault
# Notes:
#   - Creates an encrypted tar.gz.dat file from a directory
#     or file.
#   - Uses openssl aes-256-cbc with sha512 and pbkdf2
#     key derivation.
#   - Optionally wipes the source content after creation.
# Arguments:
#   -t      The TARGET to encrypt. REQUIRED
#   -w      WIPE the target content upon completion of
#           archive creation. WARNING: Perhaps verify archive
#           prior to wiping content.
#   -h      Display help menu.
# Cyclomatic Complexity: 7
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
vault_create() {
  function show_help() {
    cat << EOF
Create an encrypted vault from a directory or file.

Example: ${0##*/} -t <target> {-w}{-h}

Arguments:
    -t      The TARGET to encrypt.
    -w      WIPE the target content upon completion of archive creation.
            WARNING: Perhaps verify archive prior to wiping content.
    -h      Display this help menu.

EOF
  HELPED="true"
  }
  [[ $# -eq 0 ]] && show_help

  OPTIND=1
  while getopts "t:hw" opt; do
    case "$opt" in
      t) TARG="$OPTARG" ;;
      h) show_help ;;
      w) arg_w='set' ;;
      *) echo "ERROR: Unknown option!"; show_help ;;
    esac
  done
  shift "$((OPTIND-1))"
  [ "$1" = "--" ] && shift
  if [[ "$HELPED" == "true" ]]; then
    unset HELPED
    return 1
  fi
  loggerx INFO "Encrypting $TARG"
  tar cz "${TARG}/" | openssl enc -aes-256-cbc -md sha512 -pbkdf2 -out "${TARG}.tar.gz.dat"
  [[ "$arg_w" == "set" ]] && wipe -rf "$TARG"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Open an encrypted vault.
# Notes:
#   - Decrypts and extracts an encrypted tar.gz.dat file.
#   - Uses openssl aes-256-cbc with sha512 and pbkdf2
#     key derivation.
# Arguments:
#   - <vault file>   The vault file to open.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
vault_open() {
  VAULT="$1"
  openssl enc -aes-256-cbc -md sha512 -pbkdf2 -d -in "$VAULT" | tar -xz
}
