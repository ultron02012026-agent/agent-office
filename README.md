# Agent Office 🏢

A 3D first-person office environment where you walk into AI agent offices and chat with them in real-time. Built with Godot 4.2+ (Forward Plus renderer).

## Features

- **4 Agent Offices** — Ultron (blue), Spinfluencer (pink), Dexer (green), Architect (gold), each with unique themed decorations
- **First-Person Movement** — WASD + mouse look with camera bob and footstep audio stubs
- **Real-Time Chat** — Walk into any office to open a chat panel; messages sent to OpenClaw gateway (chat completions API)
- **Per-Room Chat History** — Leave a room and come back; your conversation is preserved
- **Voice Chat** — Push-to-talk mic capture → Whisper STT → chat → TTS → spatial 3D audio playback
- **Agent Avatars** — Capsule avatars with idle bob, face-player rotation, and speaking glow pulse
- **Agent Visits** — Agents periodically "visit" each other's offices (visual indicator of activity)
- **Day/Night Cycle** — Directional light shifts from dawn → noon → dusk → night over 5 minutes
- **Minimap** — Bottom-right HUD showing floor plan, room colors, and player position
- **Room Title Cards** — Cinematic name card fades in when entering an office
- **Proximity Prompts** — "Enter [Agent]'s Office →" appears near doorways
- **Door Animations** — Doors slide open as you approach
- **Notification Badges** — Simulated "!" badges above doors when agents want attention
- **Status Indicators** — Green/yellow/red dots above doors showing agent connection state
- **Bulletin Board** — Lobby wall showing recent activity across all rooms
- **Command Palette** — Press `/` for VS Code-style commands: `/goto`, `/status`, `/clear`, `/sprint`
- **Sprint Timer** — Pomodoro-style countdown bar with color phases and completion flash
- **Ambiance System** — Per-zone ambient audio (lobby, hallway, office) with crossfade
- **Screenshot Mode** — F12 hides HUD and saves a PNG to `user://screenshots/`
- **Debug Overlay** — F3 shows FPS, position, room, memory, day cycle, sprint status
- **Settings Menu** — Esc opens tabbed settings: Audio, Connection, Controls, Display, Agents
- **Welcome Overlay** — Blocks input on first launch; shows controls; press any key to begin

## Controls

| Key | Action |
|-----|--------|
| **WASD** | Move |
| **Mouse** | Look around |
| **Esc** | Settings menu |
| **Enter** | Send chat message |
| **Tab** | Toggle voice/text mode |
| **V** (hold) | Push-to-talk (voice mode) |
| **/** | Command palette |
| **F3** | Debug overlay |
| **F12** | Screenshot |

## Setup

### Requirements
- **Godot 4.2+** (tested on 4.6.1)
- **OpenClaw Gateway** for AI chat (optional — works offline, just no agent responses)

### Quick Start
```bash
git clone https://github.com/ultron02012026-agent/agent-office.git
cd agent-office
godot --editor   # Import and open in Godot
# Press F5 to play
```

### Gateway Connection
1. Open Settings (Esc) → Connection tab
2. Set **Gateway URL** to your OpenClaw gateway (default: `http://100.125.54.7:18789`)
3. Set **Auth Token** if required
4. Click **Test Connection** to verify

### Tailscale Remote Play
To play from another machine on your Tailscale network:
1. Ensure both machines are on the same Tailnet
2. Set the Gateway URL to your gateway's Tailscale IP (e.g., `http://100.x.y.z:18789`)
3. Export the project (Project → Export) and run the binary on the remote machine

### Running Tests
```bash
godot --headless --script tests/run_tests.gd
```

## Project Structure
```
agent-office/
├── project.godot          # Engine config, autoloads, input maps
├── scenes/
│   ├── main.tscn          # Main scene (office layout, all nodes)
│   └── player.tscn        # First-person player (CharacterBody3D)
├── scripts/               # All game logic (.gd files)
│   ├── settings_manager.gd  # Autoload singleton (persistent settings)
│   ├── player.gd            # FPS controller
│   ├── chat_ui.gd           # Chat panel + OpenClaw API
│   ├── voice_chat.gd        # Mic → STT → TTS pipeline
│   └── ...                  # 17 more feature scripts
└── tests/                 # 22 test suites (347 tests)
    ├── run_tests.gd       # Test runner
    └── test_*.gd          # Individual test files
```

## Architecture
- **SettingsManager** (autoload) — global persistent settings, loaded before everything else
- **Scripts attach to scene nodes** — each feature is a self-contained `.gd` file
- **No external assets required** — geometry is CSG, avatars are capsule meshes, audio nodes are stubs (drop in .ogg/.wav files)
- **All tests are pure logic** — no scene instantiation needed, run headless
