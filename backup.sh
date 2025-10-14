#!/bin/sh
echo "Content-Type: text/plain"
echo ""

echo "Starting backup..."
rclone sync /data b2-music:navidrome-database -v
echo "Backup complete!"
