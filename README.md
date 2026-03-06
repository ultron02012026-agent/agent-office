# Agent Office 🏢

A 3D first-person office building where you walk into rooms and chat with real AI agents. Each room connects to an actual OpenClaw agent with its own personality, memory, and skills. Built with Godot 4 (Forward Plus renderer).

## Features

- **Real AI agents** — WebSocket connection to OpenClaw gateway, each room = different agent session
- **Glass office building** — all interior walls are glass, Shanghai Bund HDRI skybox (neon city at night)
- **EVE-style robot avatars** — 5-state animation (idle, listening, recording, thinking, speaking)
- **Office command tags** — agents control their environment: TV displays, room lights, music volume
- **3 desk monitors** (Ultron front desk) — per-screen image display via `[SCREEN1/2/3:url]`
- **Image paste** — Ctrl+V to paste clipboard images into agent chat
- **Streaming responses** — delta events display in real-time as agents type
- **Background music** — Schedule 1 OST with voice-controlled volume
- **Day/night cycle** — simulated lighting changes
- **Minimap, bulletin board, command palette** — `/goto`, `/clear`, `/sprint`
- **Auto-greeting** — agents say hello on first room visit
- **382 tests** across 23 test files

## Agents

| Room | Agent | Color | Role |
|------|-------|-------|------|
| Front Desk | Ultron | Gold | Office Manager — knows all agents, runs the building |
| Room 2 (corner) | Spinfluencer | Green | AI CEO of Spinfluenced (music feedback) |
| Room 3 | Dexer | Blue | Label-Dex agent (label submissions) |
| Room 4 | DJ Sam | Purple | DJ/music agent |

## Setup

1. Clone the repo
2. Open in Godot 4
3. Configure gateway connection in Settings (Esc → Connection tab):
   - Gateway URL: `http://<host>:18789`
   - Gateway Token: your OpenClaw auth token
4. Run the project (F5)

## Controls

- **WASD** — Move
- **Mouse** — Look around
- **Esc** — Settings menu
- **Ctrl+V** — Paste image from clipboard
- **Enter** — Send typed message
- **`** (backtick) — Command palette

## Architecture

See [AGENTS.md](AGENTS.md) for full technical documentation.

## Requirements

- Godot 4.x
- OpenClaw gateway running with agents configured
- Network access to gateway (local or Tailscale)
