# Changelog

All notable changes to Agent Office.

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

## v0.3.0 — In Progress
*Voice, Settings, Tests*

- [ ] Push-to-talk voice chat (V key) with spatial audio from agent position
- [ ] TTS responses played back as 3D audio
- [ ] Text chat as fallback (Tab to toggle)
- [ ] Settings menu (Esc key): audio, connection, controls, display, agent config
- [ ] Settings persist to disk
- [ ] Agent avatar capsules sitting in chairs (colored per agent)
- [ ] Avatar pulses when agent is speaking
- [ ] Room name labels on door frames
- [ ] Test suite: chat_ui, room_area, player, settings
- [ ] Headless test runner: `godot --headless --script tests/run_tests.gd`

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
