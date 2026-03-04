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

exec /gwb/entrypoint.sh "$@"
