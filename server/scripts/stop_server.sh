#!/bin/bash
set -euo pipefail
launchctl unload "$HOME/Library/LaunchAgents/com.stack.server.plist" || true
