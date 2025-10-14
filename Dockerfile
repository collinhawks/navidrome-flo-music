FROM deluan/navidrome:latest

# Create startup script (without rclone for now)
RUN echo '#!/bin/bash\n\
/app/navidrome --musicfolder "/music" --datafolder "/data" --port "4533"\n\
' > /start.sh && chmod +x /start.sh

CMD ["/start.sh"]
