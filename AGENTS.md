# Agent Office — AGENTS.md

## What Is This
3D first-person office building (Godot 4, GDScript) where you walk into rooms and chat with real OpenClaw AI agents. Glass walls, Shanghai Bund HDRI skybox, EVE-style robot avatars. Each room connects to an actual agent with its own personality, memory, and skills via WebSocket.

## Tech Stack
- **Engine:** Godot 4 (Forward Plus renderer)
- **Language:** GDScript
- **Backend:** OpenClaw Gateway via WebSocket (`chat.send`, `chat.inject`, `chat.history`)
- **Fallback:** REST `/v1/chat/completions` if WS disconnected
- **Persistence:** ConfigFile to `user://settings.cfg`
- **Repo:** `github.com/ultron02012026-agent/agent-office` (private)

## Architecture
```
SettingsManager (autoload singleton)
    ↕ read by all scripts
main.tscn (root scene)
├── Player (CharacterBody3D) → player.gd — FPS movement, room tracking, HUD
├── Room[2-4]_Area (Area3D) → room_area.gd — enter/exit detection
├── Ultron_FD_Area (Area3D) → room_area.gd — front desk area
├── GatewayWS (Node) → gateway_ws.gd — WebSocket client to OpenClaw gateway
├── ChatUI (CanvasLayer) → chat_ui.gd — text chat, streaming responses, command tags
├── VoiceChat (Node) → voice_chat.gd — mic capture (STT/TTS currently disabled)
├── TVDisplay (Node) → tv_display.gd — image display on TVs and monitors
├── Ambiance (Node) → ambiance.gd — background music, zone crossfade
├── SettingsMenu (CanvasLayer) → settings_menu.gd — tabbed settings UI
├── [Agent]_Avatar (Node3D) → agent_avatar.gd — EVE robot, 5-state animation
├── [Agent]_TTSPlayer (AudioStreamPlayer3D) — spatial TTS playback
├── AgentSocial (Node) → agent_social.gd — visitor orbs between rooms
├── BulletinBoard (Node) → bulletin_board.gd — live chat activity display
├── Minimap (CanvasLayer) → minimap.gd — overhead room map
├── DayCycle (Node) → day_cycle.gd — day/night lighting cycle
├── CommandPalette (CanvasLayer) → command_palette.gd — /goto, /status, /clear, /sprint
├── NotificationManager (Node) → notification_manager.gd — chat notification badges
├── WorldEnvironment → Shanghai Bund HDRI panoramic skybox
└── HUD (CanvasLayer) — room name label
```

## Rooms & Agents

| Room | Agent ID | Session Key | Robot Color | Description |
|------|----------|-------------|-------------|-------------|
| Spinfluencer (Room 2) | `spinfluencer` | `agent:spinfluencer:main` | Green | AI CEO of Spinfluenced |
| Dexer (Room 3) | `dexer` | `agent:dexer:main` | Blue | Label-Dex AI agent |
| DJ Sam (Room 4) | `dj-sam` | `agent:dj-sam:main` | Purple | DJ/music agent |
| Ultron Front Desk | `main` | `agent:main:main` | Gold | Office Manager (Ultron) |

## Key Scripts

| Script | Purpose |
|--------|---------|
| `gateway_ws.gd` | WebSocket client — connects to OpenClaw, sends `chat.send`/`chat.inject`, routes streaming events, auto-reconnects |
| `chat_ui.gd` | Chat panel — text input, streaming delta display, command tag parsing (music/TV/lights/screens), greeting system, per-room history |
| `tv_display.gd` | Fetches images from URLs, displays on room TVs and Ultron's 3 monitors |
| `agent_avatar.gd` | EVE-style robot with 5 states: idle, listening, recording, thinking, speaking. Eye emission, head tilt, arm gestures |
| `player.gd` | FPS movement (WASD), mouse look, room enter/exit, HUD updates |
| `ambiance.gd` | Background music (Schedule 1 OST), zone crossfade, process_mode=ALWAYS |
| `settings_manager.gd` | Autoload singleton — gateway URL/token, agent configs, audio/display settings |
| `day_cycle.gd` | Simulated day/night cycle affecting light colors |
| `agent_social.gd` | Random agent "visits" — glowing orbs matching eye color |

## Command Tag System
Agents include tags in responses to control the office. Tags are stripped before display.

**Music (all agents):**
`[MUSIC_UP]` `[MUSIC_DOWN]` `[MUSIC_OFF]` `[MUSIC_ON]`

**TV/Screen (per room):**
- `[TV_SHOW:url]` — display image on room TV (or Ultron center monitor)
- `[TV_OFF]` — clear TV/all monitors

**Ultron-only (3 monitors):**
- `[SCREEN1:url]` `[SCREEN2:url]` `[SCREEN3:url]` — left/center/right monitors
- `[SCREEN_CLEAR:1]` `[SCREEN_CLEAR:2]` `[SCREEN_CLEAR:3]`

**Lights (per room):**
- `[LIGHTS_COLOR:#hexcolor]` — change room light color
- `[LIGHTS_BRIGHT:0-100]` — set brightness

## Chat Flow (WebSocket)
1. Player enters room → `gateway_ws.inject_office_context(room)` (first visit only)
2. Auto-greeting fires via `chat.send` with greeting prompt
3. User types message → `gateway_ws.send_message(room, text, attachments)`
4. Delta events stream in → chat log updates in real-time
5. Final event → parse command tags, display clean response, trigger TTS
6. Image paste: Ctrl+V captures clipboard image, sends as base64 attachment

## Gateway Connection
- **URL:** `ws://` + `SettingsManager.gateway_url` (default `http://100.125.54.7:18789`)
- **Auth:** `connect` frame with `auth.token` from `SettingsManager.gateway_token`
- **Protocol:** JSON frames — `{"type":"req","id":N,"method":"...","params":{...}}`
- **Events:** `{"type":"event","event":"chat","payload":{"state":"delta"|"final","message":"..."}}`

## Spatial Layout
```
z=-15  ┌──────── North wall ────────┐
       │                             │
       │ Spinfluencer    │  Dexer    │  (rooms at z=-10)
z=-5   │ (green, dbl)    │  (blue)   │
       │    door          │  door     │
       │      HALLWAY                 │
       │ DJ Sam     │  Coming Soon   │  (rooms at z=0)
z=3    │ (purple)   │   (locked)     │
       │                             │
       │        LOBBY                │
       │   ┌──Ultron Front Desk──┐   │
       │   │ 3 monitors, robot   │   │
z=15   └───┴─────────────────────┴───┘
       Left: x=-15    Right: x=15
```

## Environment
- **Skybox:** Shanghai Bund HDRI (neon city skyline at night, river reflections)
- **Ground:** Dark reflective plaza (wet pavement look)
- **Interior:** All glass walls for sunlight, structural pillars
- **Lighting:** Ambient 0.8, room lights 1.5, hallway ceiling lights, accent lights
- **Sealed building:** Glass wall at entrance — can see out, can't leave

## Common Tasks

### Swap the skybox
Replace `assets/environment/skybox.hdr` with any equirectangular HDR/EXR file.

### Add a new room
1. In `main.tscn`: duplicate room walls/desk/chair/TV/light/label/avatar nodes
2. Add `Area3D` with `room_area.gd`, set `room_name` export
3. Add avatar with `agent_avatar.gd`, set `room_name`
4. Add `TTSPlayer` AudioStreamPlayer3D
5. Add entry in `SettingsManager.agent_configs`
6. Add to `gateway_ws.gd` agent_map
7. Add to minimap, bulletin_board, agent_social, command_palette arrays

### Add a new command tag
1. Define tag format in `chat_ui.gd` `_build_system_prompt()`
2. Add handler function (e.g., `_handle_tv_commands()`)
3. Call handler from response processing
4. Add to `_strip_command_tags()` regex
5. Update `gateway_ws.gd` inject message

### Run tests
```bash
godot --headless --script tests/run_tests.gd
```
382 tests, 23 test files.

## ⚠️ Scene File Rules
**Do NOT rewrite `main.tscn` from scratch.** Always make surgical edits.
- All `[ext_resource]` entries MUST be in the header (before `[sub_resource]`)
- All `[sub_resource]` entries MUST be before `[node]` entries
- `load_steps` must match total resource count
- Sub-agents editing scenes: be ADDITIVE, never delete existing nodes
