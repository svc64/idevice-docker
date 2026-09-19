#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || -z "${1:-}" ]]; then
    echo "Usage: $0 <UDID>" >&2
    exit 1
fi

if [[ -z "${BACKUPS_DIR:-}" ]]; then
    echo "Error: BACKUPS_DIR is not set." >&2
    exit 1
fi
mkdir -p ${BACKUPS_DIR}

UDID="$1"
echo "Using device UDID: $UDID"
LOCK_FILE="${BACKUPS_DIR}/${UDID}.lock"

exec 9>"$LOCK_FILE"

if ! flock -n 9; then
    echo "Another instance is already running for UDID ${UDID}" >&2
    exit 1
fi

while pymobiledevice3 lockdown date; do # Just check if the device remains online
    # BACKUP_TIME is an interval in seconds; default is one hour.
    BACKUP_TIME="${BACKUP_TIME:-3600}"

    last_run_file="${BACKUPS_DIR}/${UDID}.lastrun"
    last_run=0

    if [[ -f "$last_run_file" ]]; then
        last_run="$(<"$last_run_file")"
    fi

    now="$(date +%s)"

    time_since_backup=$(( now - last_run ))
    if (( time_since_backup < BACKUP_TIME )); then
        echo "Backup ran less than ${BACKUP_TIME} seconds ago, waiting..."
        sleep $(( BACKUP_TIME - time_since_backup ))
    fi

    export PYMOBILEDEVICE3_UDID=${UDID}
    pymobiledevice3 lockdown date || { echo "Device not connected..."; exit 0; }

    # Delete in progress backup...
    rm -rf "${BACKUPS_DIR}/${UDID}.backup.inprogress"

    if pymobiledevice3 backup2 backup "${BACKUPS_DIR}/${UDID}.backup.inprogress"; then
        if [ -d "${BACKUPS_DIR}/${UDID}.backup" ]; then
            mv "${BACKUPS_DIR}/${UDID}.backup" "${BACKUPS_DIR}/${UDID}.backup.deleteme.${now}"
        fi
        mv "${BACKUPS_DIR}/${UDID}.backup.inprogress" "${BACKUPS_DIR}/${UDID}.backup"
        if compgen -G "${BACKUPS_DIR}/${UDID}.backup.deleteme.*" > /dev/null; then
            rm -rf "${BACKUPS_DIR}/${UDID}.backup.deleteme."*
        fi
    else
        echo "Backup failed for ${UDID} (exit $?), keeping previous backup" >&2
    fi

    printf '%s\n' "$now" > "$last_run_file"
done
