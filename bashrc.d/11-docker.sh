# shellcheck shell=bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~s
# FILE                : 11-docker.sh
# DESCRIPTION         : Docker Functions and Aliases
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
# Get total pulls for a given docker image from DockerHub.
# Arguments:
#   <image:tag>
# Usage:
#   dockerhub-total-pulls <image:tag>
# Example:
#   dockerhub-total-pulls debian:latest
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dockerhub-total-pulls() {
    image=$(cut -d: -f1 <<< "$1")
    curl -s "https://hub.docker.com/v2/repositories/$image" | \
    jq -r '(paths(scalars) | select(.[-1] == "pull_count")) as $p | [ ( [ $p[] | tostring ] | join(".") ) , ( getpath($p) | tojson ) ] | join(": ")' | \
    awk '{s+=$2} END {print s}' | \
    xargs printf "%'d"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get total pulls for multiple docker images from DockerHub.
# Arguments:
#   <image:tag> [<image:tag> ...]
# Usage:
#   dockerhub-total-pulls-report <image:tag> [<image:tag> ...]
# Example:
#   dockerhub-total-pulls-report debian:latest ubuntu:latest fedora:latest archlinux:latest opensuse/leap:latest rockylinux:latest almalinux:latest
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# shellcheck disable=2183,2068
dockerhub-total-pulls-report() {
  if [[ "$1" == "-h" ]]; then
    echo "Try: dockerhub-total-pulls-report debian:latest ubuntu:latest fedora:latest archlinux:latest opensuse/leap:latest rockylinux:latest almalinux:latest"
    return
  fi
  images=$*
  width=50
  echo "TOTAL PULLS:"
  echo "------------"
  for image in ${images[@]}; do
    pulls=$(dockerhub-total-pulls "$image")
    printf "%s" "$image"
    printf "%*s" "$((COLUMNS-(COLUMNS-$(wc -c<<<"${image}${pulls}")+width)))" # | tr ' ' -
    printf "%s\n" "${pulls}"
  done
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# List tags for a given docker image from DockerHub.
# Arguments:
#   <image>
# Usage:
#   dockerhub_tags <image>
# Example:
#   dockerhub_tags debian
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dockerhub_tags() {
  # List tags for a given docker image
  if [[ $# -lt 1 ]]; then
    loggerx ERROR image basename must be supplied!
    return 1
  fi
  image=$1
  tag_count=$(curl -sS "https://registry.hub.docker.com/v2/repositories/library/$image/tags" | jq -r '.count')
  total_pages=$(( "$tag_count" / 100 + 1))
  page=1
  while [ $page -le $total_pages ]; do
    curl -sS "https://registry.hub.docker.com/v2/repositories/library/$image/tags?page_size=100&page=$page" | jq -r '."results"[]["name"]'
    (( page++ ))
  done
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# `docker images` wrapper
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#alias di="docker images | grep -v '^<none>' | grep $1"
di()  {
  # A `docker images` wrapper
  [[ $# = 0 ]] && docker images | grep -v '^<none>'
  [[ $# = 0 ]] && return
  docker images | grep -v '^<none>' | grep "$1"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# `docker ps` wrapper
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.RunningFor}}\t{{.Status}}\t{{.Ports}}"'

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# `watch docker ps` wrapper
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dpsw() {
  watch -n2 'docker ps --format "table {{.Names}}\t{{.Image}}\t{{.RunningFor}}\t{{.Status}}\t{{.Ports}}"'
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Docker Aliases
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
alias dcont='docker container'
alias dim='docker image'
alias dvol='docker volume'
alias dnet='docker network'
alias dbuild='docker build -t'
alias drun='docker run -it --rm'
alias dlogs='docker logs -f'
alias dexec='docker exec -it'
alias dpsa='docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
alias dimgs='docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"'
alias dvols='docker volume ls'
alias dnls='docker network ls'
#alias drma='docker rm $(docker ps -a -q)'
#alias drmi='docker rmi $(docker images -q)'
#alias drmid='docker rmi $(docker images -f "dangling=true" -q)'
alias dstop='docker stop $(docker ps -a -q)'
alias dcli='docker container ls -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
alias dcleanw='docker container prune -f && docker image prune -f && docker volume prune -f && docker network prune -f'
