FROM deluan/navidrome:latest

# Install rclone
RUN apk add --no-cache rclone

# Create entrypoint script line by line
RUN echo '#!/bin/sh' > /entrypoint.sh
RUN echo 'set -e' >> /entrypoint.sh
RUN echo '' >> /entrypoint.sh
RUN echo '# Create rclone config' >> /entrypoint.sh
RUN echo 'mkdir -p /root/.config/rclone' >> /entrypoint.sh
RUN echo 'cat > /root/.config/rclone/rclone.conf << EOF' >> /entrypoint.sh
RUN echo '[b2-music]' >> /entrypoint.sh
RUN echo 'type = s3' >> /entrypoint.sh
RUN echo 'provider = Other' >> /entrypoint.sh
RUN echo 'env_auth = false' >> /entrypoint.sh
RUN echo 'access_key_id = ${S3_ACCESS_KEY_ID}' >> /entrypoint.sh
RUN echo 'secret_access_key = ${S3_SECRET_ACCESS_KEY}' >> /entrypoint.sh
RUN echo 'endpoint = ${S3_ENDPOINT}' >> /entrypoint.sh
RUN echo 'region = ${S3_REGION}' >> /entrypoint.sh
RUN echo 'EOF' >> /entrypoint.sh
RUN echo '' >> /entrypoint.sh
RUN echo '# Sync database FROM Backblaze (restore)' >> /entrypoint.sh
RUN echo 'echo "Restoring database from Backblaze..."' >> /entrypoint.sh
RUN echo 'rclone sync b2-music:navidrome-database /data 2>/dev/null || echo "No existing database found, starting fresh"' >> /entrypoint.sh
RUN echo '' >> /entrypoint.sh
RUN echo '# Sync music FROM Backblaze' >> /entrypoint.sh
RUN echo 'echo "Syncing music from Backblaze..."' >> /entrypoint.sh
RUN echo 'rclone sync b2-music:${S3_BUCKET} /music' >> /entrypoint.sh
RUN echo '' >> /entrypoint.sh
RUN echo '# Start Navidrome in background' >> /entrypoint.sh
RUN echo 'echo "Starting Navidrome..."' >> /entrypoint.sh
RUN echo '/app/navidrome --musicfolder "/music" --datafolder "/data" --port "4533" &' >> /entrypoint.sh
RUN echo 'NAVIDROME_PID=$!' >> /entrypoint.sh
RUN echo '' >> /entrypoint.sh
RUN echo '# Function to backup database' >> /entrypoint.sh
RUN echo 'backup_database() {' >> /entrypoint.sh
RUN echo '    echo "Backing up database to Backblaze..."' >> /entrypoint.sh
RUN echo '    rclone sync /data b2-music:navidrome-database' >> /entrypoint.sh
RUN echo '}' >> /entrypoint.sh
RUN echo '' >> /entrypoint.sh
RUN echo '# Setup trap to backup on exit' >> /entrypoint.sh
RUN echo 'trap backup_database EXIT' >> /entrypoint.sh
RUN echo '' >> /entrypoint.sh
RUN echo '# Wait for Navidrome and backup every hour' >> /entrypoint.sh
RUN echo 'while kill -0 $NAVIDROME_PID 2>/dev/null; do' >> /entrypoint.sh
RUN echo '    sleep 3600' >> /entrypoint.sh
RUN echo '    backup_database' >> /entrypoint.sh
RUN echo 'done' >> /entrypoint.sh

RUN chmod +x /entrypoint.sh

# Use CMD instead of ENTRYPOINT
CMD ["/entrypoint.sh"]
