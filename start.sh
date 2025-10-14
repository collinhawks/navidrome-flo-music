#!/bin/bash

# Create rclone configuration
mkdir -p /root/.config/rclone
cat > /root/.config/rclone/rclone.conf << EOF
[b2-music]
type = s3
provider = Other
env_auth = false
access_key_id = ${S3_ACCESS_KEY_ID}
secret_access_key = ${S3_SECRET_ACCESS_KEY}
endpoint = ${S3_ENDPOINT}
region = ${S3_REGION}
EOF

# Mount Backblaze bucket
echo "Mounting Backblaze B2 bucket..."
rclone mount b2-music:${S3_BUCKET} /music --daemon --allow-other --vfs-cache-mode writes

# Wait for mount to establish
sleep 5

# Start Navidrome
echo "Starting Navidrome..."
exec /app/navidrome --musicfolder "/music" --datafolder "/data" --port "8080" --loglevel "info"
