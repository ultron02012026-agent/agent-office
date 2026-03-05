# Agent Office — AGENTS.md

## What Is This
3D first-person office building (Godot 4.2, GDScript) where you walk into rooms and chat/voice-talk with AI agents via OpenClaw gateway API. Four rooms, central hallway, lobby.

## Tech Stack
- **Engine:** Godot 4.2 (Forward Plus renderer)
- **Language:** GDScript
- **Backend:** OpenClaw Gateway (OpenAI-compatible API: chat completions, STT, TTS)
- **Persistence:** ConfigFile to `user://settings.cfg`

## Architecture
```
SettingsManager (autoload singleton)
    ↕ read by all scripts
main.tscn (root scene)
├── Player (CharacterBody3D) → player.gd — movement, input, room tracking
├── Room[1-4]_Area (Area3D) → room_area.gd — enter/exit detection
├── ChatUI (CanvasLayer) → chat_ui.gd — text chat + API calls
├── VoiceChat (Node) → voice_chat.gd — mic capture, STT, TTS
├── SettingsMenu (CanvasLayer) → settings_menu.gd — tabbed settings UI
├── [Agent]_Avatar (MeshInstance3D) → agent_avatar.gd — speaking pulse
├── [Agent]_TTSPlayer (AudioStreamPlayer3D) — spatial TTS playback
└── HUD (CanvasLayer) — room name + voice mode indicator
```

## File Map
| File | Description |
|------|-------------|
| `project.godot` | Godot config: autoloads, input mappings (WASD, V, Tab, Esc) |
| `scenes/main.tscn` | Full office: 4 rooms, hallway, lobby, furniture, lights, avatars, UI layers |
| `scenes/player.tscn` | CharacterBody3D with capsule collider + CameraPivot/Camera3D |
| `scripts/player.gd` | FPS movement, mouse look, room enter/exit, voice toggle, HUD updates |
| `scripts/room_area.gd` | Area3D trigger — calls `enter_room()`/`exit_room()` on player |
| `scripts/chat_ui.gd` | Chat panel: message send, OpenClaw `/v1/chat/completions`, voice transcription handling |
| `scripts/voice_chat.gd` | Mic capture → WAV → STT (`/v1/audio/transcriptions`) → TTS (`/v1/audio/speech`) → spatial playback |
| `scripts/settings_manager.gd` | Autoload singleton: all settings vars, ConfigFile save/load, applies audio/display |
| `scripts/settings_menu.gd` | Programmatic tabbed UI (Audio/Connection/Controls/Display/Agents), Esc to open |
| `scripts/agent_avatar.gd` | MeshInstance3D pulse effect via emission when agent is speaking |
| `tests/run_tests.gd` | Headless test runner (`godot --headless --script tests/run_tests.gd`) |
| `tests/test_chat_ui.gd` | Tests: empty message rejection, thinking state, BBCode formatting |
| `tests/test_player.gd` | Tests: camera clamp, room state tracking, HUD location |
| `tests/test_room_area.gd` | Tests: room name propagation, enter/exit state |
| `tests/test_settings.gd` | Tests: defaults, save/load roundtrip, agent config editing |

## Key Patterns

### Rooms
Each room = a set of CSGBox3D walls + Area3D trigger + desk/chairs + Label3D + OmniLight3D + avatar + TTSPlayer. The Area3D has `room_name` export. When player enters, `player.enter_room()` opens chat and binds voice to that room's TTSPlayer.

### Chat Flow
1. Player enters room → `chat_ui.show_chat(room_name)` 
2. User types or voice sends text → `_send_to_openclaw()` 
3. POST to `{gateway_url}/v1/chat/completions` with system prompt + history
4. Response displayed in RichTextLabel with BBCode colors
5. If voice mode: response also sent to `voice_chat.request_tts()`

### Voice Flow
1. Tab toggles voice mode flag
2. Hold V → `start_recording()` (AudioStreamMicrophone → AudioEffectCapture on "Record" bus)
3. Release V → `stop_recording()` → save WAV → POST to `/v1/audio/transcriptions`
4. Transcription emitted via signal → chat_ui processes as typed message
5. Agent reply → POST to `/v1/audio/speech` → MP3 loaded → plays on room's AudioStreamPlayer3D

### Settings
`SettingsManager` is an autoload (registered in project.godot). All scripts read from it directly (e.g., `SettingsManager.gateway_url`). Settings menu writes to SettingsManager vars, calls `save_settings()` on close.

### Agent Config
`SettingsManager.agent_configs` dict maps room names to `{agent_name, system_prompt}`. Editable in settings menu Agents tab. Used by chat_ui for system prompt in API calls.

## Spatial Layout
```
z=-15  ┌──── North wall ────┐
       │                     │
z=-11  │ Ultron    │ Dexer   │   (rooms at z=-8 center)
z=-5   │ door      │ door    │
       │  HALLWAY (x=-2..2)  │
z=-3   │ Spinflu   │Architect│   (rooms at z=0 center)
z=3    │ door      │ door    │
       │                     │
z=7    │      LOBBY          │   (player spawns at z=10)
z=15   └─────────────────────┘
       Left: x=-10    Right: x=10
```

## Common Tasks

### Add a new room
1. In `main.tscn`: duplicate a room's walls/desk/chair/whiteboard/TV/light/label nodes, adjust positions
2. Add new `Area3D` with `room_area.gd`, set `room_name` export
3. Add `[Name]_Avatar` MeshInstance3D with `agent_avatar.gd`, set `room_name`
4. Add `[Name]_TTSPlayer` AudioStreamPlayer3D at desk position
5. Add doorway gap in hallway walls
6. Add entry in `SettingsManager.agent_configs` default dict
7. Connect Area3D body_entered/body_exited signals to itself

### Change the API endpoint
Edit `SettingsManager.gateway_url` default value, or change at runtime via Settings > Connection tab.

### Add a new setting
1. Add var to `settings_manager.gd` with default
2. Add `config.set_value`/`config.get_value` in `save_settings()`/`load_settings()`
3. Add UI control in appropriate tab in `settings_menu.gd`

### Run tests
```bash
godot --headless --script tests/run_tests.gd
```

### Add a new test
1. Create `tests/test_xxx.gd` extending Node with `run() -> Dictionary` returning `{passed, failed}`
2. Add entry to `test_files` array in `tests/run_tests.gd`
