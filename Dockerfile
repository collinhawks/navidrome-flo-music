FROM deluan/navidrome:latest

# Install rclone
RUN apk add --no-cache rclone

# Create the entrypoint script using HEREDOC
RUN cat > /entrypoint.sh << 'EOF'
#!/bin/sh

echo "Environment variables:"
echo "S3_ACCESS_KEY_ID: ${S3_ACCESS_KEY_ID:0:10}..."  
echo "S3_ENDPOINT: $S3_ENDPOINT"
echo "S3_BUCKET: $S3_BUCKET"

# Create rclone config
mkdir -p /root/.config/rclone
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

echo "Rclone config created. Testing connection..."
rclone ls b2-music:${S3_BUCKET} --config /root/.config/rclone/rclone.conf

echo "Syncing music..."
rclone sync b2-music:${S3_BUCKET} /music --config /root/.config/rclone/rclone.conf -v

echo "Contents of /music after sync:"
ls -la /music/

# Start Navidrome
echo "Starting Navidrome..."
exec /app/navidrome "$@"
EOF

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
