#!/bin/sh
# Wrapper to launch Mp3tag via Wine.
# A separate script is needed because start-app joins all its arguments
# into a single quoted string before passing to watch-app/xpra.
# xpra's HTML5 client automatically centers windows in the browser viewport.
exec wine "C:\\Program Files\\Mp3tag\\Mp3tag.exe"
