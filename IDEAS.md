# Agent Office — Ideas

## 🔥 Big Ideas

### Live TV in the Lobby
A wall-mounted TV playing a live CNBC stream (or other feeds). Ultron controls what's on — could switch between CNBC, weather radar, sports scores, market tickers. WebView or HLS stream rendered on a 3D surface. Would make the office feel alive.

### Agent-Controlled Screens
Agents can already put static images on their monitors via `[TV_SHOW:url]`. Extend this to:
- Live web content (WebView on a 3D plane)
- Rotating dashboards (Spinfluencer shows submission stats, Dexer shows label data)
- YouTube/Twitch embeds

### Custom Maps / Build Your Own Office
The core idea: pick any office layout you want. Modular map packs that swap the entire floor plan while keeping the agent connection system intact. Examples:
- **The Office (Dunder Mifflin)** — Michael's office, bullpen, conference room, break room, warehouse
- **Startup Loft** — open floor plan, standing desks, ping pong table, rooftop
- **Nightclub** — DJ booth, dance floor, VIP, bar, green room
- **Space Station** — sci-fi corridors, command bridge, labs
- **Your Apartment** — literal recreation of your living space with agents in rooms
- **Agent-designed rooms** — let each agent customize their own space ("DJ Sam, redesign your office")

Each map = a different main.tscn with room areas wired to the same agent sessions. The game becomes a canvas — build whatever environment you want to work in.

### Multiplayer / Spectator Mode
Let other people visit the office. Walk around, watch agents work, chat with them. Could be a demo for showing off OpenClaw.

### Agent Avatars That Move
Instead of static robots at desks, agents walk around, visit each other, sit on couches. Full animation system. The social orbs are a placeholder for this.

### Voice Chat (Real)
STT/TTS is half-built. Finish it so you can talk to agents out loud. Walk up, start talking, hear them respond. No typing needed.

---

## 💬 Chat Improvements

- [ ] Scrollable chat log (can't scroll up right now)
- [ ] Selectable/copyable text (can't highlight agent responses)
- [ ] Markdown rendering (bold, links, code blocks)
- [ ] Auto-scroll to bottom on new messages
- [ ] Message timestamps
- [ ] Clear chat button
- [ ] Clickable links (open in browser)
- [ ] Inline image display (render image URLs in chat)
- [ ] Better typing indicator (animated dots)
- [ ] Chat panel resize (drag to make bigger/smaller)
- [ ] Notification sound variety (send vs receive)

---

## 🎨 Visual / Polish

- [ ] Agent idle animations (breathing, looking around — partially done)
- [ ] Particle effects (dust motes, ambient particles)
- [ ] Day/night cycle visible through windows
- [ ] Custom skybox from real Milwaukee 360° panorama
- [ ] Room-specific ambient music (each office has its own vibe)
- [ ] Better door animations
- [ ] Footstep sounds (disabled, needs audio overlap fix)
- [ ] Loading screen / transition when entering rooms

---

## 🛠 Technical

- [ ] Fix TTS (returns 405 on gateway)
- [ ] Fix audio capture (project setting needed)
- [ ] Fix bulletin board add_child errors (use call_deferred)
- [ ] Remove unused scripts/variables (GDScript warnings on startup)
- [ ] Debug: TV image loading still flaky, needs more testing
