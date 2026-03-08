# Agent Office Music System — Technical Spec

> **Status:** Draft  
> **Created:** 2026-03-07  
> **Author:** Ultron  

## Overview

A jukebox/music system for Agent Office where users request music (by name, mood, YouTube link, or playlist) through chat. The agent downloads audio via `yt-dlp`, converts it, and triggers playback in Godot via command tags. Tracks can be saved to favorites, queued, skipped, and browsed.

---

## Architecture

```
User Request → Agent (OpenClaw) → yt-dlp/ffmpeg → local OGG file
                                                      ↓
Agent sends [MUSIC_PLAY:filename] → Godot parses tag → loads OGG at runtime → AudioStreamPlayer
```

**Key insight:** Godot 4 supports `AudioStreamOggVorbis.load_from_file(path)` and `AudioStreamMP3.load_from_file(path)` for runtime loading from absolute disk paths. No import step needed.

---

## Phase 1: Core Audio Pipeline

### Complexity: Medium

### Audio Format Decision

**OGG Vorbis** is the primary format:
- Native runtime loading via `AudioStreamOggVorbis.load_from_file()`
- Smaller files than WAV, good quality
- Well-supported by `ffmpeg` and `yt-dlp`
- MP3 also works (`AudioStreamMP3.load_from_file()`) as fallback

### Directory Structure

```
~/.openclaw/screen-content/shared/music/
├── tracks/                    # Downloaded audio files
│   ├── abc123.ogg            # Named by yt-dlp video ID
│   ├── def456.ogg
│   └── ...
├── library.json              # Track metadata & favorites
└── history.json              # Playback history
```

Using `~/.openclaw/screen-content/shared/music/` keeps it accessible to both the agent (filesystem) and Godot (via the content server at `http://localhost:18790/shared/music/` if needed, though Godot will use absolute paths).

### Download & Conversion Pipeline

**yt-dlp command** (agent runs this via shell):
```bash
# Search and download best audio, convert to OGG
yt-dlp -x --audio-format vorbis --audio-quality 5 \
  -o "$HOME/.openclaw/screen-content/shared/music/tracks/%(id)s.ogg" \
  --no-playlist --max-downloads 1 \
  "ytsearch1:chill house music"
```

**For direct YouTube URLs:**
```bash
yt-dlp -x --audio-format vorbis --audio-quality 5 \
  -o "$HOME/.openclaw/screen-content/shared/music/tracks/%(id)s.ogg" \
  --no-playlist \
  "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
```

**Get metadata (title, duration, thumbnail) without downloading:**
```bash
yt-dlp --print "%(id)s|%(title)s|%(duration)s|%(thumbnail)s" \
  --no-download "ytsearch1:chill house music"
```

**If yt-dlp's built-in conversion fails, use ffmpeg directly:**
```bash
ffmpeg -i input.webm -vn -c:a libvorbis -q:a 5 output.ogg
```

### Command Tags

| Tag | Description | Example |
|-----|-------------|---------|
| `[MUSIC_PLAY:filename]` | Play a track immediately (stops current) | `[MUSIC_PLAY:abc123.ogg]` |
| `[MUSIC_QUEUE:filename]` | Add track to end of queue | `[MUSIC_QUEUE:def456.ogg]` |
| `[MUSIC_SKIP]` | Skip to next track in queue | |
| `[MUSIC_STOP]` | Stop playback and clear queue | |
| `[MUSIC_PAUSE]` | Pause current track | |
| `[MUSIC_RESUME]` | Resume paused track | |
| `[MUSIC_UP]` | Volume up (existing) | |
| `[MUSIC_DOWN]` | Volume down (existing) | |
| `[MUSIC_SHUFFLE]` | Toggle shuffle mode | |
| `[MUSIC_REPEAT]` | Cycle repeat mode (off→track→queue) | |
| `[MUSIC_NOW]` | (Internal) Agent queries now-playing state | |

The filename is relative to the `tracks/` directory. Just the filename, not the full path.

### Godot Implementation

#### Files to Create

**`scripts/music_player.gd`** — New autoload or node script:

```gdscript
extends Node

const MUSIC_DIR = "/Users/ultron/.openclaw/screen-content/shared/music/tracks/"

var current_player: AudioStreamPlayer
var queue: Array[String] = []  # filenames
var is_shuffled: bool = false
var repeat_mode: int = 0  # 0=off, 1=track, 2=queue
var now_playing: String = ""

func _ready():
	current_player = AudioStreamPlayer.new()
	current_player.bus = "Music"  # Use existing Music bus if available
	add_child(current_player)
	current_player.finished.connect(_on_track_finished)

func play_track(filename: String):
	var path = MUSIC_DIR + filename
	if not FileAccess.file_exists(path):
		push_warning("Music file not found: " + path)
		return
	
	var stream: AudioStream
	if filename.ends_with(".ogg"):
		stream = AudioStreamOggVorbis.load_from_file(path)
	elif filename.ends_with(".mp3"):
		stream = AudioStreamMP3.load_from_file(path)
	else:
		push_warning("Unsupported format: " + filename)
		return
	
	if stream == null:
		push_warning("Failed to load audio: " + path)
		return
	
	current_player.stream = stream
	current_player.play()
	now_playing = filename

func queue_track(filename: String):
	queue.append(filename)
	# If nothing playing, start immediately
	if not current_player.playing and now_playing == "":
		skip()

func skip():
	if queue.is_empty():
		if repeat_mode == 2 and now_playing != "":
			# Repeat queue: would need to track full queue history
			current_player.stop()
			now_playing = ""
		else:
			current_player.stop()
			now_playing = ""
		return
	
	var next: String
	if is_shuffled:
		next = queue[randi() % queue.size()]
		queue.erase(next)
	else:
		next = queue.pop_front()
	
	play_track(next)

func stop():
	current_player.stop()
	queue.clear()
	now_playing = ""

func pause():
	current_player.stream_paused = true

func resume():
	current_player.stream_paused = false
	if not current_player.playing:
		current_player.play()

func _on_track_finished():
	if repeat_mode == 1:
		# Repeat current track
		current_player.play()
		return
	skip()
```

#### Files to Modify

**`scripts/chat_ui.gd`** — Extend `_handle_music_commands()`:

```gdscript
func _handle_music_commands(text: String):
	# Keep existing MUSIC_UP/DOWN/OFF/ON handling
	if not ambiance or not ambiance.has_node("BackgroundMusic"):
		return
	var music = ambiance.get_node("BackgroundMusic")
	
	# Existing volume controls
	if "[MUSIC_UP]" in text:
		music.volume_db = min(music.volume_db + 3.0, 0.0)
	if "[MUSIC_DOWN]" in text:
		music.volume_db = max(music.volume_db - 3.0, -40.0)
	if "[MUSIC_OFF]" in text:
		music.stream_paused = true
	if "[MUSIC_ON]" in text:
		music.stream_paused = false
		if not music.playing:
			music.play()
	
	# New jukebox controls
	var music_player = get_node_or_null("/root/MusicPlayer")  # or however it's accessed
	if not music_player:
		return
	
	# [MUSIC_PLAY:filename.ogg]
	var play_match = _extract_tag(text, "MUSIC_PLAY")
	if play_match != "":
		# Pause background music when jukebox plays
		music.stream_paused = true
		music_player.play_track(play_match)
	
	# [MUSIC_QUEUE:filename.ogg]
	var queue_match = _extract_tag(text, "MUSIC_QUEUE")
	if queue_match != "":
		music_player.queue_track(queue_match)
	
	if "[MUSIC_SKIP]" in text:
		music_player.skip()
	if "[MUSIC_STOP]" in text:
		music_player.stop()
		music.stream_paused = false  # Resume background music
	if "[MUSIC_PAUSE]" in text:
		music_player.pause()
	if "[MUSIC_RESUME]" in text:
		music_player.resume()
	if "[MUSIC_SHUFFLE]" in text:
		music_player.is_shuffled = !music_player.is_shuffled
	if "[MUSIC_REPEAT]" in text:
		music_player.repeat_mode = (music_player.repeat_mode + 1) % 3

func _extract_tag(text: String, tag_name: String) -> String:
	var pattern = "[" + tag_name + ":"
	var start = text.find(pattern)
	if start == -1:
		return ""
	start += pattern.length()
	var end = text.find("]", start)
	if end == -1:
		return ""
	return text.substr(start, end - start)
```

Also update the tag stripping in the display function (around line 659):
```gdscript
# Add new tags to strip list
for tag in ["[MUSIC_UP]", "[MUSIC_DOWN]", "[MUSIC_OFF]", "[MUSIC_ON]",
            "[MUSIC_SKIP]", "[MUSIC_STOP]", "[MUSIC_PAUSE]", "[MUSIC_RESUME]",
            "[MUSIC_SHUFFLE]", "[MUSIC_REPEAT]", "[TV_OFF]"]:
    # strip simple tags...

# Strip parameterized tags with regex
var regex = RegEx.new()
regex.compile("\\[MUSIC_(?:PLAY|QUEUE):[^\\]]+\\]")
final_text = regex.sub(final_text, "", true)
```

Update system prompt context (gateway_ws.gd lines 88-90 and chat_ui.gd line 486):
```
Music: [MUSIC_PLAY:file] [MUSIC_QUEUE:file] [MUSIC_SKIP] [MUSIC_STOP] [MUSIC_PAUSE] [MUSIC_RESUME] [MUSIC_UP] [MUSIC_DOWN] [MUSIC_SHUFFLE] [MUSIC_REPEAT]
```

### Prerequisites
- `yt-dlp` installed ✅ (confirmed on Mac mini)
- `ffmpeg` installed ✅ (confirmed on Mac mini)
- Music directory created: `mkdir -p ~/.openclaw/screen-content/shared/music/tracks`

### Risks & Limitations
- **Large files:** Long tracks (1hr+ mixes) could be 50-100MB as OGG. Consider a max duration flag: `--match-filter "duration<3600"`
- **Download time:** First play of a new track has latency (5-30s for download+convert). Agent should acknowledge: "Downloading now, one moment..."
- **Disk space:** Need cleanup strategy (Phase 4)
- **Godot path:** Hardcoded absolute path to music dir. Could use an environment variable or config file instead.

---

## Phase 2: Agent Integration

### Complexity: Medium

### Library JSON Schema

**`~/.openclaw/screen-content/shared/music/library.json`:**
```json
{
  "tracks": {
    "dQw4w9WgXcQ": {
      "id": "dQw4w9WgXcQ",
      "title": "Rick Astley - Never Gonna Give You Up",
      "artist": "Rick Astley",
      "duration": 213,
      "filename": "dQw4w9WgXcQ.ogg",
      "source_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "thumbnail": "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
      "tags": ["pop", "80s", "classic"],
      "added_at": "2026-03-07T23:00:00Z",
      "play_count": 5,
      "favorite": true
    }
  },
  "playlists": {
    "favorites": {
      "name": "Favorites",
      "track_ids": ["dQw4w9WgXcQ"]
    },
    "chill": {
      "name": "Chill Vibes",
      "track_ids": []
    }
  }
}
```

### History JSON Schema

**`~/.openclaw/screen-content/shared/music/history.json`:**
```json
{
  "plays": [
    {
      "track_id": "dQw4w9WgXcQ",
      "played_at": "2026-03-07T23:15:00Z",
      "requested_by": "Ethan",
      "request_text": "play never gonna give you up"
    }
  ]
}
```

### Agent Workflow

The agent (Ultron) handles the full pipeline in its response:

1. **Receive request** — User says "play some chill house music"
2. **Search** — Agent runs: `yt-dlp --print "%(id)s|%(title)s|%(duration)s" --no-download "ytsearch1:chill house music"`
3. **Check library** — Read `library.json`, check if track ID already downloaded
4. **Download if needed** — `yt-dlp -x --audio-format vorbis -o "...tracks/%(id)s.ogg" "URL"`
5. **Update library.json** — Add track metadata
6. **Update history.json** — Log the play
7. **Send command tag** — Include `[MUSIC_PLAY:abc123.ogg]` in response
8. **Respond naturally** — "🎵 Now playing: Chill House Mix by LoFi Records"

### Agent Skill / System Prompt Addition

The agent needs instructions in its system prompt or skill file:

```
## Music System

You are the office DJ. When users request music:

1. Search YouTube: `yt-dlp --print "%(id)s|%(title)s|%(duration)s" --no-download "ytsearch1:<query>"`
2. Check if already downloaded: `ls ~/.openclaw/screen-content/shared/music/tracks/<id>.ogg`
3. If not downloaded: `yt-dlp -x --audio-format vorbis --audio-quality 5 -o "$HOME/.openclaw/screen-content/shared/music/tracks/%(id)s.ogg" --no-playlist "<url_or_search>"`
4. Update library.json with track metadata
5. Include `[MUSIC_PLAY:<id>.ogg]` in your response

For queue: use `[MUSIC_QUEUE:<id>.ogg]` instead.
For controls: `[MUSIC_SKIP]` `[MUSIC_STOP]` `[MUSIC_PAUSE]` `[MUSIC_RESUME]`

Library file: ~/.openclaw/screen-content/shared/music/library.json
History file: ~/.openclaw/screen-content/shared/music/history.json

When asked "what's playing?" — read library.json and check the most recent history entry.
When asked to save/favorite — update library.json, set favorite: true.
When asked to play favorites — read library.json, filter favorites, queue them all with [MUSIC_PLAY] + [MUSIC_QUEUE] tags.
```

### Files to Create/Modify
- **Create:** `library.json`, `history.json` (agent creates on first use)
- **Modify:** Agent skill/system prompt to include music instructions
- **Modify:** `gateway_ws.gd` context string to list new music tags

### Risks
- **Race conditions:** Agent writing JSON while Godot might read it. Low risk since Godot doesn't read these files (agent-side only).
- **Search quality:** `ytsearch1` returns one result; might not be the best. Agent can search multiple and pick.
- **yt-dlp updates:** YouTube changes may break downloads. Keep `yt-dlp` updated: `yt-dlp -U`

---

## Phase 3: Playback Controls

### Complexity: Medium

### Queue System

Already implemented in Phase 1's `music_player.gd`. The queue is an in-memory array of filenames. Agent sends:
- `[MUSIC_PLAY:first.ogg]` for immediate play
- `[MUSIC_QUEUE:second.ogg][MUSIC_QUEUE:third.ogg]` for subsequent tracks

### Now Playing Display

Use existing `[TV_SHOW:url]` to display a "now playing" page on a monitor:

**Create:** `~/.openclaw/screen-content/shared/music/now-playing.html`

```html
<!DOCTYPE html>
<html>
<head>
<style>
  body { background: #1a1a2e; color: white; font-family: sans-serif;
         display: flex; align-items: center; justify-content: center;
         height: 100vh; margin: 0; }
  .container { text-align: center; }
  .art { width: 300px; height: 300px; border-radius: 12px; object-fit: cover; }
  .title { font-size: 28px; margin-top: 20px; }
  .artist { font-size: 18px; color: #888; margin-top: 8px; }
  .eq { font-size: 40px; margin-top: 16px; }
</style>
</head>
<body>
<div class="container">
  <img class="art" id="art" src="">
  <div class="title" id="title">Nothing Playing</div>
  <div class="artist" id="artist"></div>
  <div class="eq">🎵</div>
</div>
<script>
  // Poll now-playing state from a JSON file
  async function update() {
    try {
      const r = await fetch('/shared/music/now-playing.json?' + Date.now());
      const d = await r.json();
      document.getElementById('title').textContent = d.title || 'Nothing Playing';
      document.getElementById('artist').textContent = d.artist || '';
      document.getElementById('art').src = d.thumbnail || '';
    } catch(e) {}
  }
  setInterval(update, 3000);
  update();
</script>
</body>
</html>
```

Agent writes `now-playing.json` when playing a track:
```json
{
  "title": "Chill House Mix",
  "artist": "LoFi Records",
  "thumbnail": "https://i.ytimg.com/vi/abc123/maxresdefault.jpg",
  "track_id": "abc123",
  "started_at": "2026-03-07T23:15:00Z"
}
```

Then sends `[TV_SHOW:http://localhost:18790/shared/music/now-playing.html]` alongside the play command.

### Volume Control

Keep existing `[MUSIC_UP]` / `[MUSIC_DOWN]` — they modify `volume_db` on the AudioStreamPlayer. The jukebox player should use the same audio bus so volume applies uniformly.

### Shuffle & Repeat

Handled in `music_player.gd` (Phase 1). Agent toggles via `[MUSIC_SHUFFLE]` and `[MUSIC_REPEAT]`.

### Crossfade (Nice to Have)

Use two AudioStreamPlayers, fade between them:
```gdscript
var player_a: AudioStreamPlayer
var player_b: AudioStreamPlayer
var active_player: AudioStreamPlayer
var crossfade_duration: float = 3.0

func crossfade_to(filename: String):
    var inactive = player_b if active_player == player_a else player_a
    # Load new track on inactive player
    inactive.stream = AudioStreamOggVorbis.load_from_file(MUSIC_DIR + filename)
    inactive.volume_db = -40.0
    inactive.play()
    # Tween: fade inactive up, active down
    var tween = create_tween()
    tween.tween_property(inactive, "volume_db", 0.0, crossfade_duration)
    tween.parallel().tween_property(active_player, "volume_db", -40.0, crossfade_duration)
    tween.tween_callback(func(): active_player.stop())
    active_player = inactive
```

### Files to Create/Modify
- **Create:** `now-playing.html`, agent writes `now-playing.json`
- **Modify:** `music_player.gd` — add crossfade support (optional)

---

## Phase 4: Polish

### Complexity: Medium-Complex

### "What's Playing?" Response

Agent reads `now-playing.json` and `library.json` to respond:
> "🎵 Now playing: *Chill House Mix* by LoFi Records (3:45 remaining). It's been played 5 times — one of your favorites!"

### Smart Recommendations

Agent reads `history.json` and `library.json` to suggest tracks:
- "Last time you played chill house, lofi beats, and jazz. Want more of that?"
- Search based on tags from previously played tracks

### Mood-Based Playlists

Agent maps mood keywords to search queries:
- "chill" → `ytsearch5:chill lofi beats`
- "focus" → `ytsearch5:deep focus music`
- "party" → `ytsearch5:party house music 2026`
- "ambient" → `ytsearch5:ambient electronic music`

Agent downloads multiple tracks and queues them all.

### Auto-Play on Office Entry

Option A: Agent detects Ethan entering the office (via existing game events) and proactively starts music.
Option B: Godot reads `library.json` on startup and auto-plays favorites/last session. Simpler to implement in the agent's system prompt: "When Ethan enters the office, offer to resume music from last session."

### Cleanup of Old Files

Agent periodically (or on request) cleans up:
```bash
# Delete tracks not played in 30+ days and not favorited
# Agent reads library.json, checks play history, removes old entries
```

Or set a max disk usage (e.g., 1GB) and remove least-recently-played non-favorites when exceeded.

### Files to Create/Modify
- **Modify:** Agent skill with mood mappings and recommendation logic
- **Modify:** `now-playing.html` for richer display
- **Create:** Cleanup script (or inline in agent logic)

---

## Godot 4 Runtime Audio — Technical Details

### Confirmed Working
- **OGG Vorbis:** `AudioStreamOggVorbis.load_from_file("/absolute/path/to/file.ogg")` — works in Godot 4.x
- **MP3:** `AudioStreamMP3.load_from_file("/absolute/path/to/file.mp3")` — works in Godot 4.x
- **WAV:** No native runtime loader. Requires custom GDScript parser.

### Recommendation
Use **OGG Vorbis** exclusively:
- Native runtime loading
- Good compression (smaller than MP3 at equivalent quality)
- Open format, no licensing issues
- `yt-dlp` can output directly to OGG with `--audio-format vorbis`

### Key Considerations
- Files loaded at runtime are NOT imported — no `.import` file generated
- Absolute paths work fine (not just `res://` or `user://`)
- No streaming from HTTP — must be a local file path
- Loading is synchronous — large files may cause a brief hitch. For very long tracks, consider loading on a thread.

---

## yt-dlp & ffmpeg Commands Reference

```bash
# Search and download as OGG
yt-dlp -x --audio-format vorbis --audio-quality 5 \
  -o "$HOME/.openclaw/screen-content/shared/music/tracks/%(id)s.ogg" \
  --no-playlist --max-downloads 1 \
  "ytsearch1:QUERY"

# Download from URL as OGG
yt-dlp -x --audio-format vorbis --audio-quality 5 \
  -o "$HOME/.openclaw/screen-content/shared/music/tracks/%(id)s.ogg" \
  --no-playlist \
  "https://www.youtube.com/watch?v=VIDEO_ID"

# Get metadata only
yt-dlp --print "%(id)s|%(title)s|%(duration)s|%(thumbnail)s|%(uploader)s" \
  --no-download "ytsearch1:QUERY"

# Convert existing file to OGG (fallback)
ffmpeg -i input.webm -vn -c:a libvorbis -q:a 5 output.ogg

# Extract thumbnail
yt-dlp --write-thumbnail --skip-download \
  -o "$HOME/.openclaw/screen-content/shared/music/tracks/%(id)s" \
  "URL"
```

---

## Legal / TOS Considerations

- **YouTube TOS:** Downloading audio from YouTube violates their Terms of Service. This is for personal/private use only.
- **Copyright:** Downloaded music is copyrighted. Don't redistribute.
- **yt-dlp:** The tool itself is legal; usage may vary by jurisdiction.
- **Mitigation:** This is a personal project on a private machine. Not public-facing. Keep downloads local, don't share.
- **Alternative:** For a production system, consider Spotify API or other licensed music services.

---

## Implementation Order

| Phase | Effort | Dependencies |
|-------|--------|-------------|
| Phase 1: Core Pipeline | ~4-6 hours | yt-dlp, ffmpeg installed |
| Phase 2: Agent Integration | ~2-3 hours | Phase 1 |
| Phase 3: Playback Controls | ~3-4 hours | Phase 1 |
| Phase 4: Polish | ~4-6 hours | Phases 1-3 |

**Recommended start:** Phase 1 + Phase 2 together (get a track playing end-to-end), then Phase 3, then Phase 4 as nice-to-haves.

---

## Summary of Files

### New Files
| File | Type | Phase |
|------|------|-------|
| `scripts/music_player.gd` | Godot script | 1 |
| `~/.openclaw/screen-content/shared/music/tracks/` | Directory | 1 |
| `~/.openclaw/screen-content/shared/music/library.json` | Data | 2 |
| `~/.openclaw/screen-content/shared/music/history.json` | Data | 2 |
| `~/.openclaw/screen-content/shared/music/now-playing.html` | Web page | 3 |
| `~/.openclaw/screen-content/shared/music/now-playing.json` | Data | 3 |

### Modified Files
| File | Change | Phase |
|------|--------|-------|
| `scripts/chat_ui.gd` | Parse new MUSIC_* tags, call music_player | 1 |
| `scripts/gateway_ws.gd` | Update system prompt with new tags | 1 |
| Agent skill/system prompt | Music DJ instructions | 2 |
