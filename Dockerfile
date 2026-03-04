FROM aandree5/gui-web-base:v1.11.0

LABEL org.opencontainers.image.authors="mariof1" \
    org.opencontainers.image.license="MIT" \
    org.opencontainers.image.url="https://github.com/mariof1/mp3tag-web" \
    org.opencontainers.image.title="Mp3tag Web" \
    org.opencontainers.image.description="Image to run Mp3tag in the browser"

# Directories for upstream image to set correct permissions
ENV APP_DIRS="/pw /mp3tag-web"

# Wine configuration
ENV WINEPREFIX=/home/gwb/.wine
ENV WINEARCH=win32
ENV WINEDEBUG=-all
# Suppress Wine crash handler popup dialogs
ENV WINE_DISABLE_CRASH_DIALOG=1

EXPOSE 5000
EXPOSE 5443

ARG MP3TAG_VERSION=3.33.1

# Add 32-bit architecture and install Wine + dependencies
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        wine \
        wine32:i386 \
        xvfb \
        wget \
        cabextract \
    && apt-get autoremove -y --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Initialize Wine prefix and install Mp3tag as the gwb user (avoids C:\users\root\ profile mismatch)
RUN mkdir -p "${WINEPREFIX}" && chown -R "${PUID}:${PGID}" "${WINEPREFIX}" \
    && wget -q \
        --referer="https://www.mp3tag.de/en/download.html" \
        -O /tmp/mp3tag-setup.exe \
        "https://download.mp3tag.de/mp3tag-v${MP3TAG_VERSION}-setup.exe" \
    && chown "${PUID}:${PGID}" /tmp/mp3tag-setup.exe \
    && gosu "${PUID}:${PGID}" xvfb-run --auto-servernum --server-args="-screen 0 1024x768x24" \
        sh -c "wineboot --init && sleep 5 && wine /tmp/mp3tag-setup.exe /S; sleep 8; wineserver -k 2>/dev/null; true" \
    && test -f "${WINEPREFIX}/drive_c/Program Files/Mp3tag/Mp3tag.exe" \
    && rm /tmp/mp3tag-setup.exe \
    && rm -rf /tmp/wine-* \
    && chown -R "${PUID}:${PGID}" "${WINEPREFIX}"

# Create persistent data directory and link Mp3tag config for persistence
RUN mkdir -p /mp3tag-web \
    && mkdir -p /pw/initial \
    && chown -R "${PUID}:${PGID}" /mp3tag-web

# Configure xpra window handling for Mp3tag
RUN configure-xpra --content-type "title:Mp3tag=text" 2>/dev/null || true

# Use 1280x720 virtual display so xpra positions the workspace at (0,0) in the browser
RUN mkdir -p /home/gwb/.xpra \
    && echo 'xvfb = Xvfb +extension GLX +extension Composite +extension RANDR +extension RENDER -extension DOUBLE-BUFFER -screen 0 1280x720x24+32 -nolisten tcp -noreset -auth $XAUTHORITY' \
        >> /home/gwb/.xpra/xpra.conf \
    && chown -R "${PUID}:${PGID}" /home/gwb/.xpra

# Wrapper script to launch Mp3tag (avoids arg-joining issue in start-app)
COPY scripts/run-mp3tag.sh /pw/run-mp3tag.sh
RUN chmod +x /pw/run-mp3tag.sh

# Entrypoint script
COPY scripts/entrypoint.sh /pw/entrypoint.sh
RUN chmod +x /pw/entrypoint.sh

# Healthcheck script
COPY scripts/healthcheck.sh /pw/healthcheck.sh
RUN chmod +x /pw/healthcheck.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD /pw/healthcheck.sh

ENTRYPOINT ["/pw/entrypoint.sh"]
CMD ["start-app", "--title", "Mp3tag Web", "/pw/run-mp3tag.sh"]
