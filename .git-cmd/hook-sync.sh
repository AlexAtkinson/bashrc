#!/usr/bin/env bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# FILE                : hook-sync.sh
# DESCRIPTION         : Sync's the git hook content from .git-cmd/hooks to .git/hooks.
#                       This is used to ensure that the hooks are always up to
#                       date with the latest version in the repo.
#                       This is NON-DESTRUCTIVE to any existing content in target hook files.
#
# NOTICE              : Consider using Husky instead.
#
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

IFS_BAK=$IFS

# Create array of hook files in .git-cmd/hooks
HOOKS=(.git-cmd/hooks/*)

# Ensure that each hook file exists in .git/hooks.
# Creates empty file if not found.
for hook in "${HOOKS[@]}"; do
  HOOK_NAME=$(basename "$hook")
  TARGET_HOOK=".git/hooks/$HOOK_NAME"
  if [[ ! -f "$TARGET_HOOK" ]]; then
    touch "$TARGET_HOOK"
    chmod +x "$TARGET_HOOK"
    echo '#!/usr/bin/env bash' > "$TARGET_HOOK"
  fi
  # Populate CONTENT array with the content of the hook file, wrapped in control flags.
  START='# HOOKSYNC - AUTOCONFIG START --------------------------------------------------'
  CONTENT=()
  # shellcheck disable=SC2179
  CONTENT+='# WARNING: Changes to this section will be overwritten.\n'
  # shellcheck disable=SC2179
  CONTENT+='#          Last Updated: '"'$(date -u +"%FT%H-%S")'"'\n'
  # shellcheck disable=SC2179
  CONTENT+='#\n'
  # Set IFS to ensure that newlines are preserved when reading the hook file content into the CONTENT array.
  IFS=$'\n'
  while read -r line; do
    # Escape characters that may interfere with sed replacement.
    line=$(echo "$line" | sed 's/[&/\]/\\&/g')
    # shellcheck disable=SC2179
    CONTENT+="$line\n"
  done < "$hook"
  IFS=$IFS_BAK
  # shellcheck disable=SC2179
  CONTENT+='#\n'
  END='# HOOKSYNC - AUTOCONFIG END ----------------------------------------------------'
  # Add control flags to target hook file if not already present.
  if [[ $(grep -c "$START" "$TARGET_HOOK") == 0 ]]; then
    echo -e "\n$START\n\n$END" >> "$TARGET_HOOK"
  else
    true
  fi
  # Use sed to replace the content between the control flags with the content of the hook file.
  # WARNING: This sed command is invalid on MacOS. Ensure gsed is installed and aliased to sed.
  #   sed: 1: "...": unterminated substitute in regular expression
  sed -ni "/${START}/{p;:a;N;/${END}/!ba;s/.*\n/${CONTENT[*]}/};p" "$TARGET_HOOK"
done

# Delete HOOKSYNC control flags from target hook files if the corresponding hook file is deleted from .git-cmd/hooks.
# Exclude .sample files from this operation.
for target_hook in .git/hooks/*; do
  HOOK_NAME=$(basename "$target_hook")
  [[ "$HOOK_NAME" == *.sample ]] && continue
  SOURCE_HOOK=".git-cmd/hooks/$HOOK_NAME"
  if [[ ! -f "$SOURCE_HOOK" ]]; then
    # Delete control flags and content between them from target hook file.
    gsed -i "/${START}/,/${END}/d" "$target_hook"
  fi
done