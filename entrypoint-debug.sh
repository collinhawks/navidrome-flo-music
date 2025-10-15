#!/bin/bash
set -e

echo "=========================================="
echo "Navidrome Startup - Debug Mode"
echo "=========================================="

# Print environment for debugging (without secrets)
echo "PORT: ${PORT}"
echo "B2_BUCKET_NAME: ${B2_BUCKET_NAME}"
echo "B2_KEY_ID set: $([ -n "$B2_KEY_ID" ] && echo 'yes' || echo 'no')"
echo "B2_APPLICATION_KEY set: $([ -n "$B2_APPLICATION_KEY" ] && echo 'yes' || echo 'no')"

# Check if running as correct user
echo "Current user: $(whoami)"
echo "User ID: $(id -u)"

# Ensure directories exist
mkdir -p /data /music
echo "✓ Directories created"

# List directory permissions
ls -la /data /music || echo "Could not list directories"

# Try to start Navidrome without B2 sync first
echo "=========================================="
echo "Starting Navidrome (without B2 sync for testing)"
echo "=========================================="

export ND_MUSICFOLDER=/music
export ND_DATAFOLDER=/data
export ND_LOGLEVEL=info
export ND_PORT=${PORT:-4533}
export ND_BASEURL=""
export ND_SCANSCHEDULE=""  # Disable initial scan for faster startup

echo "Navidrome configuration:"
echo "  Music Folder: $ND_MUSICFOLDER"
echo "  Data Folder: $ND_DATAFOLDER"
echo "  Port: $ND_PORT"

# Start Navidrome
exec /app/navidrome
