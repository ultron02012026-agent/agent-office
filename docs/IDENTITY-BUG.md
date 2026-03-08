# Identity Bug: Agents Respond as Ultron

## Problem

When Ethan walks into Spinfluencer's or Dexer's office, those agents respond as if they are Ultron instead of themselves.

## Root Cause

**The bug is in the HTTP fallback path, not the WebSocket path.**

### HTTP Fallback (the buggy path)

When the WebSocket connection is not established (or drops), `chat_ui.gd` falls back to HTTP via `_send_to_openclaw()` → `_send_chat_request()`. This sends a POST to:

```
{gateway_url}/v1/chat/completions
```

The request body includes:
```json
{
  "model": "anthropic/claude-sonnet-4-20250514",
  "messages": [
    {"role": "system", "content": "You are Spinfluencer, an AI agent..."},
    {"role": "user", "content": "Hello!"}
  ]
}
```

**The problem:** The `/v1/chat/completions` endpoint resolves the agent ID from:
1. The `X-OpenClaw-Agent-Id` header (not set by the game)
2. The model string (no agent ID embedded in `anthropic/claude-sonnet-4-20250514`)
3. Falls back to `"main"` (Ultron)

So the gateway creates a session for **Ultron** (`agent:main:openai:<uuid>`), loads **Ultron's workspace** (SOUL.md, AGENTS.md, TOOLS.md — all saying "You are Ultron"), and the game's short system prompt "You are Spinfluencer" gets appended as `extraSystemPrompt` but is completely overpowered by Ultron's full workspace context.

### WebSocket Path (correct, but has a minor issue)

The WS path in `gateway_ws.gd` correctly sends:
```json
{
  "method": "chat.send",
  "params": {
    "sessionKey": "agent:spinfluencer:main",
    "message": "...",
    "deliver": false
  }
}
```

The gateway parses `agent:spinfluencer:main` → agent ID `spinfluencer` → loads Spinfluencer's workspace. **This path works correctly.**

However, there's a minor issue: `inject_office_context()` calls `chat.inject` before the first `chat.send`. If the session doesn't exist yet (no prior Telegram conversation), `chat.inject` fails with "session not found" because `chat.inject` requires an existing session with a transcript file. The office context injection is silently lost. The first `chat.send` then creates a new session — without the office context. This doesn't cause the identity bug but means agents might not know about their TV/lights/music controls on first visit.

## Evidence

### Code trace: HTTP fallback

1. `chat_ui.gd:_send_to_openclaw()` builds system prompt via `_build_system_prompt()` which correctly says "You are [room_name]"
2. Sends to `/v1/chat/completions` with no agent ID header
3. `gateway-cli.js:handleOpenAiHttpRequest()` calls `resolveAgentIdForRequest({req, model})`:
   - `resolveAgentIdFromHeader(req)` → null (no header)
   - `resolveAgentIdFromModel("anthropic/claude-sonnet-4-20250514")` → null (not an agent model alias)
   - Falls back to `"main"`
4. Session key becomes `agent:main:openai:<uuid>` (Ultron's session)
5. `agentCommand()` loads Ultron's workspace files as the primary system prompt
6. The game's system prompt is appended as `extraSystemPrompt` but can't override Ultron's full identity

### Code trace: WebSocket path

1. `gateway_ws.gd:send_message("Spinfluencer", msg)` → session key `agent:spinfluencer:main`
2. Gateway `chat.send` handler → `resolveSessionAgentId({sessionKey: "agent:spinfluencer:main"})` → `"spinfluencer"`
3. `getReplyFromConfig()` → `resolveAgentWorkspaceDir(cfg, "spinfluencer")` → `/Users/ultron/.openclaw/workspaces/spinfluencer`
4. Loads Spinfluencer's SOUL.md ("You're the Spinfluencer") ✅

## Fix

### Primary Fix: Add agent ID header to HTTP fallback

In `chat_ui.gd`, modify `_send_chat_request()` to include the agent ID header:

```gdscript
func _send_chat_request(messages: Array, max_tokens: int = 200):
    var body = JSON.stringify({
        "model": "anthropic/claude-sonnet-4-20250514",
        "messages": messages,
        "max_tokens": max_tokens
    })
    var headers = ["Content-Type: application/json"]
    if SettingsManager.gateway_token != "":
        headers.append("Authorization: Bearer " + SettingsManager.gateway_token)
    
    # Add agent ID header so gateway routes to the correct agent
    var agent_id = _get_current_agent_id()
    if agent_id != "":
        headers.append("X-OpenClaw-Agent-Id: " + agent_id)
    
    var url = SettingsManager.gateway_url + "/v1/chat/completions"
    var err = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
```

### Secondary Fix: Ensure WS is the primary path

The WS path works correctly. Ensure the game prioritizes it:
- The game already does this (`if _gateway_ws and _gateway_ws.is_ws_connected()`)
- Add connection status indicator in the UI so players know if WS is connected
- Add reconnection logging to help debug connection issues

### Optional Fix: Handle `chat.inject` failure for new sessions

For the office context injection issue, change `inject_office_context()` to delay injection until after the first `chat.send` response, or use `chat.send` with a system-role message for the context instead:

```gdscript
func inject_office_context(room_name: String):
    if _injected_rooms.has(room_name):
        return
    _injected_rooms[room_name] = true
    var agent_id = agent_map.get(room_name, "main")
    var session_key = "agent:" + agent_id + ":main"
    var context = _build_office_context(room_name, agent_id)
    # Use chat.send with a system prefix instead of chat.inject
    # This creates the session if it doesn't exist
    _send_request("chat.send", {
        "sessionKey": session_key,
        "message": "[System] " + context,
        "deliver": false
    })
```

Or, send the office context as part of the greeting message itself:

```gdscript
func _request_greeting(room_name: String):
    var context = _build_office_context(room_name)
    var greeting_msg = context + "\n\nEthan just walked into your office. Give a brief greeting (1 sentence)."
    _gateway_ws.send_message(room_name, greeting_msg)
```

## Verification

After applying the fix:
1. Start the game with WS disconnected → talk to Spinfluencer → should identify as Spinfluencer (not Ultron)
2. Start with WS connected → talk to Spinfluencer → should identify as Spinfluencer
3. Start with WS connected → talk to Dexer → should identify as Dexer
4. Check that office context (TV, lights, music controls) works on first visit

## Files Changed

- `scripts/chat_ui.gd` — Add `X-OpenClaw-Agent-Id` header to HTTP fallback
- `scripts/gateway_ws.gd` — (optional) Improve office context injection reliability
