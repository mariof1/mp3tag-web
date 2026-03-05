#!/bin/sh
# Launch all apps in the shared xpra session.
# Telegram Desktop runs in the background; Mp3tag is the primary (foreground) app.
# xpra seamless mode shows both as separate windows in the same browser tab.

# Ensure X11 auth is available for background processes
export XAUTHORITY="${XAUTHORITY:-/home/gwb/.Xauthority}"
export DISPLAY="${DISPLAY:-:100}"

start_telegram() {
    export QT_OPENGL=software
    export LANG=C.UTF-8
    # -noupdate: prevent update checks that can raise the window
    telegram-desktop -noupdate >/dev/null 2>&1 &
    echo $!
}

# Start Telegram Desktop if installed and not explicitly disabled
if [ "${TELEGRAM_ENABLED:-true}" = "true" ] && command -v telegram-desktop >/dev/null 2>&1; then
    TELEGRAM_PID=$(start_telegram)

    # Monitor: restart Telegram only if the process crashes.
    # We intentionally do NOT probe Telegram's X11 windows (xdotool search etc.)
    # because the X11 queries trigger events that cause Telegram to steal focus
    # from Mp3tag. If the user closes Telegram (hides to tray), they can refresh
    # the browser to get a fresh session.
    (
        while true; do
            sleep 30
            if ! kill -0 $TELEGRAM_PID 2>/dev/null; then
                sleep 2
                TELEGRAM_PID=$(start_telegram)
                # After restart, wait for window creation then refocus Mp3tag
                sleep 8
                MP3TAG_WID=$(xdotool search --name "Mp3tag" 2>/dev/null | head -1)
                [ -n "$MP3TAG_WID" ] && xdotool windowactivate "$MP3TAG_WID" 2>/dev/null
            fi
        done
    ) &
fi

# Launch Mp3tag with /downloads/Telegram Desktop as the default folder.
# Telegram saves files there by default; Wine Z: maps to Linux root.
exec wine "C:\\Program Files\\Mp3tag\\Mp3tag.exe" /fp:"Z:\\downloads\\Telegram Desktop"
