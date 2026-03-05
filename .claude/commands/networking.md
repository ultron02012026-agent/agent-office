# Networking — OpenClaw API Integration

## Gateway
All API calls go through OpenClaw gateway. Base URL stored in `SettingsManager.gateway_url` (default: `http://100.125.54.7:18789`). Optional bearer token in `SettingsManager.gateway_token`.

## Endpoints Used

### Chat Completions
- **URL:** `{gateway_url}/v1/chat/completions`
- **Method:** POST
- **Called by:** `chat_ui.gd → _send_to_openclaw()`
- **Body:** `{model, messages: [{role, content}], max_tokens: 200}`
- **Model:** `anthropic/claude-sonnet-4-20250514` (hardcoded in chat_ui.gd)
- **Auth:** Bearer token header if set
- **Response:** Standard OpenAI format `{choices: [{message: {content}}]}`

### Speech-to-Text (STT)
- **URL:** `{gateway_url}/v1/audio/transcriptions`
- **Method:** POST (multipart/form-data)
- **Called by:** `voice_chat.gd → _send_to_stt()`
- **Body:** WAV file as `file` field, `model=whisper-1`
- **Response:** `{text: "transcribed text"}`

### Text-to-Speech (TTS)
- **URL:** `{gateway_url}/v1/audio/speech`
- **Method:** POST
- **Called by:** `voice_chat.gd → request_tts()`
- **Body:** `{input, voice, model: "tts-1", response_format: "mp3"}`
- **Response:** Raw MP3 binary (downloaded to `/tmp/agent_office_response.mp3`)
- **Voices:** alloy, echo, fable, onyx, nova, shimmer

### Connection Test
- **URL:** `{gateway_url}/v1/models`
- **Method:** GET
- **Called by:** `settings_menu.gd` connection tab test button

## HTTPRequest Nodes
- `ChatUI/HTTPRequest` — chat completions
- `VoiceChat/STTRequest` — STT (created in code)
- `VoiceChat/TTSRequest` — TTS with `download_file` set (created in code)

## Error Handling
All callbacks check `response_code == 200`. Errors shown in chat as red BBCode text. Voice failures emit empty transcription signal.
