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

exec /gwb/entrypoint.sh "$@"
