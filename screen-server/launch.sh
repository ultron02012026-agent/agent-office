#!/bin/bash
# Launch the screen content server
# Usage: ./launch.sh [--background]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTENT_DIR="$HOME/.openclaw/screen-content"
PID_FILE="$CONTENT_DIR/.server.pid"

# Check if already running
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "[screen-server] Already running (PID: $PID)"
        exit 0
    else
        rm -f "$PID_FILE"
    fi
fi

mkdir -p "$CONTENT_DIR"

if [ "$1" = "--background" ] || [ "$1" = "-b" ]; then
    nohup python3 "$SCRIPT_DIR/server.py" > "$CONTENT_DIR/.server.log" 2>&1 &
    echo "[screen-server] Started in background (PID: $!)"
else
    python3 "$SCRIPT_DIR/server.py"
fi
