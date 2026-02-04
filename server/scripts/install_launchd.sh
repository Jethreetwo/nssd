#!/bin/bash
set -euo pipefail
PLIST="$HOME/Library/LaunchAgents/com.stack.server.plist"
cp "$(dirname "$0")/stack.launchd.plist" "$PLIST"
launchctl load "$PLIST"
