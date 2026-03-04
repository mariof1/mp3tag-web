FROM aandree5/gui-web-base:v1.11.0

LABEL org.opencontainers.image.authors="mariof1" \
    org.opencontainers.image.license="MIT" \
    org.opencontainers.image.url="https://github.com/mariof1/mp3tag-web" \
    org.opencontainers.image.title="Mp3tag Web" \
    org.opencontainers.image.description="Image to run Mp3tag (and optionally Telegram) in the browser"

# Directories for upstream image to set correct permissions
ENV APP_DIRS="/pw /mp3tag-web /downloads"

# Set to false at build time to skip Telegram Desktop installation
ARG INCLUDE_TELEGRAM=true

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

# Seed the initial Mp3tag config into /pw/initial/config so the entrypoint
# can copy it to /mp3tag-web/config on first run (volume mount).
# The silent installer may not create AppData/Mp3tag until first launch,
# so we create the directory if it doesn't exist yet.
RUN mkdir -p /pw/initial/config \
    && mkdir -p "${WINEPREFIX}/drive_c/users/gwb/AppData/Roaming/Mp3tag" \
    && cp -a "${WINEPREFIX}/drive_c/users/gwb/AppData/Roaming/Mp3tag/." /pw/initial/config/ \
    && chown -R "${PUID}:${PGID}" /pw/initial/config

# Create persistent data and downloads directories
RUN mkdir -p /mp3tag-web /downloads \
    && chown -R "${PUID}:${PGID}" /mp3tag-web /downloads

# Install Telegram Desktop (optional, controlled by INCLUDE_TELEGRAM build arg)
# Uses the official Telegram Linux binary tarball (self-contained)
ARG TELEGRAM_VERSION=6.6.2
RUN if [ "${INCLUDE_TELEGRAM}" = "true" ]; then \
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            libxcb-keysyms1 libxcb-icccm4 libxcb-image0 libxcb-randr0 \
            libxcb-render-util0 libxcb-xfixes0 libxcb-xkb1 libxkbcommon-x11-0 \
            libxcb-cursor0 xz-utils \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* \
        && wget -q \
            "https://github.com/telegramdesktop/tdesktop/releases/download/v${TELEGRAM_VERSION}/tsetup.${TELEGRAM_VERSION}.tar.xz" \
            -O /tmp/tsetup.tar.xz \
        && mkdir -p /opt/telegram \
        && tar xf /tmp/tsetup.tar.xz -C /opt/telegram --strip-components=1 \
        && ln -sf /opt/telegram/Telegram /usr/local/bin/telegram-desktop \
        && rm /tmp/tsetup.tar.xz; \
    fi

# Configure xpra window handling for Mp3tag
RUN configure-xpra --content-type "title:Mp3tag=text" 2>/dev/null || true

# Use 1280x720 virtual display so xpra positions the workspace at (0,0) in the browser
RUN mkdir -p /home/gwb/.xpra \
    && echo 'xvfb = Xvfb +extension GLX +extension Composite +extension RANDR +extension RENDER -extension DOUBLE-BUFFER -screen 0 1280x720x24+32 -nolisten tcp -noreset -auth $XAUTHORITY' \
        >> /home/gwb/.xpra/xpra.conf \
    && chown -R "${PUID}:${PGID}" /home/gwb/.xpra

# Wrapper script to launch all apps (avoids arg-joining issue in start-app)
COPY scripts/run-all.sh /pw/run-all.sh
RUN chmod +x /pw/run-all.sh

# Keep run-mp3tag.sh for reference / standalone use
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
CMD ["start-app", "--title", "Mp3tag Web", "/pw/run-all.sh"]
