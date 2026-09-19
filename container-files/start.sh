#!/usr/bin/env bash

if [[ -v BACKUP_SERVER ]]; then
    echo "Starting iDevice backup server"
    export BACKUPS_DIR=/data/idevice-backups
    # anti command injection quoting
    exec netmuxd --on-net-discover "/device-backup.sh '%udid%'"
else
    echo "BACKUP_SERVER not set, dropping to shell"
    exec bash
fi
