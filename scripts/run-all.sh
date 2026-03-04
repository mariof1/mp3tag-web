#!/bin/sh
# Launch all apps in the shared xpra session.
# Telegram Desktop runs in the background; Mp3tag is the primary (foreground) app.
# xpra seamless mode shows both as separate windows in the same browser tab.

# Ensure X11 auth is available for background processes
export XAUTHORITY="${XAUTHORITY:-/home/gwb/.Xauthority}"
export DISPLAY="${DISPLAY:-:100}"

# Start Telegram Desktop if installed and not explicitly disabled
if [ "${TELEGRAM_ENABLED:-true}" = "true" ] && command -v telegram-desktop >/dev/null 2>&1; then
    # Disable OpenGL hardware acceleration (no GPU in container)
    export QT_OPENGL=software
    telegram-desktop &
fi

# Launch Mp3tag with /downloads as the default folder.
# Wine's Z: drive maps to the Linux root, so /downloads -> Z:\downloads.
exec wine "C:\\Program Files\\Mp3tag\\Mp3tag.exe" /fp:"Z:\\downloads"
