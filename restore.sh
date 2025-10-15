#!/bin/bash
set -e

echo "Starting restore from B2..."

# Download database from B2
if rclone lsf b2:${B2_BUCKET_NAME}/navidrome-database/navidrome.db > /dev/null 2>&1; then
    echo "Downloading database from B2..."
    rclone copy b2:${B2_BUCKET_NAME}/navidrome-database/navidrome.db /data/ \
        --log-level INFO
    echo "✓ Database restored"
else
    echo "No database found in B2, starting fresh"
fi

# Download cache from B2 if exists
if rclone lsd b2:${B2_BUCKET_NAME}/navidrome-database/cache > /dev/null 2>&1; then
    echo "Downloading cache from B2..."
    rclone sync b2:${B2_BUCKET_NAME}/navidrome-database/cache/ /data/cache/ \
        --log-level INFO
    echo "✓ Cache restored"
else
    echo "No cache found in B2, will be created fresh"
fi

echo "✓ Restore completed successfully"
