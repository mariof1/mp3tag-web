#!/bin/sh
# Restore initial mp3tag-web directories if they don't exist
# (e.g. when user binds a new empty host directory to /mp3tag-web)
for dir in /pw/initial/*/; do
    [ -d "$dir" ] || continue
    dir=$(basename "$dir")
    if [ ! -d "/mp3tag-web/$dir" ]; then
        mkdir -p "/mp3tag-web/$dir"
        cp -a "/pw/initial/$dir/." "/mp3tag-web/$dir/"
        chown -R "$PUID:$PGID" "/mp3tag-web/$dir"
    fi
done

# Symlink the Wine Mp3tag config directory to /mp3tag-web/config so settings
# are persisted on the host-mounted volume across container restarts.
MP3TAG_APPDATA="${WINEPREFIX}/drive_c/users/gwb/AppData/Roaming/Mp3tag"
if [ ! -L "$MP3TAG_APPDATA" ]; then
    rm -rf "$MP3TAG_APPDATA"
    mkdir -p "$(dirname "$MP3TAG_APPDATA")"
    ln -sf /mp3tag-web/config "$MP3TAG_APPDATA"
fi

# Symlink ~/Downloads to /downloads so Telegram's default download path
# ("Telegram folder in system «Downloads»") writes to the mounted volume.
DOWNLOADS_DIR="/home/gwb/Downloads"
if [ ! -L "$DOWNLOADS_DIR" ]; then
    # Move any existing downloaded files into /downloads before replacing
    if [ -d "$DOWNLOADS_DIR" ]; then
        cp -a "$DOWNLOADS_DIR/." /downloads/ 2>/dev/null || true
        rm -rf "$DOWNLOADS_DIR"
    fi
    ln -sf /downloads "$DOWNLOADS_DIR"
fi

# Ensure the Telegram Desktop subfolder exists so Mp3tag can open it on startup
mkdir -p "/downloads/Telegram Desktop"
chown "$PUID:$PGID" "/downloads/Telegram Desktop"

exec /gwb/entrypoint.sh "$@"
