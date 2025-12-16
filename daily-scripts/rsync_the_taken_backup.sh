#!/bin/bash

#Prerequisites
#SSH Key-Based Authentication
#ssh-keygen -t rsa
#ssh-copy-id backup_user@backup.example.com
#
#Required Packages
#apt install -y rsync      # Debian/Ubuntu
#yum install -y rsync      # RHEL/CentOS
#
#Permissions
#chmod +x rsync_backup.sh
#
#Cron Job (Daily)
#
#Example: run daily at 02:00 AM
#
#0 2 * * * /path/to/rsync_backup.sh

# ====== CONFIG ======
LOCAL_BACKUP_DIR="/path/to/local/backup/"
REMOTE_USER="backup_user"
REMOTE_HOST="backup.example.com"
REMOTE_DIR="/path/to/remote/backup/"
LOG_FILE="/var/log/rsync_backup.log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# ====== ENSURE REMOTE DIRECTORY EXISTS ======
ssh "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p ${REMOTE_DIR}"

# ====== LOG ROTATION (1MB) ======
if [ -f "$LOG_FILE" ] && [ "$(stat -c%s "$LOG_FILE")" -ge 1048576 ]; then
    mv "$LOG_FILE" "${LOG_FILE}.old"
    touch "$LOG_FILE"
fi

# ====== RSYNC BACKUP ======
echo "[$TIMESTAMP] Starting rsync backup..." >> "$LOG_FILE"

rsync -azP -e ssh "$LOCAL_BACKUP_DIR" \
"${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}" >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo "[$TIMESTAMP] Backup completed successfully." >> "$LOG_FILE"
else
    echo "[$TIMESTAMP] Backup failed. Retrying in 30 seconds..." >> "$LOG_FILE"
    sleep 30

    rsync -azP -e ssh "$LOCAL_BACKUP_DIR" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}" >> "$LOG_FILE" 2>&1

    if [ $? -eq 0 ]; then
        echo "[$TIMESTAMP] Retry successful." >> "$LOG_FILE"
    else
        echo "[$TIMESTAMP] Retry failed." >> "$LOG_FILE"
    fi
fi

