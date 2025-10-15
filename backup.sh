#!/bin/bash
set -e

echo "Starting backup to B2..."

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/tmp/backup_${TIMESTAMP}"

# Create temporary backup directory
mkdir -p ${BACKUP_DIR}

# Backup database
if [ -f /data/navidrome.db ]; then
    echo "Backing up database..."
    
    # Create SQLite backup (handles locked databases)
    sqlite3 /data/navidrome.db ".backup '${BACKUP_DIR}/navidrome.db'"
    
    # Also backup the main database to timestamped version
    cp ${BACKUP_DIR}/navidrome.db ${BACKUP_DIR}/navidrome_${TIMESTAMP}.db
    
    echo "✓ Database backed up"
fi

# Backup cache and other data files
if [ -d /data/cache ]; then
    echo "Backing up cache..."
    cp -r /data/cache ${BACKUP_DIR}/
fi

# Upload current database to B2
if [ -f ${BACKUP_DIR}/navidrome.db ]; then
    echo "Uploading current database to B2..."
    rclone copy ${BACKUP_DIR}/navidrome.db b2:${B2_BUCKET_NAME}/navidrome-database/ \
        --log-level INFO
    echo "✓ Current database uploaded"
fi

# Upload timestamped backup to B2
if [ -f ${BACKUP_DIR}/navidrome_${TIMESTAMP}.db ]; then
    echo "Uploading timestamped backup to B2..."
    rclone copy ${BACKUP_DIR}/navidrome_${TIMESTAMP}.db b2:${B2_BUCKET_NAME}/navidrome-database/backups/ \
        --log-level INFO
    echo "✓ Timestamped backup uploaded"
fi

# Upload cache if exists
if [ -d ${BACKUP_DIR}/cache ]; then
    echo "Uploading cache to B2..."
    rclone sync ${BACKUP_DIR}/cache b2:${B2_BUCKET_NAME}/navidrome-database/cache/ \
        --log-level INFO
    echo "✓ Cache uploaded"
fi

# Cleanup old backups (keep last 7 days)
echo "Cleaning up old backups (keeping last 7 days)..."
CUTOFF_DATE=$(date -d "7 days ago" +"%Y%m%d" 2>/dev/null || date -v-7d +"%Y%m%d")
rclone delete b2:${B2_BUCKET_NAME}/navidrome-database/backups/ \
    --min-age 7d \
    --log-level INFO || echo "Note: Some old backups may remain"

# Cleanup local temporary backup
rm -rf ${BACKUP_DIR}

echo "✓ Backup completed successfully"
