FROM alpine:latest as rclone-installer

# Install rclone in a separate stage
RUN apk add --no-cache curl && \
    curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
    unzip rclone-current-linux-amd64.zip && \
    cd rclone-*-linux-amd64 && \
    cp rclone /usr/local/bin/

FROM deluan/navidrome:latest

# Install fuse and copy rclone from the previous stage
RUN apt-get update && apt-get install -y fuse

COPY --from=rclone-installer /usr/local/bin/rclone /usr/local/bin/rclone

# Create startup script
RUN echo '#!/bin/bash\n\
mkdir -p /music\n\
rclone mount b2-music:navidrome-flo-music /music --daemon --allow-other\n\
sleep 5\n\
/app/navidrome --musicfolder "/music" --datafolder "/data" --port "4533"\n\
' > /start.sh && chmod +x /start.sh

CMD ["/start.sh"]
