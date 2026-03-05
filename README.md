# Agent Office 🏢

A 3D office building where each room connects to a different OpenClaw agent via chat or voice.

## Setup

1. **Install Godot 4**: `brew install --cask godot`
2. **Ensure OpenClaw gateway is running** on `localhost:3007`
3. **Open project**: Launch Godot → Import → select this folder's `project.godot`
4. **Hit Play** (F5)

## Controls

- **WASD** — Move
- **Mouse** — Look around
- **Escape** — Settings menu (pauses game)
- **Enter** — Send chat message (text mode)
- **Tab** — Toggle voice/text mode
- **V (hold)** — Push-to-talk (voice mode)

## Layout

```
        ┌─────────┐   ┌─────────┐
        │  Ultron  │   │  Dexer  │
        │  (room)  │   │  (room) │
        └────┬─────┘   └────┬────┘
             │   HALLWAY    │
        ┌────┴─────┐   ┌────┴────┐
        │Spinflu-  │   │Architect│
        │  encer   │   │  (room) │
        └──────────┘   └─────────┘
              LOBBY
```

Walk into a room → chat panel opens → talk to the agent (type or voice).
Walk out → chat closes.

## Voice Chat

- **Voice mode** (Tab to toggle): Hold V to record, release to transcribe & send
- Uses OpenClaw STT (`/v1/audio/transcriptions`) and TTS (`/v1/audio/speech`) endpoints
- Agent responses play as spatial audio from the agent's desk position
- Agent avatar capsule pulses/glows while speaking
- Falls back to text mode gracefully if voice endpoints aren't available

## Settings (Escape)

- **Audio:** Master/voice volume, mic toggle, TTS voice selection
- **Connection:** Gateway URL, connection test
- **Controls:** Mouse sensitivity, invert Y, push-to-talk key
- **Display:** Fullscreen, FOV, VSync
- **Agents:** Edit agent names and system prompts per room
- Settings persist to `user://settings.cfg`

## Tests

Run tests headless:
```bash
godot --headless --script tests/run_tests.gd
```

## How It Works

- Each room has an `Area3D` that detects player entry/exit
- Chat UI sends messages to OpenClaw's `/v1/chat/completions` endpoint
- Each room gets a system prompt identifying which agent's office you're in
- Voice chat records mic → STT → chat completions → TTS → spatial audio
- Colored capsule avatars sit at each agent's desk
- Room names on door frames for hallway navigation

## Files

- `scenes/main.tscn` — Office layout with 4 rooms, hallway, avatars, audio
- `scenes/player.tscn` — First-person player with WASD + mouse look
- `scripts/player.gd` — Movement, room tracking, voice/settings integration
- `scripts/room_area.gd` — Room detection trigger
- `scripts/chat_ui.gd` — Chat panel + OpenClaw API + voice integration
- `scripts/voice_chat.gd` — Mic capture, STT, TTS, spatial audio playback
- `scripts/settings_manager.gd` — Autoload singleton for persistent settings
- `scripts/settings_menu.gd` — Tabbed settings UI (Escape to open)
- `scripts/agent_avatar.gd` — Capsule avatar with speaking pulse effect
- `tests/` — Test suite (run headless with Godot)
