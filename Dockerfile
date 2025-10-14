FROM deluan/navidrome:latest

# Install rclone
RUN curl https://rclone.org/install.sh | bash

# Create startup script
RUN echo '#!/bin/bash\n\
mkdir -p /music\n\
rclone mount b2-music:navidrome-flo-music /music --daemon \n\
/navidrome/navidrome --musicfolder /music --datafolder /data \n\
' > /start.sh && chmod +x /start.sh

CMD ["/start.sh"]
