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
    TELEGRAM_PID=$!

    # Monitor: auto-restore Telegram if it hides to the system tray.
    # Telegram's close button minimizes to tray (30x30 icon) instead of quitting.
    # This loop detects when the main window disappears and re-maps it.
    (
        sleep 10  # wait for initial window creation
        while kill -0 $TELEGRAM_PID 2>/dev/null; do
            # Find the main Telegram window (not the tray icon which is 30x30)
            MAIN_WID=""
            for wid in $(xdotool search --pid $TELEGRAM_PID 2>/dev/null); do
                W=$(xdotool getwindowgeometry --shell $wid 2>/dev/null | grep WIDTH | cut -d= -f2)
                if [ -n "$W" ] && [ "$W" -gt 100 ] 2>/dev/null; then
                    MAIN_WID=$wid
                    break
                fi
            done
            if [ -z "$MAIN_WID" ]; then
                # Main window gone (hidden to tray) - find and re-map it
                for wid in $(xdotool search --pid $TELEGRAM_PID 2>/dev/null); do
                    NAME=$(xdotool getwindowname $wid 2>/dev/null)
                    case "$NAME" in *Telegram*|*telegram*)
                        xdotool windowmap $wid 2>/dev/null
                        xdotool windowactivate $wid 2>/dev/null
                    ;; esac
                done
            fi
            sleep 3
        done
    ) &
fi

# Launch Mp3tag with /downloads/Telegram Desktop as the default folder.
# Telegram saves files there by default; Wine Z: maps to Linux root.
exec wine "C:\\Program Files\\Mp3tag\\Mp3tag.exe" /fp:"Z:\\downloads\\Telegram Desktop"
