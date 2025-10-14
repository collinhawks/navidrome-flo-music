FROM deluan/navidrome:latest

# Install rclone (Alpine package manager should work)
RUN apk add --no-cache rclone

# Create a proper entrypoint script
RUN echo '#!/bin/sh
set -e

# Mount Backblaze if environment variables are set
if [ -n "$S3_ACCESS_KEY_ID" ] && [ -n "$S3_SECRET_ACCESS_KEY" ]; then
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
    mkdir -p /music
    rclone mount b2-music:${S3_BUCKET} /music --daemon --allow-other &
    sleep 5
fi

# Start Navidrome with all arguments
exec /app/navidrome "$@"
' > /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["--musicfolder", "/music", "--datafolder", "/data", "--port", "4533"]
