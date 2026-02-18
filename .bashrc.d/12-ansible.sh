# shellcheck shell=bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FILE                : 12-ansible.sh
# DESCRIPTION         : Ansible functions and aliases
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
# ansible-playbook wrapper to use local inventory.ini if
# present.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ansible-playbook() {
  [[ -f inventory.ini ]] && ansible-playbook -i ./inventory.ini "$@"
  [[ ! -f inventory.ini ]] && command ansible-playbook "$@"
}
alias ap='ansible-playbook'

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get Ansible Facts for a given host.
# Arguments:
#   <host>         The host to get facts for (optional,
#                  defaults to localhost)
# Outputs:
#   JSON formatted Ansible facts
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# shellcheck disable=2120,2034
_ansible_facts() {
  local HOSTS
  [[ $1 == '-h' ]] && loggerx ERROR "Usage: _ansible_facts [<host>]" && return 1
  [[ -z $1 ]] && HOSTS='localhost' || HOSTS="$1"
  ansible "$HOSTS" -m ansible.builtin.setup | sed '1c {' | jq .
}
