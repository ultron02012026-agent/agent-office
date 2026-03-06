# Changelog

All notable changes to Agent Office.

---

## v0.9.0 — 2026-03-05
*Major Layout Overhaul*

### Changed
- **Complete floor plan redesign** — replaced old hallway-with-rooms-on-sides layout with a new open-plan building
- **New layout:** 3 offices across the top (Ultron, Spinfluencer, Dexer), 2 rooms on left column (DJ Sam, Coming Soon), large open lobby area on the right with Mollie's reception desk, entrance at bottom-right
- **Building is 30×30 units** with proper exterior walls and interior dividers
- **Player spawns at entrance** (bottom-right) facing into the building toward Mollie
- **Bulletin board repositioned** to left column east wall, visible from open area

### New
- **DJ Sam room** — purple/orange theme with turntable placeholder (flat CSGCylinder), speaker stacks, headphones, replaces old Architect room
- **Coming Soon room** — gray/dim locked room with no agent, no furniture, locked door (solid with collision, doesn't open). Placeholder for future agents
- **Mollie — Office Manager** — open-area reception desk (diamond-shaped rotated CSGBox at 45°), gold/warm avatar, Area3D interaction zone. System prompt: friendly office manager who helps navigate, manage settings, and control the environment
- **Entrance area** — "Agent Office" sign above entrance gap in south-east wall, welcome mat (different floor color)
- **Open lobby** — large right-side area with good lighting (3 OmniLight3D), skylight effect on ceiling

### Updated Scripts
- `settings_manager.gd` — added DJ Sam and Mollie to default agent_configs
- `minimap.gd` — complete rewrite with new room positions matching new layout
- `agent_social.gd` — updated agent positions, doorway positions, and agent list (5 agents)
- `notification_manager.gd` — added DJ Sam and Mollie to notification rotation
- `bulletin_board.gd` — repositioned to open area wall, added DJ Sam and Mollie
- `command_palette.gd` — added /goto djsam, /goto mollie, /goto entrance; updated all teleport positions

### Removed
- Old hallway layout (north-south corridor with rooms on sides)
- Old lobby at south end
- Architect room and all Architect references (replaced by DJ Sam)

---

## v0.8.0 — 2026-03-05
*Voice-Only Interaction*

### Changed
- **Voice-only mode** — removed text chat input entirely. Players interact with agents exclusively via push-to-talk voice (V key). The chat panel is now a **transcript panel** (display only)
- **Transcript panel redesign** — moved from right side to bottom-left (subtitle style), semi-transparent (75% opacity), narrower and shorter. Shows voice status indicator at bottom
- **Auto-activate voice** — voice mode activates automatically on room entry, no Tab toggle needed
- **Voice status indicators** — bottom of transcript shows: 🎙️ Listening, 🔴 Recording, ⏳ Processing, 💭 Thinking, 🔊 Speaking
- **Thinking indicator** — shows "..." in transcript while waiting for agent response, removed when response arrives
- **Escape exits room** — since there's no text input to close, Escape now exits the room directly
- **Always TTS** — agent responses always trigger TTS playback (not conditional on voice_mode toggle)

### Removed
- Text input field (LineEdit) and Send button from chat panel
- `chat_send` input action (Enter key to send)
- `toggle_voice` input action (Tab key to toggle voice/text)
- `voice_mode` toggle from VoiceChat (always voice when in room)
- Clear button from chat panel

### Tests
- Updated test_chat_ui.gd for transcript-only behavior (voice status states, no text input validation)
- Updated test_voice_chat.gd (removed toggle tests, added always-voice-mode test)

---

## v0.7.0 — 2026-03-05
*Multiplayer Foundation & Advanced Features*

### New
- **Agent-to-Agent visits** — every ~90 seconds, a random agent avatar "visits" another room's doorway, stays 10s, then returns. Pure visual showing agents are alive and collaborating (`agent_social.gd`)
- **Command palette** — press `/` to open VS Code-style command overlay. Commands: `/goto <room>`, `/status`, `/clear`, `/sprint <minutes>` (`command_palette.gd`)
- **Bulletin board** — shared whiteboard in the lobby showing recent activity across all rooms. Auto-updates as you chat with agents (`bulletin_board.gd`)
- **Sprint timer** — pomodoro-style countdown HUD. Activate via `/sprint 25`. Progress bar at top of screen, color shifts green→yellow→red, flash effect on completion (`sprint_timer.gd`)
- **Music/ambiance system** — background ambient sound with different loops per zone (lobby hum, office quiet, hallway echo). Crossfades between zones, volume from settings (`ambiance.gd`)
- **Screenshot mode** — F12 hides HUD, captures screenshot to `user://screenshots/` with timestamp, shows "📸 Saved!" indicator (`screenshot.gd`)
- **Debug overlay** — F3 toggles performance display: FPS, player position, current room, gateway status, memory usage, day cycle time, active visits, sprint timer (`debug_overlay.gd`)

### Tests
- **354+ total tests** (up from 239): agent social visits (17), command palette (22), bulletin board (15), sprint timer (18), ambiance (13), screenshot (14), debug overlay (16)

---

## v0.6.0 — 2026-03-05
*Game Feel & Immersion*

### New
- **Agent idle animations** — gentle floating bob (sine wave), subtle rotation, avatars face the player when they enter the room
- **Footstep sound system** — timed footstep audio cues synced to movement speed, different AudioStreamPlayer stubs for hallway vs room surfaces, stops when player stops
- **Day/night cycle** — DirectionalLight color temperature shifts over time (warm dawn → neutral noon → warm evening → dim night), skylight mesh on ceiling brightens/dims
- **Chat history persistence** — leaving a room and returning restores your previous conversation; Clear button to reset a room's history
- **Notification system** — simulated notification badges (❗) appear above agent doors every 60s, notification sound stub, entering room clears notification
- **Office decorations per agent:**
  - Ultron: extra monitor, server rack (tall CSGBox with blue emission glow)
  - Spinfluencer: recording light (red glowing sphere + OmniLight), vinyl record (CSGCylinder on desk)
  - Dexer: filing cabinet (3 stacked CSGBoxes), colored label sample boxes on desk
  - Architect: blueprint (flat blue CSGBox on desk), drafting table (angled CSGBox with blueprint)
- **Door animations** — door frame pillars + colored strip at top per room theme; thin door panel slides up when player approaches (lerp animation via `door_anim.gd`)
- **New scripts:** `day_cycle.gd`, `notification_manager.gd`, `door_anim.gd`

### Tests
- **239 total tests** (up from 178): day/night cycle (18), notifications (16), door animations (9), immersion features (18 — avatar bob, face-player, footstep timing, chat persistence)

---

## v0.5.0 — 2026-03-05
*Polish & Gameplay Feel*

### New
- **Welcome overlay** — shows controls on game start, dismisses on any keypress, then captures mouse
- **Room title cards** — agent name + role shown center-screen on room entry, fades after 2 seconds
- **Minimap** — bottom-right HUD showing floor plan with colored room rectangles, player dot, and room labels
- **Agent status indicators** — colored dots above each door (green=ready, yellow=thinking, red=disconnected)
- **Interaction prompts** — "Enter [Room]'s Office →" shown when near a doorway but not yet inside
- **Better lighting** — ambient light prevents pitch-black areas; hallway lights added; emissive glow on whiteboards and TV screens
- **Audio cue stubs** — AudioStreamPlayer nodes wired up for room enter/exit sounds (drop in .wav/.ogg files later)
- **Proximity zones** — larger Area3D around each doorway for interaction prompts

### Tests
- 52 total tests (up from 35): welcome overlay state, title card fade, agent status states, minimap coordinate mapping, proximity prompts

---

## v0.5.0 — 2026-03-05
*Polish, UX, Coverage*

### New
- **Welcome overlay** — title + controls guide on launch, press any key to start
- **Room title cards** — agent name fades in center-screen on room entry
- **Minimap** — bottom-right floor plan with player dot and room labels
- **Agent status indicators** — green/yellow/red dots above doors (ready/thinking/disconnected)
- **Interaction prompts** — "Enter [Room]'s Office →" when near doorways
- **Better lighting** — ambient light, hallway lights, emissive whiteboards + TV screens
- **Tailscale support** — default gateway URL points to Mac mini over Tailscale, auth token in settings
- **Agent-friendly codebase** — AGENTS.md, per-directory READMEs, .claude/commands/, .cursorrules, inline doc headers
- **178 tests passing** (up from 35) — voice chat, settings menu, avatars, minimap, proximity prompts all covered

## v0.3.0 — 2026-03-05
*Voice, Settings, Avatars*

- Push-to-talk voice chat (V key) with spatial audio from agent position
- TTS responses played back via AudioStreamPlayer3D
- Text chat as fallback (Tab to toggle)
- Settings menu (Esc key): audio, connection, controls, display, agent config
- Settings persist to `user://settings.cfg`
- Colored agent avatar capsules sitting at desks (pulse when speaking)
- Room name labels on door frames
- Headless test runner: `godot --headless --script tests/run_tests.gd`

## v0.2.0 — 2026-03-05
*Collision, Furniture, Polish*

### Fixes
- Wall collision on all CSGBox3D nodes (no more walking through walls)
- Doorways cut into hallway walls (2m gaps at each room entrance)
- Removed dead `chat_theme` sub_resource
- Chat input disables with "thinking..." while waiting for API response

### New
- **Lobby** — Spawn area at south end with "Agent Office" sign and warm lighting
- **Whiteboards** — 2m × 1.2m white surface on back wall of each room (Excalidraw-ready)
- **TV screens** — 2 per room (large on side wall, smaller secondary)
- **Visitor chairs** — Second seat in each room
- **Ceiling** — Enclosed building
- **Per-room lighting** — Colored OmniLight3D (blue/Ultron, pink/Spinfluencer, green/Dexer, warm/Architect)
- **HUD** — Top-left label showing current location
- **Camera bob** — Subtle head movement while walking
- North hallway end wall

## v0.1.0 — 2026-03-05
*Initial MVP*

### Core
- Godot 4 project, first-person WASD + mouse look
- 4 rooms: Ultron, Spinfluencer, Dexer, Architect
- Central hallway connecting all rooms
- Area3D room detection (enter/exit triggers)
- Chat panel opens on room entry, closes on exit
- OpenClaw API integration (`localhost:3007/v1/chat/completions`)
- Per-room system prompts
- BBCode-formatted chat with colored agent names
- Conversation history maintained per visit
- Player: blue capsule with CameraPivot
- Desks and monitor placeholders in each room
- Room name Label3D signs above doorways
