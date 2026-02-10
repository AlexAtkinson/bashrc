# shellcheck shell=bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FILE                : 01-on-demand.sh
# DESCRIPTION         : Git-related functions and aliases
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

_load_rc_k8s() {
    # shellcheck source=on-demand/k8s.sh
    . ~/.bashrc.d/on-demand/k8s.sh
}
