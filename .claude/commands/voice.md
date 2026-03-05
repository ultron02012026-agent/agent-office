# Voice Chat — End-to-End Flow

## Overview
Push-to-talk voice: Mic → WAV → STT → Chat API → TTS → Spatial Audio

## Toggle
- **Tab** toggles `voice_chat.voice_mode` (bool). Player.gd calls `voice_chat.toggle_voice_mode()`.
- HUD shows 🎙️ or ⌨️ indicator.

## Recording (voice_chat.gd)
1. Player holds V → `start_recording()`
2. Creates "Record" audio bus with `AudioEffectCapture` (30s buffer)
3. Starts `AudioStreamMicrophone` on an `AudioStreamPlayer` routed to Record bus
4. Bus is muted (no mic playback to speakers)
5. Player releases V → `stop_recording()`
6. Grabs frames from `AudioEffectCapture.get_buffer()`
7. Saves as PCM16 mono WAV to `/tmp/agent_office_voice.wav`

## STT
1. WAV file uploaded as multipart/form-data to `/v1/audio/transcriptions`
2. Model: `whisper-1`
3. On success: emits `transcription_received(text)` signal
4. `chat_ui.gd` is connected to this signal, processes text like typed input

## Chat
Normal chat completions flow (see networking.md). Response displayed in chat panel.

## TTS
1. If voice mode active, `chat_ui.gd` calls `voice_chat.request_tts(reply_text)`
2. POST to `/v1/audio/speech` with voice from `SettingsManager.tts_voice`
3. MP3 downloaded to `/tmp/agent_office_response.mp3`
4. Loaded as `AudioStreamMP3`, played on room's `AudioStreamPlayer3D` (spatial)
5. Fallback: non-spatial `AudioStreamPlayer` if no TTSPlayer available

## Avatar Pulse
`agent_avatar.gd` checks `voice_chat.is_speaking && voice_chat.current_room == room_name` each frame. Enables emission with sine-wave intensity when speaking.

## Room Binding
- `player.enter_room()` calls `voice_chat.set_room(name, tts_player)`
- `player.exit_room()` calls `voice_chat.clear_room()`
- Each room has a named `[Agent]_TTSPlayer` AudioStreamPlayer3D at the agent's desk
