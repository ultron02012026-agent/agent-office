#!/usr/bin/env python3
"""
Agent Office Screen Content Server

Serves images from ~/.openclaw/screen-content/ so agents can display
generated content on in-game TVs and whiteboards.

Directory structure:
    ~/.openclaw/screen-content/
    ├── ultron/
    ├── spinfluencer/
    ├── dexer/
    └── dj-sam/

Usage:
    python3 server.py [--port 18790] [--host 0.0.0.0]

Agents save images to their directory, then use:
    [TV_SHOW:http://localhost:18790/ultron/chart.png]
"""

import argparse
import os
import sys
import signal
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path

DEFAULT_PORT = 18790
DEFAULT_HOST = "0.0.0.0"
CONTENT_DIR = Path.home() / ".openclaw" / "screen-content"

# Agent directories to create on startup
AGENT_DIRS = ["ultron", "spinfluencer", "dexer", "dj-sam", "shared"]


class ScreenContentHandler(SimpleHTTPRequestHandler):
    """Serves files from the screen-content directory with CORS headers."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(CONTENT_DIR), **kwargs)

    def end_headers(self):
        # Allow cross-origin requests from the game
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def log_message(self, format, *args):
        # Cleaner logging
        print(f"[screen-server] {args[0]}" if args else "")


def ensure_directories():
    """Create the content directory structure."""
    CONTENT_DIR.mkdir(parents=True, exist_ok=True)
    for agent_dir in AGENT_DIRS:
        (CONTENT_DIR / agent_dir).mkdir(exist_ok=True)
    
    # Write a README in the content dir
    readme = CONTENT_DIR / "README.md"
    if not readme.exists():
        readme.write_text(
            "# Screen Content\n\n"
            "Images placed here are served to Agent Office.\n"
            "Each agent has their own directory.\n\n"
            "URL format: http://localhost:18790/<agent>/<filename>\n"
            "Example: http://localhost:18790/ultron/chart.png\n"
        )


def check_port_available(host, port):
    """Check if the port is available."""
    import socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        sock.bind((host, port))
        sock.close()
        return True
    except OSError:
        sock.close()
        return False


def write_pid_file():
    """Write PID file for process management."""
    pid_file = CONTENT_DIR / ".server.pid"
    pid_file.write_text(str(os.getpid()))


def cleanup_pid_file():
    """Remove PID file on exit."""
    pid_file = CONTENT_DIR / ".server.pid"
    if pid_file.exists():
        pid_file.unlink()


def main():
    parser = argparse.ArgumentParser(description="Agent Office Screen Content Server")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help=f"Port (default: {DEFAULT_PORT})")
    parser.add_argument("--host", default=DEFAULT_HOST, help=f"Host (default: {DEFAULT_HOST})")
    args = parser.parse_args()

    ensure_directories()

    if not check_port_available(args.host, args.port):
        print(f"[screen-server] Port {args.port} already in use — server may already be running")
        # Check if it's our server
        pid_file = CONTENT_DIR / ".server.pid"
        if pid_file.exists():
            pid = pid_file.read_text().strip()
            print(f"[screen-server] Existing PID: {pid}")
        sys.exit(1)

    server = HTTPServer((args.host, args.port), ScreenContentHandler)
    write_pid_file()

    # Clean shutdown
    def handle_signal(signum, frame):
        print("\n[screen-server] Shutting down...")
        cleanup_pid_file()
        server.shutdown()
        sys.exit(0)

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    print(f"[screen-server] Serving {CONTENT_DIR}")
    print(f"[screen-server] Listening on http://{args.host}:{args.port}")
    print(f"[screen-server] Agent dirs: {', '.join(AGENT_DIRS)}")
    print(f"[screen-server] Example: http://localhost:{args.port}/ultron/image.png")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        cleanup_pid_file()
        server.server_close()


if __name__ == "__main__":
    main()
