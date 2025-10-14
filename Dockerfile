FROM deluan/navidrome:latest

# Install rclone and curl
RUN apk add --no-cache rclone curl netcat-openbsd

# Fix: Use 'netcat-openbsd' which provides 'nc' on Alpine Linux, which the base image uses.
# The original image might not have had a simple 'nc' available, leading to runtime issues.
# Also, simplify the entrypoint creation using a heredoc for readability.

# Create main entrypoint script
# Use a single RUN layer for efficiency
RUN mkdir -p /root/.config/rclone && \
    cat > /entrypoint.sh << 'EOF'
#!/bin/sh
set -e

# Create rclone config
cat > /root/.config/rclone/rclone.conf << EOC
[b2-music]
type = s3
provider = Other
env_auth = false
access_key_id = ${S3_ACCESS_KEY_ID}
secret_access_key = ${S3_SECRET_ACCESS_KEY}
endpoint = ${S3_ENDPOINT}
region = ${S3_REGION}
EOC

# Sync database FROM Backblaze (restore)
echo "Restoring database from Backblaze..."
rclone sync b2-music:navidrome-database /data 2>/dev/null || echo "No existing database found, starting fresh"

# Sync music FROM Backblaze
echo "Syncing music from Backblaze..."
rclone sync b2-music:${S3_BUCKET} /music

# Start Navidrome in background and backup script in foreground
echo "Starting Navidrome..."
# Note: Navidrome will be running on port 4533 inside the container.
# Render will map this to a public port.
/app/navidrome --musicfolder "/music" --datafolder "/data" --port "4533" &

# Start a simple HTTP server for backup triggers
while true; do
    echo "Backup server running on port 8080... use GET /backup to trigger backup"
    # Use 'nc -l -p 8080 -e /bin/sh -c' for a single-connection listener
    # -e is often more reliable for this pattern, but if not available, the pipe can work too
    # Assuming 'nc' is netcat-openbsd from the 'netcat-openbsd' package.
    # The original script's use of 'nc -l -p 8080 -q 1' is correct for Alpine/BusyBox's nc.
    echo -e "HTTP/1.1 200 OK\n\nBackup triggered" | nc -l -p 8080 -q 1
    echo "Manual backup triggered..."
    # The /data folder contains the SQLite DB and cache, which is what you want to backup.
    rclone sync /data b2-music:navidrome-database -v
    echo "Backup completed!"
done
EOF

RUN chmod +x /entrypoint.sh

# The fix: Overwrite the base image's ENTRYPOINT with your script.
# This ensures *only* your script is run first, not appended as an argument to 'navidrome'.
ENTRYPOINT ["/entrypoint.sh"]

# Keep CMD empty or set it to a default argument if your entrypoint was designed to take one.
# An empty CMD is often sufficient when the ENTRYPOINT is a full script.
CMD []
