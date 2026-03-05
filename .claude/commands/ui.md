# UI Systems

## Chat UI (`chat_ui.gd`, CanvasLayer)
- Right-side panel (400px wide) with RoomLabel, RichTextLabel (BBCode), LineEdit + SendButton
- Opens via `show_chat(room_name)`, closes via `hide_chat()`
- Thinking state disables input, shows "[agent] is thinking..."
- Colors: cyan=user, yellow=agent, gray=system, red=error
- Mouse mode set to VISIBLE when chat open, CAPTURED when closed

## HUD (CanvasLayer, layer=10)
- `RoomHUD` Label: shows "📍 Lobby" / "📍 Hallway" / "📍 [Agent]'s Office" + voice mode indicator
- `MicIndicator` Label: red "🎙️ Recording..." shown during push-to-talk
- Updated every physics frame by `player._update_hud()`
- Location logic: `z > 7` = Lobby, else Hallway, or room name if in a room

## Settings Menu (`settings_menu.gd`, CanvasLayer layer=20)
- Built programmatically in `_build_ui()` (no .tscn needed)
- `process_mode = 3` (ALWAYS) — works while game tree is paused
- Opens: `open_menu()` → pauses tree, shows mouse
- Closes: `close_menu()` → saves settings, unpauses, restores mouse mode

### Tabs:
1. **Audio** — Master/voice volume sliders, mic checkbox, TTS voice dropdown (6 voices)
2. **Connection** — Gateway URL input, token input (secret), test connection button with status
3. **Controls** — Mouse sensitivity slider, invert Y checkbox, PTT key button
4. **Display** — Fullscreen checkbox, FOV slider (60-120), VSync checkbox
5. **Agents** — Per-room: agent name edit, system prompt preview (truncated)

### Helper: `_add_slider(parent, label, initial, callback, min, max, step)`
Creates HBox with label + HSlider + value display. Used for all slider controls.

## Input Priority
1. Settings menu open → blocks all player input (player.gd checks `settings_menu.is_open`)
2. Chat visible → mouse visible, typing goes to LineEdit
3. Neither → mouse captured, WASD movement active
