FROM deluan/navidrome:latest

# Install rclone, curl, and netcat (nc)
# Use 'netcat-openbsd' for the reliable 'nc' binary on Alpine Linux (used by navidrome base)
RUN apk add --no-cache rclone curl netcat-openbsd && \
    mkdir -p /root/.config/rclone

# Use a single RUN command to create the executable entrypoint script via a heredoc
RUN cat > /entrypoint.sh << 'EOF'
#!/bin/sh
# Shell commands must be inside this heredoc block

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
/app/navidrome --musicfolder "/music" --datafolder "/data" --port "4533" &

# Start a simple HTTP server for backup triggers
while true; do
    echo "Backup server running on port 8080... use GET /backup to trigger backup"
    # The 'nc' command is now available via 'netcat-openbsd'
    echo -e "HTTP/1.1 200 OK\n\nBackup triggered" | nc -l -p 8080 -q 1
    echo "Manual backup triggered..."
    rclone sync /data b2-music:navidrome-database -v
    echo "Backup completed!"
done
EOF

# Ensure the script is executable
RUN chmod +x /entrypoint.sh

# The correct way to run your custom script, replacing the base image's ENTRYPOINT
ENTRYPOINT ["/entrypoint.sh"]
CMD []
