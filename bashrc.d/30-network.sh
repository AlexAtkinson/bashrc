# shellcheck shell=bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FILE                : 30-network.sh
# DESCRIPTION         : Network-related functions and aliases
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
# IPTables Save
# Notes:
#   - Saves iptables and ip6tables rules to timestamped files
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_iptables_save () {
    local DIR;
    DIR="$HOME/.iptabels";
    sudo iptables-save | sudo tee "${DIR}/iptables.rules.$(date +%s)" > /dev/null;
    sudo ip6tables-save | sudo tee "${DIR}/ip6tables.rules.$(date +%s)" > /dev/null
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Check Wireless Interface Name
# Notes:
#   - Uses nmcli to determine wireless interface name
# Outputs:
#   - Wireless interface name
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_wireless_interface_name() {
  if command -v nmcli >/dev/null 2>&1; then
    nmcli -t -f DEVICE,TYPE device status 2>/dev/null \
      | awk -F: '$2 == "wifi" { print $1; exit }'
  fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Networking Aliases
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
alias __dns_flush='sudo systemd-resolve --flush-caches'               # Flush DNS cache
#alias _check_myip='curl -s https://ipinfo.io/ip'                      # Get public IP address
alias _check_ipv4='curl -s -4 https://icanhazip.com'                  # Get public IPv4 address
alias _check_myip='_check_ipv4'                                       # Get public IP address
alias _check_ipv6='curl -s -6 https://icanhazip.com'                  # Get public IPv6 address
# shellcheck disable=2142
alias _check_localip="hostname -I | awk '{print \$1}'"                # Get local IP address
alias _check_ports_listening='sudo lsof -i -P -n | grep LISTEN'       # Show listening ports

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Check Network Default Routes
# Notes:
#   - Shows interfaces with default routes and DNS info
# Outputs:
#   - Interfaces with default routes
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_check_net_default_routes() {                                         # Interfaces with default routes
  resolvectl | \
    awk '/^Link/{a=1; buf=""} /DNS Servers/{c=1} {buf=buf $0 ORS} /Default Route: yes/{if (a && c) printf "%s\n", buf; a=c=0}' | \
    cat -p -P -l cpp --paging=never --color=always 2>/dev/null           # cpp because it highlights reasonably well
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Connection Counts
# Notes:
#   - Uses `ss` command
# Outputs:
#   - Connection counts by state
# Cyclomatic Complexity: 6
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_constat() {
  tmpfile=$(mktemp)
  ss -aH 2>/dev/null > "$tmpfile"
  printf "CONNECTION COUNTS (UDP,TCP):\n"
  printf -- "-----------------\n"
  for i in UNCONN LISTEN ESTAB FIN-WAIT-1 CLOSE-WAIT FIN-WAIT-2 LAST-ACK CLOSING TIME-WAIT; do
    printf '%s\n' "${i}: $(grep -ci "${i}" "${tmpfile}")"
  done | column -t
  printf '%s\n' "TOTAL: $(grep -c ^ "${tmpfile}")"
  rm -f "$tmpfile"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DNS Trace Redirects
# Notes:
#   - Traces redirects for a URL with timing and server info
# Arguments:
#   URL            The URL to trace
# Outputs:
#   Redirect trace with timings and server/response info
# Cyclomatic Complexity: 8
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dnsTraceRedirects() {
    url=$1;
    totalTime=0;
    unset run;
    while [[ "$run" != 'term' ]]; do
        ts=$(date +%s%N);
        curl -skI "${url}" > /dev/null 2>&1;
        tt=$((($(date +%s%N) - "$ts")/1000000));
        totalTime=$((totalTime + tt));
        [[ "$run" != 'last' ]] && server=$(wget --server-response --no-check-certificate --max-redirect 0 --tries 1 "${url}" 2>&1 | awk '/^  Server:/{print $2}');
        [[ "$run" != 'last' ]] && response=$(wget --server-response --no-check-certificate --max-redirect 0 --tries 1 "${url}" 2>&1 | awk '/^  HTTP/{print $1 "("$2")"}');
        [[ "$run" != 'last' ]] && printf "%s" "$tt ms : ${url}";
        url=$(wget --server-response --no-check-certificate --tries 1 -O - "${url}" 2>&1 | head -n25 | awk '/^Location/{print $2; exit}');
        if [[ -n $url ]]; then
            printf "%s\n" " [ ${server}:${response} ] >> ${url}";
        else
            if [[ "$run" != 'last' ]]; then
                run=last;
            else
                if [[ "$run" == 'last' ]]; then
                    printf "%s\n" " [ ${server}:${response} ] (Terminated)";
                    printf "%s\n" "Total Time (initial asset): ${totalTime} ms";
                    run='term';
                fi;
            fi;
        fi;
    done
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DNS Dig Aliases
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
alias digna='dig +noall +answer'
alias digns='dig NS +noall +answer'
alias digsoa='dig SOA +noall +answer'

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# dig SOA Host Record
# Arguments:
#   DOMAIN         The domain to query
# Outputs:
#   SOA Host from the authoritative nameserver
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
digsoahost() {
  digsoa | awk '{gsub(/.$/,"",$5); print $5}'
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# dig TTL Record
# Arguments:
#   DOMAIN         The domain to query
# Outputs:
#   TTL from the authoritative nameserver
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
digttl() {
  dig +noall +answer "$1" @"$(digns "$1" | awk 'NR==1 {print $5}')" | awk 'NR==1 {print $2}'
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# nslookup SOA Record
# Arguments:
#   DOMAIN         The domain to query
# Outputs:
#   SOA Record from the authoritative nameserver
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
nslookupsoa() {
  nslookup "$1" "$(digsoahost "$1")"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get TLS SANs
# Arguments:
#   DOMAIN         The domain to query
# Outputs:
#   Subject Alternative Names from the TLS certificate
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ssl-get-sans() {
  printf "Q" | openssl s_client -connect "$1":443 -servername "$1" 2>&1 | \
  openssl x509 -in /dev/stdin -text -noout -certopt \
  no_header,no_version,no_serial,no_signame,no_validity,no_subject,no_issuer,no_pubkey,no_sigdump,no_aux 2>&1 | \
  grep -o -P "DNS:.*" | sed 's/, /\n/g' | tr -d "DNS:"
}
alias tls-get-sans='ssl-get-sans'

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get TLS Supported Versions
# Arguments:
#   DOMAIN         The domain to query
# Outputs:
#   Supported TLS versions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
tls-get-supported-versions() {
  for ver in 1 1_1 1_2 1_3; do
    if printf "Q" | openssl s_client --connect "$1":443 -tls${ver} >/dev/null 2>&1; then
      [[ $ver == 1 ]] && ver='1_0'
      printf "%s\n" "TLS ${ver}: Supported"
    else
      [[ $ver == 1 ]] && ver='1_0'
      printf "%s\n" "TLS ${ver}: Not Supported"
    fi
  done
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get TLS Expiry Date
# Arguments:
#   DOMAIN         The domain to query
# Outputs:
#   Expiry date of the TLS certificate
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
tls-get-expiry() {
  local DOMAIN EXP_DATE_RAW EXP_DATE
  DOMAIN=$1
  EXP_DATE_RAW=$( (echo -n Q \
                  | openssl s_client --servername "$DOMAIN" --connect "$DOMAIN":443 \
                  | openssl x509 --noout -dates) 2>&1 \
                  | grep notAfter | cut -d= -f2- | head -n1)
  EXP_DATE=$(date -d"$EXP_DATE_RAW" --utc +"%FT%T.%3NZ")
  if [[ "$EXP_DATE" < $(date --utc +"%FT%T.%3NZ") ]]; then
    printf 'Expiry date for %s is %s -- %b\n' "$DOMAIN" "$EXP_DATE" "\e[01;97;41mEXPIRED\e[0m"
  else
    printf 'Expiry date for %s is %s\n' "$DOMAIN" "$EXP_DATE"
  fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get TLS Chain
# Arguments:
#   DOMAIN         The domain to query
# Outputs:
#   Full TLS certificate chain
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
tls-get-chain() {
  echo "Q" | openssl s_client -showcerts -connect "$1":443
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# URL Profile
# Notes:
#   - Uses digna, dnsTraceRedirects, tls-get-sans, tls-get-expiry,
#     tls-get-supported-versions, and Qualys SSL Test
# Arguments:
#   URL(s)         One or more URLs to profile
# Outputs:
#   Profile report for each URL
# Cyclomatic Complexity: 7
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
url_profile() {
  # shellcheck disable=2048
  for i in $*; do
    printHeading "$i"
    printf '%b\n' "\e[01;39mDNS Records:\e[0m"
    digna "$i"
    printf '%b\n' "\n\e[01;39mRedirects:\e[0m"
    dnsTraceRedirects "$i"
    printf '%b\n' "\n\e[01;39mTLS SANS:\e[0m"
    tls-get-sans "$i"
    printf '%b\n' "\n\e[01;39mTLS EXPIRY:\e[0m"
    tls-get-expiry "$i"
    #Start the report generation.
    tls-get-supported-versions "$i"
    curl -X GET "https://www.ssllabs.com/ssltest/analyze.html?d=${i}&hideResults=on&latest" > /dev/null 2>&1
    printf '%b\n' "\n\e[01;39mQualys SSL Test:\e[0m"
    printf '%s\n' "https://www.ssllabs.com/ssltest/analyze.html?d=${i}&hideResults=on&latest"
  done
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# GeoIP Lookup
# Arguments:
#   IP             The IP address to lookup
# Outputs:
#   City and country code for the IP address
# Notes:
#   - Requires API key from ipstack.com
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
geoip_lookup() {
  curl -sS "http://api.ipstack.com/$1?access_key=<yourkey>&output=json&fields=country_code,city" | jq -r '"\(.city), \(.country_code)"'
}
