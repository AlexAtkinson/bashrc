# shellcheck shell=bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Interactively restore browser bookmarks from a dated backup.
# Backups live under ~/pCloudDrive/backups/browser_bookmarks/
#   and are organized as <browser>/<timestamp>/.
# Supports Chromium-family browsers (single Bookmarks file)
#   and Firefox-family browsers (places.sqlite + bookmarkbackups/).
# Backs up the current bookmarks with a .pre-restore timestamp
#   before overwriting.
#
# Partner: workstation_setup (Ansible) installs a daily cron job
#   that backs up browser bookmarks to the pCloud path above.
#
# Arguments: none (interactive select prompts)
# Outputs:   status messages; exits non-zero on error or abort
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__restore_browser_bookmarks() {
    local backup_root="${HOME}/pCloudDrive/backups/browser_bookmarks"

    if [[ ! -d "$backup_root" ]]; then
        echo "ERROR: Backup root not found: $backup_root" >&2
        return 1
    fi

    # Browser → destination mappings
    declare -A _chromium_dest=(
        [chrome]="${HOME}/.config/google-chrome/Default/Bookmarks"
        [chromium]="${HOME}/.config/chromium/Default/Bookmarks"
        [brave]="${HOME}/.config/BraveSoftware/Brave-Browser/Default/Bookmarks"
        [vivaldi]="${HOME}/.config/vivaldi/Default/Bookmarks"
        [opera]="${HOME}/.config/opera/Bookmarks"
        [edge]="${HOME}/.config/microsoft-edge/Default/Bookmarks"
    )
    declare -A _firefox_root=(
        [firefox]="${HOME}/.mozilla/firefox"
        [zen]="${HOME}/.zen"
        [librewolf]="${HOME}/.librewolf"
        [waterfox]="${HOME}/.waterfox"
        [floorp]="${HOME}/.floorp"
    )

    # --- Select browser ---
    local browsers=()
    while IFS= read -r d; do browsers+=("$(basename "$d")"); done \
        < <(find "$backup_root" -mindepth 1 -maxdepth 1 -type d | sort)

    if [[ ${#browsers[@]} -eq 0 ]]; then
        echo "No backups found in $backup_root" >&2
        return 1
    fi

    echo "Select browser:"
    local browser
    select browser in "${browsers[@]}"; do
        [[ -n "$browser" ]] && break
    done

    # --- Select timestamp ---
    local timestamps=()
    while IFS= read -r d; do timestamps+=("$(basename "$d")"); done \
        < <(find "${backup_root}/${browser}" -mindepth 1 -maxdepth 1 -type d | sort -r)

    if [[ ${#timestamps[@]} -eq 0 ]]; then
        echo "No backups found for $browser" >&2
        return 1
    fi

    echo ""
    echo "Select backup to restore (newest first):"
    local ts
    select ts in "${timestamps[@]}"; do
        [[ -n "$ts" ]] && break
    done

    local src="${backup_root}/${browser}/${ts}"
    local safety_ts
    safety_ts=$(date --utc +'%Y%m%dT%H-%M-%SZ')

    echo ""
    echo "  Browser : $browser"
    echo "  Backup  : $ts"
    echo ""
    read -rp "Restore? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; return 0; }

    # --- Chromium-based ---
    if [[ -v _chromium_dest[$browser] ]]; then
        local dest="${_chromium_dest[$browser]}"
        local dest_dir
        dest_dir=$(dirname "$dest")

        if [[ -f "$dest" ]]; then
            local bak="${dest}.pre-restore.${safety_ts}.bak"
            cp "$dest" "$bak"
            echo "Saved current bookmarks → $bak"
        fi

        mkdir -p "$dest_dir"
        cp "${src}/Bookmarks" "$dest"
        echo "Restored $browser bookmarks from $ts."

    # --- Firefox-based ---
    elif [[ -v _firefox_root[$browser] ]]; then
        local profile_root="${_firefox_root[$browser]}"
        local profile
        profile=$(find "$profile_root" -mindepth 1 -maxdepth 1 -type d \
            \( -name "*.default" -o -name "*.default-*" -o -name "*.default-release" \) \
            | xargs -I{} stat --format="%Y {}" {} 2>/dev/null \
            | sort -rn | head -1 | awk '{print $2}')

        if [[ -z "$profile" || ! -d "$profile" ]]; then
            echo "ERROR: No profile found for $browser at $profile_root" >&2
            return 1
        fi

        echo ""
        echo "WARNING: $browser must be closed before restoring — SQLite may be locked."
        echo "  Profile: $profile"
        echo ""
        read -rp "Continue? [y/N] " confirm2
        [[ "$confirm2" =~ ^[Yy]$ ]] || { echo "Aborted."; return 0; }

        if [[ -f "${profile}/places.sqlite" ]]; then
            local bak="${profile}/places.sqlite.pre-restore.${safety_ts}.bak"
            cp "${profile}/places.sqlite" "$bak"
            echo "Saved current places.sqlite → $bak"
        fi

        [[ -f "${src}/places.sqlite" ]] \
            && cp "${src}/places.sqlite" "${profile}/places.sqlite"
        [[ -d "${src}/bookmarkbackups" ]] \
            && cp -r "${src}/bookmarkbackups/." "${profile}/bookmarkbackups/"

        echo "Restored $browser bookmarks from $ts."

    else
        echo "ERROR: Unknown browser type: $browser" >&2
        return 1
    fi
}