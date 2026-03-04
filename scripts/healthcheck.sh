#!/bin/sh
# 1. Check if Mp3tag (wine) process is running
# 2. Check GWB health
# 3. Exit with status 1 if any check fails

if ! pgrep -f "Mp3tag.exe" >/dev/null; then
    echo "Mp3tag is not running"
    exit 1
fi

if ! /gwb/healthcheck.sh; then
    echo "GUI Web Base healthcheck failed"
    exit 1
fi
