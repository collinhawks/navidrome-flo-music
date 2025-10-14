# Use official Navidrome image as base
FROM deluan/navidrome:latest

# Install rclone and busybox (for HTTP server)
RUN apk add --no-cache rclone busybox-extras curl

# Copy startup and backup scripts
COPY entrypoint.sh /entrypoint.sh
COPY backup.sh /backup.sh
RUN chmod +x /entrypoint.sh /backup.sh

ENTRYPOINT ["/entrypoint.sh"]
