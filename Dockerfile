FROM deluan/navidrome:latest

# Switch to root to install packages and setup
USER root

# Install rclone for B2 sync and other utilities
RUN apk add --no-cache rclone curl bash sqlite

# Create necessary directories with wide permissions (entrypoint will handle them)
RUN mkdir -p /data /music /backup /scripts && \
    chmod -R 777 /data /music /backup /scripts

# Copy scripts and config
COPY entrypoint.sh /scripts/entrypoint.sh
COPY backup.sh /scripts/backup.sh
COPY restore.sh /scripts/restore.sh
COPY periodic-backup.sh /scripts/periodic-backup.sh
COPY navidrome.toml /data/navidrome.toml

# Make scripts executable
RUN chmod +x /scripts/*.sh

# Set working directory
WORKDIR /app

# Run as root to avoid permission issues
USER root

# Use custom entrypoint
ENTRYPOINT ["/bin/bash", "/scripts/entrypoint.sh"]
