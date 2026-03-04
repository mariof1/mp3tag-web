#!/bin/sh
# Wrapper to launch Mp3tag via Wine.
# A separate script is needed because start-app joins all its arguments
# into a single quoted string before passing to watch-app/xpra.
exec wine "C:\\Program Files\\Mp3tag\\Mp3tag.exe"
