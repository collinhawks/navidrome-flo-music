# Use official Navidrome image as base
FROM deluan/navidrome:latest

# Install rclone and curl (for backup sync)
RUN apk add --no-cache rclone curl

# Copy in your custom startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Render will automatically call this on startup
ENTRYPOINT ["/entrypoint.sh"]
