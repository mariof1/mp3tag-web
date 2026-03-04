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
    telegram-desktop >/dev/null 2>&1 &
    echo $!
}

# Start Telegram Desktop if installed and not explicitly disabled
if [ "${TELEGRAM_ENABLED:-true}" = "true" ] && command -v telegram-desktop >/dev/null 2>&1; then
    TELEGRAM_PID=$(start_telegram)

    # Monitor: detect when Telegram hides to system tray and restart it.
    # Telegram's close button minimizes to tray (30x30 icon) — the window becomes
    # unmapped and xpra can't properly re-render it. The cleanest fix is to restart
    # Telegram when this happens, which gives xpra a fresh window to manage.
    (
        sleep 12  # wait for initial window creation
        while true; do
            if ! kill -0 $TELEGRAM_PID 2>/dev/null; then
                # Telegram process died — restart it
                sleep 2
                TELEGRAM_PID=$(start_telegram)
                sleep 10
                continue
            fi
            # Check if main window (>100px wide) is still visible
            VISIBLE=""
            for wid in $(xdotool search --onlyvisible --pid $TELEGRAM_PID 2>/dev/null); do
                W=$(xdotool getwindowgeometry --shell $wid 2>/dev/null | grep WIDTH | cut -d= -f2)
                if [ -n "$W" ] && [ "$W" -gt 100 ] 2>/dev/null; then
                    VISIBLE=1
                    break
                fi
            done
            if [ -z "$VISIBLE" ]; then
                # Main window hidden to tray — kill and restart for clean rendering
                kill $TELEGRAM_PID 2>/dev/null
                wait $TELEGRAM_PID 2>/dev/null
                sleep 1
                TELEGRAM_PID=$(start_telegram)
                sleep 10
            fi
            sleep 3
        done
    ) &
fi

# Launch Mp3tag with /downloads/Telegram Desktop as the default folder.
# Telegram saves files there by default; Wine Z: maps to Linux root.
exec wine "C:\\Program Files\\Mp3tag\\Mp3tag.exe" /fp:"Z:\\downloads\\Telegram Desktop"
