#!/bin/sh
set -e

PORT=${PORT:-4533}
NAVIDROME_PORT=4533

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

# Start Navidrome on an internal port
echo "🚀 Starting Navidrome (internal port $NAVIDROME_PORT)..."
(/app/navidrome --musicfolder "/music" --datafolder "/data" --port "$NAVIDROME_PORT") &

# Periodic background backups
( while true; do
    echo "🕒 Waiting 6 hours for next backup..."
    sleep 21600
    echo "☁️ Performing scheduled backup..."
    /backup.sh
done ) &

# Create mini HTTP proxy + /backup handler using busybox httpd
echo "🌐 Starting combined HTTP server on port $PORT..."

# Index page
mkdir -p /www
cat > /www/index.html <<HTML
<!DOCTYPE html>
<html>
  <body style="font-family:sans-serif;">
    <h2>Navidrome + Backblaze B2</h2>
    <p>✅ Navidrome is running.</p>
    <p><a href="/backup">Trigger Backup Now</a></p>
  </body>
</html>
HTML

# Start HTTP server (main process)
busybox httpd -f -p $PORT -h /www -r "Navidrome" -v &

# Simple loop to handle requests manually
# (since BusyBox has no built-in proxying)
while true; do
  # Read one line of the incoming request
  REQUEST=$(nc -l -p $PORT -q 1 | head -n 1)
  if echo "$REQUEST" | grep -q "GET /backup"; then
    echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nBackup started...\n"
    /backup.sh >/dev/null 2>&1 &
  else
    # Proxy everything else to Navidrome
    curl -s http://127.0.0.1:$NAVIDROME_PORT
  fi
done
