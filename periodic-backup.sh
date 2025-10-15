#!/bin/bash

# Periodic backup script - runs in background

echo "Starting periodic backup service..."

# Wait for Navidrome to be fully started and database to exist
sleep 60

while true; do
    if [ -f /data/navidrome.db ]; then
        echo ""
        echo "=========================================="
        echo "Running periodic backup (every 30 minutes)"
        echo "=========================================="
        /scripts/backup.sh
    fi
    
    # Backup every 30 minutes
    sleep 1800
done
