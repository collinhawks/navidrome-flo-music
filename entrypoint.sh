#!/bin/bash
set -e

echo "=========================================="
echo "Navidrome Startup with B2 Integration"
echo "=========================================="

# Ensure directories exist
mkdir -p /data /music /root/.config/rclone

# Check required environment variables
if [ -z "$B2_KEY_ID" ] || [ -z "$B2_APPLICATION_KEY" ] || [ -z "$B2_BUCKET_NAME" ]; then
    echo "ERROR: Missing required environment variables!"
    echo "Please set: B2_KEY_ID, B2_APPLICATION_KEY, B2_BUCKET_NAME"
    exit 1
fi

# Configure rclone for BackBlaze B2
echo "Configuring rclone for BackBlaze B2..."
cat > /root/.config/rclone/rclone.conf <<EOF
[b2]
type = b2
account = ${B2_KEY_ID}
key = ${B2_APPLICATION_KEY}
hard_delete = false
EOF
echo "✓ rclone configured"

# Test B2 connection
echo "Testing B2 connection..."
if rclone lsd b2:${B2_BUCKET_NAME} > /dev/null 2>&1; then
    echo "✓ B2 connection successful"
else
    echo "✗ B2 connection failed. Please check your credentials."
    exit 1
fi

# Restore database and data from B2 if exists
echo "Checking for existing database backup..."
if rclone lsf b2:${B2_BUCKET_NAME}/navidrome-database/navidrome.db > /dev/null 2>&1; then
    echo "Found existing database, restoring..."
    /scripts/restore.sh
else
    echo "No existing database found, starting fresh..."
fi

# Sync music folder from B2 (only download what's missing)
echo "Syncing music library from B2..."
echo "This may take a while on first run..."
rclone sync b2:${B2_BUCKET_NAME}/music /music \
    --transfers 4 \
    --checkers 8 \
    --fast-list \
    --use-server-modtime \
    --log-level INFO
echo "✓ Music library synced"

# Start periodic backup in background
/scripts/periodic-backup.sh &
BACKUP_PID=$!

# Start Navidrome
echo "=========================================="
echo "Starting Navidrome..."
echo "=========================================="

# Set environment variables for Navidrome
export ND_MUSICFOLDER=/music
export ND_DATAFOLDER=/data
export ND_LOGLEVEL=info
export ND_PORT=${PORT:-4533}
export ND_ADDRESS=0.0.0.0
export ND_BASEURL=""

# Function to backup on shutdown
cleanup() {
    echo ""
    echo "=========================================="
    echo "Shutting down, creating final backup..."
    echo "=========================================="
    
    # Kill background backup process
    kill $BACKUP_PID 2>/dev/null || true
    
    # Final backup
    if [ -f /data/navidrome.db ]; then
        /scripts/backup.sh
    fi
    
    echo "Shutdown complete"
}

# Set trap to backup on container shutdown
trap cleanup SIGTERM SIGINT EXIT

# Start Navidrome in background so we can trap signals
/app/navidrome &
NAVIDROME_PID=$!

# Wait for Navidrome to exit
wait $NAVIDROME_PID
