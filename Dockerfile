FROM deluan/navidrome:latest

# Install rclone and curl
RUN apk add --no-cache rclone curl

# Create main entrypoint
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
RUN echo '# Start Navidrome in background and backup script in foreground' >> /entrypoint.sh
RUN echo 'echo "Starting Navidrome..."' >> /entrypoint.sh
RUN echo '/app/navidrome --musicfolder "/music" --datafolder "/data" --port "4533" &' >> /entrypoint.sh
RUN echo '' >> /entrypoint.sh
RUN echo '# Start a simple HTTP server for backup triggers' >> /entrypoint.sh
RUN echo 'while true; do' >> /entrypoint.sh
RUN echo '    echo "Backup server running on port 8080... use GET /backup to trigger backup"' >> /entrypoint.sh
RUN echo '    echo -e "HTTP/1.1 200 OK\n\nBackup triggered" | nc -l -p 8080 -q 1' >> /entrypoint.sh
RUN echo '    echo "Manual backup triggered..."' >> /entrypoint.sh
RUN echo '    rclone sync /data b2-music:navidrome-database -v' >> /entrypoint.sh
RUN echo '    echo "Backup completed!"' >> /entrypoint.sh
RUN echo 'done' >> /entrypoint.sh

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
