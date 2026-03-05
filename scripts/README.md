# scripts/

## Scripts

| Script | Attached To | Description |
|--------|-------------|-------------|
| `player.gd` | `CharacterBody3D` | FPS controller: WASD movement, mouse look, camera bob, room enter/exit, voice/settings input handling, HUD updates |
| `room_area.gd` | `Area3D` | Triggers `enter_room()`/`exit_room()` on player when body enters/exits. Has `@export room_name` |
| `chat_ui.gd` | `CanvasLayer` | Chat panel: text input, message history, OpenClaw chat completions API, voice transcription display |
| `voice_chat.gd` | `Node` | Mic capture via AudioEffectCapture, WAV encoding, STT/TTS via OpenClaw API, spatial audio playback |
| `settings_manager.gd` | Autoload singleton | All settings vars (audio, connection, controls, display, agent configs), ConfigFile persistence |
| `settings_menu.gd` | `CanvasLayer` | Programmatically built tabbed settings UI, pauses game tree when open |
| `agent_avatar.gd` | `MeshInstance3D` | Pulses emission on capsule mesh when VoiceChat is speaking for this room |

## Dependencies

```
settings_manager.gd (autoload — everything reads from this)
    ↑
player.gd ←→ chat_ui.gd (player calls show/hide_chat)
    ↑              ↑
    ├── voice_chat.gd (player toggles voice, chat_ui connects transcription signal)
    ├── settings_menu.gd (player checks is_open to block input)
    └── room_area.gd (calls player.enter_room/exit_room)

agent_avatar.gd reads VoiceChat.is_speaking + current_room (no direct coupling)
```

## SettingsManager Autoload
Registered in `project.godot` under `[autoload]`. Access anywhere as `SettingsManager.property`. Call `SettingsManager.save_settings()` to persist. Settings file: `user://settings.cfg`.
