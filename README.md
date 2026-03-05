# Agent Office 🏢

A 3D office building where each room connects to a different OpenClaw agent via chat.

## Setup

1. **Install Godot 4**: `brew install --cask godot`
2. **Ensure OpenClaw gateway is running** on `localhost:3007`
3. **Open project**: Launch Godot → Import → select this folder's `project.godot`
4. **Hit Play** (F5)

## Controls

- **WASD** — Move
- **Mouse** — Look around
- **Escape** — Toggle mouse capture (needed to type in chat)
- **Enter** — Send chat message

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
```

Walk into a room → chat panel opens on the right → talk to the agent.
Walk out → chat closes.

## How It Works

- Each room has an `Area3D` that detects player entry/exit
- Chat UI sends messages to OpenClaw's `/v1/chat/completions` endpoint
- Each room gets a system prompt identifying which agent's office you're in
- Responses appear in the chat log

## Files

- `scenes/main.tscn` — Office layout with 4 rooms, hallway, chat UI
- `scenes/player.tscn` — First-person player with WASD + mouse look
- `scripts/player.gd` — Movement and room enter/exit handling
- `scripts/room_area.gd` — Room detection trigger
- `scripts/chat_ui.gd` — Chat panel + OpenClaw API integration
