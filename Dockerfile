FROM deluan/navidrome:latest

# Install rclone from Debian repositories (more stable)
RUN apt-get update && apt-get install -y rclone fuse

# Create startup script
RUN echo '#!/bin/bash\n\
mkdir -p /music\n\
rclone mount b2-music:navidrome-flo-music /music --daemon --allow-other\n\
sleep 5\n\
/app/navidrome --musicfolder "/music" --datafolder "/data" --port "4533"\n\
' > /start.sh && chmod +x /start.sh

CMD ["/start.sh"]
