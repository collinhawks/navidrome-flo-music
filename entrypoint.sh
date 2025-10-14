#!/bin/sh
set -e

echo "📀 Creating rclone config..."
mkdir -p /root/.config/rclone
cat <<EOF >/root/.config/rclone/rclone.conf
[b2]
type = b2
account = ${B2_ACCOUNT_ID}
key = ${B2_APPLICATION_KEY}
EOF

# Restore Navidrome database
echo "📂 Restoring Navidrome database..."
rclone copy b2:${B2_BUCKET}/navidrome-database /data || echo "No existing database found."

# Sync music files from B2 (skips already-synced songs)
echo "🎵 Syncing music files..."
rclone sync b2:${B2_BUCKET}/your-music-folder /music || echo "Music sync failed or empty."

# Start Navidrome
echo "🚀 Starting Navidrome..."
/app/navidrome &

# Start lightweight HTTP backup endpoint
echo "🌐 Starting backup trigger server on port 10000..."
(
  while true; do
    nc -l -p 10000 | while read line; do
      echo "$line" | grep "GET /backup" >/dev/null && {
        echo "📦 Manual backup triggered"
        /backup.sh
        printf "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nBackup complete.\n"
      } || printf "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nNavidrome Backup Service Running.\n"
    done
  done
) &

# Automatic backup every 6 hours
while true; do
  echo "🕒 Running scheduled backup..."
  /backup.sh
  sleep 21600
done
