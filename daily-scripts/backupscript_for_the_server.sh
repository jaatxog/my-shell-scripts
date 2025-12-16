#!/bin/bash

# ====== CONFIG ======
BACKUP_DIR="/path/to/backup_dir"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="$BACKUP_DIR/backup_log.txt"

# ====== CREATE BACKUP DIRECTORY IF NOT EXISTS ======
mkdir -p "$BACKUP_DIR"

# ====== LOG ROTATION (1MB) ======
LOG_MAX_SIZE=1048576
if [ -f "$LOG_FILE" ] && [ "$(stat -c%s "$LOG_FILE")" -gt "$LOG_MAX_SIZE" ]; then
    mv "$LOG_FILE" "$LOG_FILE.old"
fi

# ====== DATABASE CHECK ======
mysqlcheck -u db_user -p'DB_PASSWORD' --auto-repair --optimize --all-databases
if [ $? -ne 0 ]; then
    echo "Database check failed" >> "$LOG_FILE"
    exit 1
fi

# ====== DATABASE BACKUP ======
mysqldump -u db_user -p'DB_PASSWORD' database_name \
> "$BACKUP_DIR/db_backup_$TIMESTAMP.sql"
if [ $? -ne 0 ]; then
    echo "Database dump failed" >> "$LOG_FILE"
    exit 1
fi

# ====== CONFIG FILE BACKUPS ======
cp /etc/application/config1.conf \
"$BACKUP_DIR/config1_$TIMESTAMP.conf" || exit 1

cp /etc/application/config2.conf \
"$BACKUP_DIR/config2_$TIMESTAMP.conf" || exit 1

# ====== APPLICATION DATA BACKUPS ======
tar -czf "$BACKUP_DIR/web_data_$TIMESTAMP.tar.gz" \
-C /var/www application || exit 1

tar -czf "$BACKUP_DIR/app_scripts_$TIMESTAMP.tar.gz" \
-C /var/lib/application scripts || exit 1

tar -czf "$BACKUP_DIR/app_assets_$TIMESTAMP.tar.gz" \
-C /var/lib/application assets || exit 1

# ====== CRONTAB BACKUP ======
crontab -l > "$BACKUP_DIR/crontab_$TIMESTAMP.txt"
if [ $? -ne 0 ]; then
    echo "Crontab export failed" >> "$LOG_FILE"
    exit 1
fi

# ====== CLEANUP OLD BACKUPS (OLDER THAN 2 DAYS) ======
find "$BACKUP_DIR" -type f -mtime +2 -delete

# ====== SYSTEM INFO ======
df -h / | tail -n 1 > "$BACKUP_DIR/system_disk_usage.txt"

# ====== LOGGING ======
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Backup completed: $TIMESTAMP" >> "$LOG_FILE"

