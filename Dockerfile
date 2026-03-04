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

# Initialize Wine prefix, download and silently install Mp3tag
RUN mkdir -p "${WINEPREFIX}" \
    && wget -q \
        --referer="https://www.mp3tag.de/en/download.html" \
        -O /tmp/mp3tag-setup.exe \
        "https://download.mp3tag.de/mp3tag-v${MP3TAG_VERSION}-setup.exe" \
    && xvfb-run --auto-servernum --server-args="-screen 0 1024x768x24" \
        sh -c "wine /tmp/mp3tag-setup.exe /S; sleep 8; wineserver -k 2>/dev/null; true" \
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
