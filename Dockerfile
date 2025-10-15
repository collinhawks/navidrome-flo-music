FROM deluan/navidrome:latest

# Install rclone for B2 sync and other utilities
USER root
RUN apk add --no-cache rclone curl bash sqlite

# Create necessary directories with proper permissions
RUN mkdir -p /data /music /backup /scripts && \
    chown -R navidrome:navidrome /data /music /backup /scripts

# Copy scripts
COPY entrypoint.sh /scripts/entrypoint.sh
COPY backup.sh /scripts/backup.sh
COPY restore.sh /scripts/restore.sh
COPY navidrome.toml /data/navidrome.toml

# Make scripts executable
RUN chmod +x /scripts/*.sh && \
    chown navidrome:navidrome /data/navidrome.toml

# Set working directory
WORKDIR /app

# Switch back to navidrome user
USER navidrome

# Use custom entrypoint
ENTRYPOINT ["/bin/bash", "/scripts/entrypoint.sh"]
