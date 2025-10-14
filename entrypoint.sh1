#!/bin/sh
set -e

echo "📀 Creating rclone config..."
mkdir -p /root/.config/rclone
cat > /root/.config/rclone/rclone.conf <<EOF
[b2-music]
type = s3
provider = Other
env_auth = false
access_key_id = ${S3_ACCESS_KEY_ID}
secret_access_key = ${S3_SECRET_ACCESS_KEY}
endpoint = ${S3_ENDPOINT}
region = ${S3_REGION}
EOF

echo "📂 Restoring Navidrome database..."
rclone sync b2-music:navidrome-database /data 2>/dev/null || echo "No existing database found."

echo "🎵 Syncing music files..."
rclone sync b2-music:music /music || echo "Music sync failed or empty."

# Start lightweight HTTP server for manual backups
echo "🌐 Starting backup trigger server on port 8080..."
mkdir -p /www
cat > /www/index.html <<HTML
<!DOCTYPE html>
<html>
  <body style="font-family:sans-serif;">
    <h2>Navidrome Backup</h2>
    <p><a href="/backup">Trigger Backup Now</a></p>
  </body>
</html>
HTML

# Run a simple CGI handler to process /backup
busybox httpd -f -p 8080 -h /www -c /backup.sh &

# Start periodic backup every 6 hours
( while true; do
    echo "🕒 Waiting 6 hours for next backup..."
    sleep 21600
    echo "☁️ Automatic backup started..."
    /backup.sh
done ) &

# Start Navidrome in foreground
echo "🚀 Starting Navidrome..."
exec /app/navidrome --musicfolder "/music" --datafolder "/data" --port "${PORT:-4533}"
