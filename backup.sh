#!/bin/bash
# Kash - Automated Backup Script
# This script backs up the database, receipts, and environment variables.

# --- Configuration ---
BACKUP_DIR="/tmp/kash_backups"
DATA_DIR="/opt/kash/data"
ENV_FILE="/opt/kash/.env"
NAS_MOUNT="/mnt/nas_backup"        # This should be mapped in Proxmox
RCLONE_REMOTE="vps_remote"         # The name of your rclone remote
RETENTION_DAYS=7
DATE=$(date +%Y-%m-%d_%H%M%S)
BACKUP_NAME="kash_backup_$DATE"

# --- Setup ---
mkdir -p "$BACKUP_DIR"
echo "Starting backup: $BACKUP_NAME"

# 1. Consistent SQLite Backup
# We use the sqlite3 CLI .backup command to ensure we don't copy a database mid-write
if command -v sqlite3 &>/dev/null; then
    echo "Dumping database..."
    sqlite3 "$DATA_DIR/expenses.db" ".backup $BACKUP_DIR/expenses.db"
else
    echo "WARNING: sqlite3 not found, doing a standard copy (less safe)..."
    cp "$DATA_DIR/expenses.db" "$BACKUP_DIR/expenses.db"
fi

# 2. Create Archive
echo "Creating archive..."
tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" \
    -C "$BACKUP_DIR" "expenses.db" \
    -C "/opt/kash" "data/receipts" \
    -C "/opt/kash" ".env"

# 3. Copy to NAS (if mounted)
if mountpoint -q "$NAS_MOUNT"; then
    echo "Copying to NAS at $NAS_MOUNT..."
    cp "$BACKUP_DIR/$BACKUP_NAME.tar.gz" "$NAS_MOUNT/"
    # Prune old backups on NAS
    find "$NAS_MOUNT" -name "kash_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
else
    echo "WARNING: NAS mount at $NAS_MOUNT not found or not active. Skipping NAS backup."
    echo "To fix: Run 'pct set ID -mp0 /mnt/pve/YOUR_STORAGE,mp=/mnt/nas_backup' on Proxmox host."
fi

# 4. Sync to VPS via rclone
if command -v rclone &>/dev/null; then
    echo "Syncing to VPS via rclone remote '$RCLONE_REMOTE'..."
    rclone copy "$BACKUP_DIR/$BACKUP_NAME.tar.gz" "$RCLONE_REMOTE:kash_backups/"
else
    echo "WARNING: rclone not installed. Skipping VPS backup."
    echo "To fix: Run 'apt install rclone' inside the container."
fi

# 5. Cleanup
echo "Cleaning up local temporary files..."
rm -f "$BACKUP_DIR/expenses.db"
# We keep the local tar.gz in /tmp just in case, but it will be wiped on reboot or next run.

echo "Backup completed successfully at $(date)"
