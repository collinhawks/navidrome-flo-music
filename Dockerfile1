FROM deluan/navidrome:latest

# Install rclone
RUN apk add --no-cache rclone

# Create entrypoint script step by step
RUN echo '#!/bin/sh' > /entrypoint.sh
RUN echo 'echo "Environment variables:"' >> /entrypoint.sh
RUN echo 'echo "S3_ACCESS_KEY_ID: ${S3_ACCESS_KEY_ID:0:10}..."' >> /entrypoint.sh
RUN echo 'echo "S3_ENDPOINT: $S3_ENDPOINT"' >> /entrypoint.sh
RUN echo 'echo "S3_BUCKET: $S3_BUCKET"' >> /entrypoint.sh
RUN echo 'mkdir -p /root/.config/rclone' >> /entrypoint.sh

# Add rclone config
RUN echo 'cat > /root/.config/rclone/rclone.conf << EOC' >> /entrypoint.sh
RUN echo '[b2-music]' >> /entrypoint.sh
RUN echo 'type = s3' >> /entrypoint.sh
RUN echo 'provider = Other' >> /entrypoint.sh
RUN echo 'env_auth = false' >> /entrypoint.sh
RUN echo 'access_key_id = ${S3_ACCESS_KEY_ID}' >> /entrypoint.sh
RUN echo 'secret_access_key = ${S3_SECRET_ACCESS_KEY}' >> /entrypoint.sh
RUN echo 'endpoint = ${S3_ENDPOINT}' >> /entrypoint.sh
RUN echo 'region = ${S3_REGION}' >> /entrypoint.sh
RUN echo 'EOC' >> /entrypoint.sh

# Add sync and navidrome start
RUN echo 'echo "Syncing music..."' >> /entrypoint.sh
RUN echo 'rclone sync b2-music:${S3_BUCKET} /music --config /root/.config/rclone/rclone.conf -v' >> /entrypoint.sh
RUN echo 'echo "Starting Navidrome..."' >> /entrypoint.sh
RUN echo 'exec /app/navidrome "$@"' >> /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
