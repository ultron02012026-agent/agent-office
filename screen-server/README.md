# Screen Content Server

Local HTTP server that serves images to Agent Office TVs and monitors.

## Quick Start

```bash
# Start in foreground
./launch.sh

# Start in background
./launch.sh --background
```

## How It Works

1. Server runs on `http://localhost:18790`
2. Serves files from `~/.openclaw/screen-content/`
3. Each agent has a directory: `ultron/`, `spinfluencer/`, `dexer/`, `dj-sam/`, `shared/`
4. Agents save images to their directory, then use `[TV_SHOW:http://localhost:18790/agent/file.png]`

## For Agents

Save any image to your screen-content directory:
```bash
cp chart.png ~/.openclaw/screen-content/ultron/chart.png
```

Then in Agent Office chat, include the tag:
```
[TV_SHOW:http://localhost:18790/ultron/chart.png]
```

The image appears on your in-game monitor.

## Port

Default: `18790` (one above the OpenClaw gateway at 18789)

Override: `python3 server.py --port 9999`
