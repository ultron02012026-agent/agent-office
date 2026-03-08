## Runtime music player for Agent Office jukebox system.
## Loads OGG/MP3 files from disk at runtime using AudioStreamOggVorbis.load_from_file().
## Supports queue, skip, pause, resume, shuffle, and repeat modes.
extends Node

const MUSIC_DIR = "/Users/ultron/.openclaw/screen-content/shared/music/tracks/"

var queue: Array[String] = []  # filenames relative to MUSIC_DIR
var is_shuffled: bool = false
var repeat_mode: int = 0  # 0=off, 1=track, 2=queue
var now_playing: String = ""
var _played_history: Array[String] = []  # for repeat-queue mode

var _player: AudioStreamPlayer

func _ready():
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	_player.finished.connect(_on_track_finished)
	print("[MusicPlayer] Ready. Music dir: ", MUSIC_DIR)

func play_track(filename: String):
	var path = MUSIC_DIR + filename
	print("[MusicPlayer] play_track: ", path)
	if not FileAccess.file_exists(path):
		push_warning("[MusicPlayer] File not found: " + path)
		print("[MusicPlayer] ERROR: File not found: ", path)
		return

	var stream: AudioStream = null
	if filename.ends_with(".ogg"):
		stream = AudioStreamOggVorbis.load_from_file(path)
	elif filename.ends_with(".mp3"):
		stream = AudioStreamMP3.load_from_file(path)
	else:
		push_warning("[MusicPlayer] Unsupported format: " + filename)
		print("[MusicPlayer] ERROR: Unsupported format: ", filename)
		return

	if stream == null:
		push_warning("[MusicPlayer] Failed to load: " + path)
		print("[MusicPlayer] ERROR: Failed to load stream from: ", path)
		return

	_player.stream = stream
	_player.play()
	now_playing = filename
	print("[MusicPlayer] Now playing: ", filename)

func queue_track(filename: String):
	queue.append(filename)
	print("[MusicPlayer] Queued: ", filename, " (queue size: ", queue.size(), ")")
	# If nothing is playing, start immediately
	if not _player.playing and now_playing == "":
		skip()

func skip():
	print("[MusicPlayer] Skip requested. Queue size: ", queue.size())
	if queue.is_empty():
		if repeat_mode == 2 and _played_history.size() > 0:
			# Repeat queue: reload history into queue and play
			queue = _played_history.duplicate()
			_played_history.clear()
			print("[MusicPlayer] Repeat queue: reloaded ", queue.size(), " tracks")
		else:
			_player.stop()
			now_playing = ""
			print("[MusicPlayer] Queue empty, stopped.")
			return

	if queue.is_empty():
		_player.stop()
		now_playing = ""
		return

	var next: String
	if is_shuffled:
		var idx = randi() % queue.size()
		next = queue[idx]
		queue.remove_at(idx)
	else:
		next = queue.pop_front()

	if not now_playing.is_empty():
		_played_history.append(now_playing)
	play_track(next)

func stop():
	print("[MusicPlayer] Stop.")
	_player.stop()
	queue.clear()
	_played_history.clear()
	now_playing = ""

func pause():
	print("[MusicPlayer] Pause.")
	_player.stream_paused = true

func resume():
	print("[MusicPlayer] Resume.")
	_player.stream_paused = false
	if not _player.playing and _player.stream != null:
		_player.play()

func is_playing() -> bool:
	return _player.playing and not _player.stream_paused

func _on_track_finished():
	print("[MusicPlayer] Track finished: ", now_playing)
	if repeat_mode == 1:
		# Repeat current track
		print("[MusicPlayer] Repeating track.")
		_player.play()
		return
	if not now_playing.is_empty():
		_played_history.append(now_playing)
		now_playing = ""
	skip()
